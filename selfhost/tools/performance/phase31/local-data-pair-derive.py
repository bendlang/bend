#!/usr/bin/env python3
"""Extend the exact local row variants to the unchanged complete scalar pair."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,re,shutil
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
s=importlib.util.spec_from_file_location('local31',HERE/'local-data-derive.py');local=importlib.util.module_from_spec(s);s.loader.exec_module(local)
row=local.row;parser=row.parser
NAMES=['pair','dp','dp.row','dp.f1','dist','dist.fin']
ARITIES={'dp':3,'dp.row':2,'dp.f1':5,'dist':1,'dist.fin':1,'row':4,'gen':4,'init':3}
parser.ARITIES.update(ARITIES)
def ident(p):return local.ident(p)
def save(p,x):return local.save(p,x)
def edit(s,a,b):return local.edit(s,a,b)
def calls(text,names):
 at=0;out='';token=re.compile(r'(?<![\w$])(callOwned|jump)\(')
 while match:=token.search(parser.mask(text),at):
  start=match.start();end=parser.close(text,text.index('(',start))+1;original=text[start:end];name,args=parser.application(original)
  if name in names:
   assert len(args)==ARITIES[name],(name,args)
   result=row.symbol(name)+'('+','.join(calls(a,names)for a in args)+')'
   if match[1]=='callOwned':result='force('+result+')'
  else:
   left=original.index('(');result=original[:left+1]+calls(original[left+1:-1],names)+')'
  out+=text[at:start]+result;at=end
 return out+text[at:]
def helper(source,name):
 original=row.definition(source,name)
 if name=='dist.fin':
  assert original=='G["dist.fin"]=fn(1,function(a){return project("Tuple",a[0]).slice()[1];});'
  code='function $Owned_dist_fin(value){return project("Tuple",value).slice()[1];}\n'
  return code,dict(name=name,original=original,private=code,nativeSites={})
 p=re.fullmatch(r'G\["'+re.escape(name)+r'"\]=fn\((\d+),function\(a\)\{(.*?)return matcher1\("(.*?)",\(\)=>fn\((\d+),function\(a\)\{(.*)\}\)\);\}\);',original)
 if p:
  count,lead,tag,k,body=p.groups();ids=re.findall(r'const (x\d+)=a\[\d+\];',lead);assert len(ids)==int(count)
 else:
  p=re.fullmatch(r'G\["'+re.escape(name)+r'"\]=matcher1\("(.*?)",\(\)=>fn\((\d+),function\(a\)\{(.*)\}\)\);',original)
  assert p,name
  tag,k,body=p.groups();ids=[]
 changed=calls(body,set(ARITIES));counts=dict.fromkeys(local.native.ARITIES,0);changed=local.native.rewrite(changed,counts)
 params=','.join(ids+['value']);code='function '+row.symbol(name)+'('+params+'){const a=project('+json.dumps(tag)+',value).slice();'+changed+'}\n'
 return code,dict(name=name,original=original,private=code,nativeSites=counts)
def derive(source,setup):
 generated=[];proof=[]
 for name in ['dp.f1','dp.row','dist.fin','dist']:
  code,r=helper(source,name);generated.append(code);proof.append(r)
 dp='''function $Owned_dp(n,i,state){
 for(;n!==0n;){const oldN=n,oldI=i,oldState=state;
  const nextN=oldN-1n,nextI=(oldI+1)>>>0;
  const nextState=force($Owned_dp_row(oldI,oldState));
  n=nextN;i=nextI;state=nextState;
 }return state;
}
'''
 original=row.definition(source,'dp');assert original.count('get(G,"dp.row")')==1
 generated.append(dp);proof.append(dict(name='dp',original=original,private=dp))
 pair=row.definition(source,'pair');body=parser.callback(pair,'fn(1,function(a){');assert len(body['params'])==1;p=body['params'][0]
 names={'dp','dist'}|({'gen','init'}if setup else set());fast=calls(body['expr'],names);counts=dict.fromkeys(local.native.ARITIES,0);fast=local.native.rewrite(fast,counts)
 guard='(typeof '+p+'==="number"&&Number.isInteger('+p+')&&'+p+'>=0&&'+p+'<=4294967295)'
 replacement='G["pair"]=scalarCapture("pair",fn(1,exactCode(function(a,$entered){'+body['prefix']+'if($entered&&'+guard+'&&$Owned_arrayMarkersSafe()&&scalarGuard($Pair_guards)){/* private pair entry */return force('+fast+');}/* private pair generic */return '+body['expr']+';})));'
 result=edit(source,pair,replacement)
 allnames=list(dict.fromkeys(row.NAMES+NAMES));bundle='const $Pair_guards='+json.dumps(allnames,separators=(',',':'))+';\n'+''.join(generated)+'\n'.join('scalarCapture('+json.dumps(name)+',G['+json.dumps(name)+']);'for name in NAMES)+'\n'
 result=edit(result,'const $Owned_exports = ',bundle+'const $Owned_exports = ')
 return result,dict(helpers=proof,pairOriginal=pair,pairReplacement=replacement,closure=allnames,nativeSites=counts)
def oracle(p):
 mask=0xffffffff;s=((p+1)*2654435761)&mask
 def stream(s):
  a=[]
  for i in range(256):
   s=(s^((s<<13)&mask))&mask;s^=s>>17;s=(s^((s<<5)&mask))&mask;a.append(s&3)
  return a
 a,b=stream(s),stream((s*340573321)&mask);prev=list(range(257));cur=[0]*257
 for i,x in enumerate(a):
  cur[0]=i+1
  for j,y in enumerate(b):cur[j+1]=min(prev[j+1]+1,cur[j]+1,prev[j]+int(x!=y))
  prev,cur=cur,prev
 return ((prev[256]*2654435761)&mask)^((p+1)&mask)
def main():
 ap=argparse.ArgumentParser();ap.add_argument('source',type=Path);ap.add_argument('out',type=Path);a=ap.parse_args();a.source=a.source.resolve();a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=False)
 design=ROOT/'design/phase31/full-pair-transfer.md';d=json.loads((a.source/'derive.json').read_text());assert d['complete']
 inputs=[Path(__file__),HERE/'local-data-derive.py',design,a.source/'derive.json']+[Path(x['file'])for x in d['variants'].values()]
 shutil.copyfile(Path(__file__),a.out/'consumed-derive.py')
 r=dict(kind='phase31-local-data-full-pair',complete=False,inputs=[ident(p)for p in inputs],variants={},rewrites={});save(a.out/'derive.json',r)
 try:
  mapping={'baseline':'baseline','private_full':'private_native','private_setup':'private_setup','private_dp':'private_dp','typescript':'typescript'}
  for name,prior in mapping.items():
   path=Path(d['variants'][prior]['file']);assert ident(path)==d['variants'][prior];text=path.read_text()
   if name not in ['baseline','typescript']:text,r['rewrites'][name]=derive(text,name!='private_full')
   if name!='typescript':
    base=Path(d['variants']['baseline']['file']).read_text()
    for line in base.splitlines():
     if line.startswith('G[')and not any(line.startswith('G["'+x+'"]=')for x in ['pair','row.probe']):assert line in text.splitlines(),line
   marker='export default {...$Owned_exports,bench:';start=text.index(marker)
   text=text[:start]+marker+'p=>$Owned_exports["pair"](p)};\n'
   target=a.out/(name+'.mjs');target.write_text(text);r['variants'][name]=ident(target)
  points=[dict(args=[p],expected=oracle(p))for p in [0,1,2,3,17,4294967295]];assert sum(p['expected']for p in points[:4])&0xffffffff==2065873279
  save(a.out/'points.json',points);r['points']=ident(a.out/'points.json');r['complete']=True
  shutil.copyfile(Path(__file__),a.out/'consumed-derive.py');shutil.copyfile(design,a.out/'design.md')
 except Exception as e:r['error']=repr(e);raise
 finally:save(a.out/'derive.json',r)
 print(json.dumps(dict(complete=True,out=str(a.out))))
if __name__=='__main__':main()
