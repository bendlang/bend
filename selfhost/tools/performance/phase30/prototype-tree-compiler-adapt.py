#!/usr/bin/env python3
"""Retain actual checked tree emissions and adapt existing independent controls."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
DESIGN=ROOT/'design/phase30/actual-scalar-tree-validation.md'
CONTROLS=HERE/'prototype-tree-region-controls.mjs'
COUNTS=HERE/'prototype-tree-region-counts.mjs'
PARSER=HERE/'inspect-terminal-region.py'
spec=importlib.util.spec_from_file_location('phase30_actual_tree_parser',PARSER)
parser=importlib.util.module_from_spec(spec);spec.loader.exec_module(parser)

def identity(p):
 p=Path(p).resolve();raw=p.read_bytes()
 return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}

def checked(p,attempt_name):
 receipt=Path(str(p)+'.json');data=json.loads(receipt.read_text())
 assert data['complete'] and data['observation']['checked']
 assert data['output']['sha256']==identity(p)['sha256']
 attempt=Path(data['attempt']['file'])
 assert attempt.parent.name==attempt_name and data['attempt']['sha256']==identity(attempt)['sha256']
 return [identity(p),identity(receipt),identity(attempt)]

def edit(text,old,new):
 assert text.count(old)==1,old
 return text.replace(old,new)

def controls(source,sentinel):
 source=edit(source,"const variants=['baseline','public_leaf','private_leaf'];","const variants=['baseline','candidate'];")
 source=edit(source,"kind:'phase30-private-scalar-tree-controls'","kind:'phase30-actual-scalar-tree-controls'")
 start=source.index("    const original=path.join(dir,variant+'.mjs');let text=")
 end=source.index("    const m=await import(pathToFileURL(file));",start)
 replacement="""    const original=path.join(dir,variant+'.mjs');
    const file=path.join(out,variant+'-depth-sentinel.mjs');
    fs.copyFileSync(path.join(dir,'candidate-depth-sentinel.mjs'),file,fs.constants.COPYFILE_EXCL);
"""
 source=source[:start]+replacement+source[end:]
 return source

def counts(source):
 source=edit(source,"const variants=['baseline','public_leaf','private_leaf'];","const variants=['baseline','candidate'];")
 source=edit(source,"kind:'phase30-private-scalar-tree-counts'","kind:'phase30-actual-scalar-tree-counts'")
 start=source.index("    edit('const $tree30Stack=[];'")
 end=source.index("\n  }\n  const empty=",start)
 replacement=r'''    edit('/* private scalar tree */','/* private scalar tree */$counts.treeEntries++;');
    edit('$visit:for(;;){','$visit:for(;;){$counts.treeNodes++;if($s0===0n){$counts.treeLeaves++;$counts.indices.push($s1);}');
    const push=text.match(/\$frames\[\$top\+\+\]=\{args:\[[^\]]*\],phase:0,left:null\};/g);assert.equal(push.length,1);
    edit(push[0],push[0]+'$counts.frames++;$counts.highWater=Math.max($counts.highWater,$top);');
    edit('$frames.length=--$top;','$counts.treeCombines++;$frames.length=--$top;');'''
 source=source[:start]+replacement+source[end:]
 return source

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('baseline',type=Path);ap.add_argument('candidate',type=Path);ap.add_argument('out',type=Path)
 args=ap.parse_args();args.out.mkdir(parents=True,exist_ok=False)
 report={'kind':'phase30-actual-tree-validation-adaptation','complete':False,
  'scope':'Actual checked attempt11 versus attempt12. Original oracle and host actions retained; only labels and diagnostic output instrumentation adapted.',
  'inputs':[identity(p)for p in [Path(__file__),DESIGN,CONTROLS,COUNTS,PARSER]],'outputs':[]}
 try:
  report['inputs']+=checked(args.baseline,'attempt-11')+checked(args.candidate,'attempt-12')
  source=args.candidate.read_text()
  marker='/* private scalar tree */'
  assert source.count(marker)==1
  rows=[line for line in source.splitlines()if marker in line]
  assert len(rows)==1 and rows[0].startswith('G["rcol"]=')
  owner=rows[0];at=owner.index(marker);fast_open=at-1
  assert owner[fast_open]=='{'
  fast_close=parser.close(owner,fast_open)
  callback='function(a,$entered){';callback_open=owner.rfind(callback,0,fast_open)+len(callback)-1
  assert callback_open>=len(callback)-1 and owner[callback_open]=='{'
  callback_close=parser.close(owner,callback_open)
  fast=owner[fast_open+1:fast_close]
  assert fast.startswith(marker) and '$frames.length=--$top;' in fast
  assert '$s0<32n' in owner[callback_open:fast_open]
  assert not any(x in fast for x in ['get(G,','callOwned(','jump('])
  sentinel_owner=owner[:fast_open+1]+'return "fast";'+owner[fast_close:fast_close+1]+'return "generic";'+owner[callback_close:]
  sentinel=edit(source,owner,sentinel_owner)
  for old,name in [(args.baseline,'baseline.mjs'),(args.candidate,'candidate.mjs'),(Path(__file__),'consumed-adapt.py'),(DESIGN,'plan.md')]:
   shutil.copyfile(old,args.out/name)
  artifacts={'candidate-depth-sentinel.mjs':sentinel,
    'actual-controls.mjs':controls(CONTROLS.read_text(),sentinel),
    'actual-counts.mjs':counts(COUNTS.read_text())}
  for name,text in artifacts.items():
   target=args.out/name;target.write_text(text);report['outputs'].append(identity(target))
  report['baseline']=identity(args.out/'baseline.mjs');report['candidate']=identity(args.out/'candidate.mjs')
  report['diagnosticBody']={'fast':fast,'generic':owner[fast_close+1:callback_close],
    'publicDepthCap':32,'hostRecursiveTreeCalls':0}
  report['complete']=True
 except Exception as error:
  report['error']=repr(error);raise
 finally:(args.out/'derive.json').write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps({'complete':True,'out':str(args.out)}))

if __name__=='__main__':main()
