#!/usr/bin/env python3
"""Prepare a pristine-API event experiment with bounded sequential workers."""
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
parent=root/'selfhost/build/phase32/reuse-prototype-plan-01/plan.json';old=json.loads(parent.read_text())
original=pathlib.Path(old['baseline']['api']['file']);assert ident(original)['sha256']=='d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b'
text=original.read_text();assert text.count('function $dg_check_events$(')==1
needle='"check_program_diagnostic": run_lib((a0, a1, a2) => { const r = (run_loop($check_program_diagnostic$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),';assert text.count(needle)==1
appendix='''
const p32OriginalEvents=$dg_check_events$;
const p32OrdinaryCheck=run_lib((a0,a1,a2)=>{const r=run_loop($check_program_diagnostic$(a0,a1,a2));(a0);(a1);(a2);return r},3);
let p32Active=false;
export function p32Check(args,hook){
 if(p32Active)throw Error('Nested private checkpoint request');
 p32Active=true;
 $dg_check_events$=function(...xs){return hook(xs,ys=>run_loop(Reflect.apply(p32OriginalEvents,this,ys)),(d,rest)=>{const name=run_loop($dn$(d)),entry=run_loop($lookup$(rest,name)),kind=run_loop($dk$(entry));return [run_loop($signature_mode$(d,rest)),!run_loop($String$eq$(kind,'Absent'))]});};
 try{return p32OrdinaryCheck(...args)}finally{$dg_check_events$=p32OriginalEvents;p32Active=false}
}
'''
(out/'api.mjs').write_text(text+appendix);(out/'appendix.mjs').write_text(appendix)
worker=root/'selfhost/tools/performance/phase32/reuse-checkpoint-worker.mjs';runner=root/'selfhost/tools/performance/phase32/reuse-checkpoint-run.py'
for src,dst in [(worker,'worker.mjs'),(runner,'run.py'),(pathlib.Path(__file__),'consumed-prepare.py')]: (out/dst).write_bytes(src.read_bytes())
law='import Base\nlaw answer:\n  U32\ndef answer():\n  7\ndef main() -> U32:\n  answer()\n'
cases=[]
for c in old['cases']:
 c=dict(c)
 if 'text' in c:c['path']=str(out/'request.bend')
 cases.append(c)
for name,code in [('law-first',law),('law-unchanged',law),('law-body',law.replace('  7\n','  8\n')),('law-error',law.replace('  7\n','  True{}\n')),('law-restored',law),('duplicate',law+'def answer() -> U32:\n  9\n'),('order',law.replace('law answer:\n  U32\ndef answer():\n  7\n','def answer() -> U32:\n  7\nlaw answer:\n  U32\n'))]:
 f=out/(name+'.txt');f.write_text(code);cases.append(dict(id=name,text=ident(f),path=str(out/'request.bend'),dependency=''))
inputs=[ident(old['baseline'][k]['file']) for k in ['manifest','verifier','api','runtime','base','driver','cache']]
inputs +=[ident(c['source']['file'] if 'source' in c else c['text']['file']) for c in cases]
inputs +=[ident(x) for x in [parent,original,worker,runner,out/'worker.mjs',out/'run.py',out/'api.mjs',out/'appendix.mjs',pathlib.Path(__file__),root/'design/phase32/reuse-event-checkpoint.md',root/'design/phase32/reuse-memory-bounds.md']]
p=dict(kind='phase32-bounded-event-checkpoints',baseline=old['baseline'],api=ident(out/'api.mjs'),worker=ident(out/'worker.mjs'),node=ident('/home/ai/.nvm/versions/node/v24.18.0/bin/node'),heapMb=768,cpu='2',inputs=inputs,cases=cases,scope='Private immutable-input saved-code feasibility; no production semantic reuse.')
p['inputs'].append(p['node']);(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(out/'plan.json')
