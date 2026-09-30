#!/usr/bin/env python3
"""Independent use-site audit and executed forward-reference witnesses."""
from pathlib import Path
import hashlib,importlib.util,json,re,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
PARSER=HERE/'inspect-terminal-region.py'
spec=importlib.util.spec_from_file_location('binding_review_parser',PARSER)
parser=importlib.util.module_from_spec(spec);spec.loader.exec_module(parser)
NODE='/home/ai/.nvm/versions/node/v24.18.0/bin/node'
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def identity(p):
 p=Path(p).resolve();raw=p.read_bytes()
 return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def audit(source):
 token=r'\$R(?:_\d+)+'
 pattern=r'(?:function ('+token+r')\(([^)]*)\)|const ('+token+r')=(?:function\(([^)]*)\)|\(([^)]*)\)=>))\{'
 declarations=[];masked=parser.mask(source)
 for match in re.finditer(pattern,masked):
  group=1 if match[1] else 3
  start=match.start();brace=match.end()-1;end=parser.close(source,brace)
  declarations.append({'name':match[group],'nameAt':match.start(group),'start':start,'brace':brace,'end':end,
    'line':source.count('\n',0,start),'params':match[2]if match[1]else match[4]if match[4]is not None else match[5]})
 assert declarations
 declaration_positions={d['nameAt']for d in declarations};calls=[];forward=[]
 for use in re.finditer(r'(?<![\w$])'+token+r'(?![\w$])',masked):
  name=use[0];at=use.start()
  if at in declaration_positions:continue
  assert masked[use.end():].lstrip().startswith('('),('non-call',name,at)
  prefix=masked[:at].rstrip();assert not prefix.endswith('.'),('property',name,at)
  assert not re.search(r'\bnew\s*$',prefix),('constructor',name,at)
  line=source.count('\n',0,at);targets=[d for d in declarations if d['line']==line and d['name']==name]
  assert len(targets)==1,('binding scope',name,at,len(targets))
  owner=next((d for d in declarations if d['brace']<at<d['end']),None)
  row={'name':name,'at':at,'end':use.end(),'line':line,'declaration':targets[0]['start']}
  calls.append(row)
  if owner and targets[0]['start']>owner['end']:
   forward.append({**row,'caller':owner['name'],'callerDeclaration':owner['start']})
 assert calls and forward
 # These frozen generated IIFEs contain no initialization-time helper call:
 # calls outside helper bodies are deferred in public callbacks, checked by the
 # exact owner derivation and independently exercised here after module import.
 changed=source
 for i,row in reversed(list(enumerate(forward))):
  changed=changed[:row['at']]+'($privateForwardReview['+str(i)+']++,'+row['name']+')'+changed[row['end']:]
 assert '$privateForwardReview'not in source
 changed='const $privateForwardReview=Array('+str(len(forward))+').fill(0);\n'+changed
 changed+='\nexport function privateForwardReview(){return [...$privateForwardReview];}\n'
 return changed,{'declarations':declarations,'directCalls':calls,'forwardEdges':forward}

report={'kind':'phase30-independent-private-binding-review','complete':False,'pass':False,
 'scope':'Frozen actual12 alternatives; private identifier use and same-IIFE forward references. Diagnostic counter copies are never timed.',
 'inputs':[identity(Path(__file__)),identity(PARSER),identity(NODE)],'rows':[]}
(out/'consumed-review.py').write_bytes(Path(__file__).read_bytes())
runner=out/'run.mjs';runner.write_text('import {pathToFileURL} from "node:url";const m=await import(pathToFileURL(process.argv[2]));const args=JSON.parse(process.argv[3]);const initial=m.privateForwardReview();const result=m.default.bench(...args);console.log(JSON.stringify({initial,result,counts:m.privateForwardReview()}));\n')
try:
 for kind,args,expected in [('helper',[128,524800],128),('whole',[2,0],887240761)]:
  directory=ROOT/('selfhost/build/phase30/private-binding-'+kind+'-01')
  report['inputs'].append(identity(directory/'derive.json'))
  for variant in ['baseline','constant_function','constant_arrow']:
   source=directory/(variant+'.mjs');report['inputs'].append(identity(source))
   diagnostic,evidence=audit(source.read_text());target=out/(kind+'-'+variant+'.mjs');target.write_text(diagnostic)
   command=['taskset','-c','6',NODE,str(runner),str(target),json.dumps(args,separators=(',',':'))]
   start=time.monotonic();run=subprocess.run(command,text=True,capture_output=True,timeout=15)
   row={'kind':kind,'variant':variant,'source':identity(source),'diagnostic':identity(target),'audit':evidence,
    'command':command,'exitCode':run.returncode,'seconds':time.monotonic()-start,'stdout':run.stdout,'stderr':run.stderr}
   report['rows'].append(row);assert run.returncode==0,row
   observed=json.loads(run.stdout);row['observation']=observed
   assert observed['result']==expected
   assert all(x==0 for x in observed['initial']),'helper invoked during module initialization'
   assert any(x>0 for x in observed['counts']),'forward reference was not exercised'
 for item in report['inputs']:assert identity(item['file'])==item
 report['complete']=True;report['pass']=True
except Exception as error:report['error']=repr(error);raise
finally:(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'complete':True,'pass':True,'rows':len(report['rows']),'executedForwardEdges':sum(sum(x>0 for x in r['observation']['counts'])for r in report['rows'])}))
