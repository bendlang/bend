#!/usr/bin/env python3
"""Disposable exact scalar binary-tree ablation; no compiler/runtime source edits."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, re, shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PLAN=ROOT/'design/phase30/pure-scalar-tree-region.md'
PARSER=HERE/'inspect-terminal-region.py'
spec=importlib.util.spec_from_file_location('phase30_tree_parser',PARSER)
parser=importlib.util.module_from_spec(spec);spec.loader.exec_module(parser)
parser.ARITIES['rpix']=10
NAMES=['rcol','rpix','pix','bkt','mit','asr8','sel','sel.go','b2u']
SMALL=['b2u','asr8','sel','sel.go']

def identity(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}

def lexical(name):return '$R'+''.join('_'+str(ord(c))for c in name)

def derive(source,variant):
 assert variant in ['public_leaf','private_leaf']
 assert '$tree30' not in source
 ds={}
 for name in NAMES:
  rows=[line for line in source.splitlines()if line.startswith('G['+json.dumps(name)+']=')]
  assert len(rows)==1,name
  ds[name]=rows[0]
 owner=ds['rcol']
 succ=parser.callback(owner,'matcher1p("Succ",1,11,()=>(0,function(a){')
 zero=parser.callback(owner,'matcher("Zero",()=>fn(10,function(a){')
 assert len(succ['params'])==11 and len(zero['params'])==10
 # Exactly two saturated self calls, followed by the original scalar combine.
 expression=succ['expr']
 matched=re.match(r'^\(\((x\d+),(x\d+),\)=>',expression)
 assert matched,'Unexpected two-child continuation'
 end=parser.close(expression,0)
 assert expression[end+1]=='(' and parser.close(expression,end+1)==len(expression)-1
 combine=expression[matched.end():end]
 children=parser.split(expression[end+2:-1]);assert len(children)==2
 decoded=[parser.application(child)for child in children]
 for name,args in decoded:
  assert name=='rcol' and len(args)==11 and args[0]==succ['params'][0]
 left_args,right_args=[args for _,args in decoded]
 assert not any(token in combine for token in ['get(G,','callOwned(','jump('])
 for variable in succ['params']:
  assert not re.search(r'\b'+re.escape(variable)+r'\b',combine),'Parent capture in binary combine'
 for value in left_args+right_args:
  assert not any(re.search(r'\b'+re.escape(variable)+r'\b',value)for variable in matched.groups()),'Child argument sees parallel result binder'
 leaf_name,leaf_args=parser.application(zero['expr'])
 assert leaf_name=='rpix' and leaf_args==zero['params']

 mit=ds['mit'];start=mit.index('(()=>{')+len('(()=>{');end=mit.index('const $guards=',start)
 declarations=mit[start:end]
 assert set(re.findall(r'function (\$R(?:_\d+)+)\(',declarations))==set(map(lexical,SMALL))
 assert '$R[' not in declarations
 loop_start=mit.index('for(;;){',mit.index('/* private scalar region */'))
 loop_end=parser.close(mit,loop_start+len('for(;;)'))+1
 loop=mit[loop_start:loop_end]
 assert not any(x in loop for x in ['get(G,','callOwned(','jump('])
 bindings={name:lexical(name)for name in SMALL}
 bindings.update(mit='$tree30Mit',pix='$tree30Pix',bkt='$tree30Bkt',rpix='$tree30Rpix')
 def private(expr):
  changed=parser.private_calls(expr,set(bindings))
  changed=re.sub(r'\$H\[("[^"\\]+")\]',lambda m:bindings[json.loads(m[1])],changed)
  assert not any(x in changed for x in ['get(G,','callOwned(','jump(','$H['])
  return changed
 bundle=declarations+'function $tree30Mit($count,'+','.join('$s'+str(i)for i in range(1,7))+'){'
 bundle+='if($count===0n)return $s6;let $s0=$count-1n;'+loop+'}'
 for name,arity in [('pix',2),('bkt',2),('rpix',10)]:
  body=parser.callback(ds[name],'fn('+str(arity)+',function(a){')
  bundle+='function '+bindings[name]+'('+','.join(body['params'])+'){return '+private(body['expr'])+';}'

 slots=['$tree30S'+str(i)for i in range(11)]
 original=succ['params']
 aliases=''.join('const '+name+'='+('$tree30S0-1n'if i==0 else slots[i])+';'for i,name in enumerate(original))
 saved_aliases=''.join('const '+name+'=$tree30Frame.args['+str(i)+'];'for i,name in enumerate(original))
 zero_aliases=''.join('const '+name+'='+slots[i+1]+';'for i,name in enumerate(zero['params']))
 def transfer(args):
  return ''.join('const $tree30Next'+str(i)+'='+private(value)+';'for i,value in enumerate(args))
 assign=''.join(slot+'=$tree30Next'+str(i)+';'for i,slot in enumerate(slots))
 leaf='force('+zero['expr']+')'if variant=='public_leaf' else private(zero['expr'])
 tree='function $tree30Loop('+','.join(slots)+'){const $tree30Stack=[];let $tree30Top=0,$tree30Value;'
 tree+='$tree30Visit:for(;;){if($tree30S0!==0n){'+aliases+transfer(left_args)
 tree+='$tree30Stack[$tree30Top++]={args:['+','.join(original)+'],phase:0,left:0};'+assign+'continue;}'
 tree+='{'+zero_aliases+'$tree30Value='+leaf+';}'
 tree+='while($tree30Top){const $tree30Frame=$tree30Stack[$tree30Top-1];'
 tree+='if($tree30Frame.phase===0){$tree30Frame.left=$tree30Value;$tree30Frame.phase=1;'+saved_aliases
 tree+=transfer(right_args)+assign+'continue $tree30Visit;}'
 tree+='const '+matched[1]+'=$tree30Frame.left;const '+matched[2]+'=$tree30Value;'
 tree+='$tree30Value='+combine+';$tree30Stack.length=--$tree30Top;}return $tree30Value;}}'
 assert tree.count('$tree30Loop(')==1,'No recursive private tree call'
 checks=[]
 for i,name in enumerate(original):
  if i in [0,2]:
   checks.append('(typeof '+name+'==="bigint"&&'+name+'>=0n&&'+name+('<32n)'if i==0 else '<=281474976710655n)'))
  else:checks.append('(typeof '+name+'==="number"&&Number.isInteger('+name+')&&'+name+'>=0&&'+name+'<=4294967295)')
 new_body=succ['prefix']+'if($entered&&'+'&&'.join(checks)+'&&scalarGuard($tree30Guards)){/* tree fast entry */return $tree30Loop('+original[0]+'+1n,'+','.join(original[1:])+');}'
 new_body+='/* tree generic entry */return '+succ['expr']+';'
 begin=succ['start']-len('(0,function(a){');finish=succ['end']+2
 assert owner[begin:succ['start']]=='(0,function(a){' and owner[succ['end']:finish]=='})'
 changed=owner[:begin]+'exactCode(function(a,$entered){'+new_body+'})'+owner[finish:]
 prefix='G["rcol"]='
 rhs=changed[len(prefix):-1]
 if not rhs.startswith('scalarCapture("rcol",'):rhs='scalarCapture("rcol",'+rhs+')'
 changed=prefix+'(()=>{const $tree30Guards='+json.dumps(NAMES,separators=(',',':'))+';'+bundle+tree+'return '+rhs+';})();'
 replacements={'rcol':changed}
 for name in NAMES[1:]:
  prefix='G['+json.dumps(name)+']='
  if not ds[name].startswith(prefix+'scalarCapture('):replacements[name]=prefix+'scalarCapture('+json.dumps(name)+','+ds[name][len(prefix):-1]+');'
 output=source
 edits=[]
 for name,replacement in replacements.items():
  assert output.count(ds[name]+'\n')==1
  output=output.replace(ds[name]+'\n',replacement+'\n')
  edits.append({'name':name,'original':ds[name],'replacement':replacement})
 return output,{'variant':variant,'publicDepthCap':32,'guardClosure':NAMES,'successorSlots':succ['params'],
   'zeroSlots':zero['params'],'leftArguments':left_args,'rightArguments':right_args,'combine':combine,
   'frame':'parent immutable scalar arguments, child stage, completed left result','hostRecursiveTreeCalls':0,'edits':edits}

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('source',type=Path);ap.add_argument('out',type=Path);args=ap.parse_args()
 source=args.source.resolve();receipt=Path(str(source)+'.json');checked=json.loads(receipt.read_text())
 assert checked['complete'] and checked['observation']['checked']
 assert checked['output']['sha256']==identity(source)['sha256']
 attempt=Path(checked['attempt']['file']);assert attempt.parent.name=='attempt-10'
 assert checked['attempt']['sha256']==identity(attempt)['sha256']
 args.out.mkdir(parents=True,exist_ok=False)
 for old,new in [(Path(__file__),'consumed-derive.py'),(PLAN,'plan.md'),(source,'baseline.mjs')]:shutil.copyfile(old,args.out/new)
 report={'kind':'phase30-private-scalar-binary-tree-ablation','complete':False,
  'inputs':[identity(p)for p in [Path(__file__),PLAN,PARSER,source,receipt,attempt]],'variants':{},
  'compilerChanged':False,'runtimeChanged':False,'correctness':'not run','timing':'not run'}
 try:
  for variant in ['public_leaf','private_leaf']:
   text,evidence=derive(source.read_text(),variant);target=args.out/(variant+'.mjs');target.write_text(text)
   report['variants'][variant]={'output':identity(target),'derivation':evidence}
  report['baseline']=identity(args.out/'baseline.mjs');report['complete']=True
 except Exception as error:
  report['error']=repr(error);raise
 finally:(args.out/'derive.json').write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps({'complete':True,'out':str(args.out)}))

if __name__=='__main__':main()
