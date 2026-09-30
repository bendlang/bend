#!/usr/bin/env python3
"""Disposable closed-array row ladder over an actual checked canonical probe."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,shutil
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
PARSER=HERE/'inspect-terminal-region.py'
spec=importlib.util.spec_from_file_location('owned_row_parser',PARSER)
parser=importlib.util.module_from_spec(spec);spec.loader.exec_module(parser)
CELLS=['cell.f4','cell.f3','cell.f2','cell.f1','cell']
NAMES=['row.probe','prng','gen','init','row','cell','cell.f1','cell.f2','cell.f3','cell.f4','umin','umin.go','b2u','Array.new','Array.get','Array.set']
parser.ARITIES.update({'row':4,'cell':3,'cell.f1':6,'cell.f2':6,'cell.f3':7,'cell.f4':8,'umin':2,'umin.go':3,'b2u':1})
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def edit(s,old,new):
 assert s.count(old)==1,old
 return s.replace(old,new)
def symbol(name):return '$Owned_'+name.replace('.','_')
def direct(expr,names,force=False):
 result=parser.private_calls(expr,set(names))
 for name in names:
  result=result.replace('$H['+json.dumps(name)+'](',('force('if force else '')+symbol(name)+'(')
 if force:
  # The row's one complete cell call is the only forced private rewrite here.
  assert len(names)==1 and result.count('force('+symbol(names[0])+'(')==1
  at=result.index('force('+symbol(names[0])+'(');inner=result.index('(',at+len('force('))
  end=parser.close(result,inner);result=result[:end+1]+')'+result[end+1:]
 return result
def definition(source,name):
 rows=[l for l in source.splitlines()if l.startswith('G['+json.dumps(name)+']=')]
 assert len(rows)==1,name
 return rows[0]
def derive(source,variant):
 assert variant in ['private_cell','private_scalar','private_row']
 generated=[];scalar=variant!='private_cell';rewrites=[]
 for name in CELLS:
  line=definition(source,name)
  match=re.fullmatch(r'G\["'+re.escape(name)+r'"\]=fn\((\d+),function\(a\)\{(.*?)return matcher1\("(.*?)",\(\)=>fn\((\d+),function\(a\)\{(.*)\}\)\);\}\);',line)
  assert match,name
  count,lead,tag,k,body=match.groups();count=int(count);k=int(k)
  ids=re.findall(r'const (x\d+)=a\[\d+\];',lead);assert len(ids)==count
  private=symbol(name);params=','.join(ids)
  generated.append(f'function {private}_cold({params},a){{{body}}}')
  optimized=direct(body,CELLS)
  if scalar:optimized=direct(optimized,['umin','umin.go','b2u'])
  generated.append(f'function {private}_fields({params},a){{{optimized}}}')
  invoke=f'{private}_cold({params},a)'
  generated.append(f'''function {private}({params},value){{
 const p=project({json.dumps(tag)},value);
 if(!p.length)return fn({k},a=>{invoke});
 const all=p.slice();
 if(all.length==={k})return {private}_fields({params},all);
 if(all.length<{k})return fn({k},a=>{invoke},null,all);
 let r={private}_cold({params},all.slice(0,{k}));
 if(all.length>{k})r=jump(force(r),all.slice({k}));return r;
}}''')
  rewrites.append({'name':name,'originalArm':body,'privateExactArm':optimized})
 if scalar:
  # Validate these unchanged scalar helper definitions before selecting their
  # primitive semantics for the closed, typed local path.
  b2u=definition(source,'b2u');minimum=definition(source,'umin');choose=definition(source,'umin.go')
  assert 'matcher("False",()=>0,()=>matcher1("True",()=>1))' in b2u
  body=parser.callback(choose,'fn(2,function(a){')
  assert body['expr']=='matcher("True",()=>'+body['params'][0]+',()=>matcher1("False",()=>'+body['params'][1]+'))'
  m=parser.callback(minimum,'fn(2,function(a){');x,y=m['params']
  assert m['expr']=='jump(callOwned(get(G,"umin.go"),['+x+','+y+',]),[(/* primitive */(('+x+')<('+y+')))])'
  generated.extend(['function $Owned_b2u(b){return b?1:0;}','function $Owned_umin_go(x,y,lt){return lt?x:y;}',
    'function $Owned_umin(x,y){return $Owned_umin_go(x,y,(/* primitive */((x)<(y))));}'])
 row=definition(source,'row');rhs=row[len('G["row"]='):-1]
 # Copy the row machinery privately, retaining all public definitions verbatim.
 private_rhs=direct(rhs,['cell'],True).replace('get(G,"row")','$Owned_row_desc')
 generated.append('const $Owned_row_desc='+private_rhs+';')
 if variant=='private_row':
  generated.append('''function $Owned_row(n,j,ai,state){
   for(;n!==0n;){const oldN=n,oldJ=j,oldAi=ai,oldState=state;
    const nextN=oldN-1n,nextJ=(oldJ+1)>>>0;
    const nextState=force($Owned_cell(oldJ,oldAi,oldState));
    n=nextN;j=nextJ;ai=oldAi;state=nextState;
   }
   return callOwned(callOwned(callOwned(callOwned(get(G,"row"),[0n]),[j]),[ai]),[state]);
  }''')
 probe=definition(source,'row.probe');body=parser.callback(probe,'fn(2,function(a){');n,seed=body['params']
 expression=body['expr']
 if variant=='private_row':fast=direct(expression,['row'])
 else:
  assert expression.count('get(G,"row")')==1
  fast=expression.replace('get(G,"row")','$Owned_row_desc')
 check=lambda x:f'(typeof {x}==="number"&&Number.isInteger({x})&&{x}>=0&&{x}<=4294967295)'
 replacement='G["row.probe"]=scalarCapture("row.probe",fn(2,exactCode(function(a,$entered){'+body['prefix']
 replacement+='if($entered&&'+check(n)+'&&'+n+'<=64&&'+check(seed)+'&&scalarGuard($Owned_guards)){/* owned row entry */return force('+fast+');}'
 replacement+='/* owned row generic */return '+expression+';})));'
 changed=edit(source,probe,replacement)
 marker='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
 bundle='const $Owned_guards='+json.dumps(NAMES,separators=(',',':'))+';\n'+'\n'.join(generated)+'\n'
 bundle+='\n'.join('scalarCapture('+json.dumps(name)+',G['+json.dumps(name)+']);'for name in NAMES)+'\n'
 changed=edit(changed,marker,bundle+marker)
 # No public row/cell/native function definition is redirected.
 for name in ['row',*CELLS,'umin','umin.go','b2u']:
  assert definition(changed,name)==definition(source,name)
 return changed,{'variant':variant,'closure':NAMES,'probeOriginal':probe,'probeReplacement':replacement,'privateBodies':rewrites,'bundle':bundle}
def wrap(source,upstream):
 marker='export default '
 assert source.count(marker)==1
 source=source.replace(marker,'const $Owned_exports = ',1)
 if upstream:observe='JSON.stringify([st.a,st.b,st.prev,st.cur])'
 else:observe='JSON.stringify(st.a.map(x=>x.array))'
 return source+'\nexport default {...$Owned_exports,bench:(n,seed)=>{const st=$Owned_exports["row.probe"](n,seed);return '+observe+';}};\n'
def oracle(n,seed):
 def stream(seed):
  a=[0]*128
  for i in range(n):
   seed=(seed^((seed<<13)&0xffffffff))&0xffffffff;seed^=seed>>17;seed=(seed^((seed<<5)&0xffffffff))&0xffffffff;a[i]=seed&3
  return a
 a=stream(seed);b=stream((seed*340573321)&0xffffffff);prev=list(range(n+1))+[0]*(127-n);cur=[0]*128
 for j in range(n):cur[j+1]=min((prev[j+1]+1)&0xffffffff,(cur[j]+1)&0xffffffff,(prev[j]+int((seed&3)!=b[j]))&0xffffffff)
 return json.dumps([a,b,cur,prev],separators=(',',':'))
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('base',type=Path);ap.add_argument('upstream',type=Path);ap.add_argument('out',type=Path);a=ap.parse_args();a.out.mkdir(parents=True,exist_ok=False)
 design=ROOT/'design/phase30/closed-owned-row-first-ladder.md'
 paths=[Path(__file__),PARSER,design,a.base,Path(str(a.base)+'.json'),a.upstream,Path(str(a.upstream)+'.json')]
 r={'kind':'phase30-closed-owned-row-derivation','complete':False,'inputs':[ident(p)for p in paths],'variants':{},'rewrites':[]}
 save(a.out/'derive.json',r)
 try:
  baseline=json.loads(Path(str(a.base)+'.json').read_text());ts=json.loads(Path(str(a.upstream)+'.json').read_text())
  assert baseline['complete'] and baseline['observation']['checked'] and ts['complete'] and ts['checked']
  assert baseline['input']['sha256']==ts['input']['sha256']
  for path,receipt in [(a.base,baseline),(a.upstream,ts)]:assert receipt['output']['sha256']==ident(path)['sha256']
  assert Path(baseline['attempt']['file']).parent.name=='attempt-12'
  for name in ['baseline','private_cell','private_scalar','private_row','typescript']:
   if name=='baseline':source=a.base.read_text()
   elif name=='typescript':source=a.upstream.read_text()
   else:source,evidence=derive(a.base.read_text(),name);r['rewrites'].append(evidence)
   target=a.out/(name+'.mjs');target.write_text(wrap(source,name=='typescript'));r['variants'][name]=ident(target)
  points=[{'args':[n,seed],'expected':oracle(n,seed)}for n in [0,1,2,7,16,32,64]for seed in [0,1,17,4294967295]]
  save(a.out/'points.json',points);r['points']=ident(a.out/'points.json');r['complete']=True
  shutil.copyfile(Path(__file__),a.out/'consumed-derive.py');shutil.copyfile(design,a.out/'design.md')
 except Exception as error:r['error']=repr(error);raise
 finally:save(a.out/'derive.json',r)
 print(json.dumps({'complete':True,'out':str(a.out)}))
if __name__=='__main__':main()
