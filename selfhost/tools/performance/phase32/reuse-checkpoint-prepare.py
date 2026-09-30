#!/usr/bin/env python3
"""Derive exact event checkpoint experiment; preserve predecessor and patch."""
import difflib,hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
source=root/'selfhost/build/phase32/reuse-prototype-plan-01/plan.json';p=json.loads(source.read_text());old=pathlib.Path(p['worker']['file']).read_text();worker=old;changes=[]
def replace(a,b):
 global worker
 assert worker.count(a)==1,(a,worker.count(a));worker=worker.replace(a,b);changes.append(dict(old=a,new=b))
replace("const chosen=role==='both'?['prefix','compact']:[role];","const chosen=role==='both'?['checkpoint']:[role];")
replace("function start(){at=0;", "let checkpointPrevious=null,checkpointCurrent=null,checkpointCursor=0;\nfunction start(){checkpointCurrent=null;checkpointCursor=0;at=0;")
replace("for(const variant of chosen){mode=variant;previous=[];", "for(const variant of chosen){mode=variant;previous=[];checkpointPrevious=null;")
replace("const observe=result=>", """globalThis.__p32EventsHook=(args,invoke,scheduleItem)=>{
 if(mode!=='checkpoint'||phase!=='check_program_diagnostic')return invoke(args);
 if(!checkpointCurrent){
  const started=performance.now();const schedule=[],tails=[];let todo=args[0];
  while(todo.$==='Con'){if(schedule.length>=10000)throw Error('Event cap');const [effective,later]=scheduleItem(todo.head,todo.tail);schedule.push({definition:todo.head,effective,later});tails.push(todo);todo=todo.tail}assert.equal(todo.$,'Nil');tails.push(todo);
  checkpointCurrent={initial:[args[1],args[2]],schedule,checkpoints:[]};let skip=0;
  if(checkpointPrevious&&equal(checkpointCurrent.initial,checkpointPrevious.initial)){
   checkpointCurrent.initial=checkpointPrevious.initial;
   const limit=Math.min(schedule.length,checkpointPrevious.schedule.length,checkpointPrevious.checkpoints.length-1);
   while(skip<limit&&equal(schedule[skip],checkpointPrevious.schedule[skip])){schedule[skip]=checkpointPrevious.schedule[skip];skip++}
   for(let i=0;i<skip;i++)checkpointCurrent.checkpoints[i]=checkpointPrevious.checkpoints[i];
  }
  stats.keyMs+=performance.now()-started;stats.logicalSkipped=skip;stats.hits=skip;
  if(skip){const cached=checkpointPrevious.checkpoints[skip];args=[tails[skip],cached.world,cached.seen];checkpointCursor=skip}
 }
 const index=checkpointCursor++;stats.calls++;checkpointCurrent.checkpoints[index]={world:args[1],seen:args[2]};return invoke(args);
};
const observe=result=>""")
replace("const t=performance.now(),actual=observe(await D.inspect(file,{mode:'library',api:variant==='baseline'?original:wrapped})),requestMs=performance.now()-t;", """const t=performance.now(),actual=observe(await D.inspect(file,{mode:'library',api:variant==='baseline'?original:wrapped}));
   if(variant==='checkpoint'&&checkpointCurrent){const freezeStart=performance.now();freeze(checkpointCurrent);stats.freezeMs+=performance.now()-freezeStart;checkpointPrevious=checkpointCurrent}
   const requestMs=performance.now()-t;""")
api=pathlib.Path(p['api']['file']).read_text();suffix='''
const p32OriginalEvents=$dg_check_events$;
$dg_check_events$=function(...args){
 const invoke=xs=>run_loop(Reflect.apply(p32OriginalEvents,this,xs));
 return globalThis.__p32EventsHook?globalThis.__p32EventsHook(args,invoke,(d,rest)=>[run_loop($signature_mode$(d,rest)),!$String$eq$($dk$(run_loop($lookup$(rest,$dn$(d)))),'Absent')]):invoke(args);
};
'''
assert api.count('function $dg_check_events$(')==1
(out/'api.mjs').write_text(api+suffix);(out/'api-appendix.mjs').write_text(suffix);(out/'worker.mjs').write_text(worker);(out/'original-worker.mjs').write_text(old)
(out/'worker.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),worker.splitlines(True),fromfile='prototype-worker',tofile='checkpoint-worker')));(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes())
p['kind']='phase32-exact-event-checkpoint';p['api']=ident(out/'api.mjs');p['worker']=ident(out/'worker.mjs');p['inputs'] +=[ident(source),p['api'],p['worker'],ident(__file__),ident(root/'design/phase32/reuse-event-checkpoint.md')]
law='import Base\nlaw answer:\n  U32\ndef answer():\n  7\ndef main() -> U32:\n  answer()\n'
extra=[('law-first',law),('law-unchanged',law),('law-body',law.replace('  7\n','  8\n')),('law-error',law.replace('  7\n','  True{}\n')),('law-restored',law),('duplicate',law+'def answer() -> U32:\n  9\n'),('order',law.replace('law answer:\n  U32\ndef answer():\n  7\n','def answer() -> U32:\n  7\nlaw answer:\n  U32\n'))]
for name,text in extra:
 f=out/(name+'.txt');f.write_text(text);item=ident(f);p['cases'].append(dict(id=name,text=item,path=str(out/'request.bend'),dependency=''));p['inputs'].append(item)
p['cases']=[{**c,**({'path':str(out/'request.bend')} if 'text' in c else {})} for c in p['cases']]
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');(out/'derivation.json').write_text(json.dumps(dict(original=ident(pathlib.Path(json.loads(source.read_text())['worker']['file'])),changes=changes,apiAppendix=ident(out/'api-appendix.mjs')),indent=2)+'\n');print(out/'plan.json')
