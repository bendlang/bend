#!/usr/bin/env python3
"""Prepare bounded emitter-only cache experiment without executing a compiler."""
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4]
out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
source=root/'selfhost/build/phase32/reuse-prototype-plan-01/plan.json'
old=json.loads(source.read_text())
original=pathlib.Path(old['baseline']['api']['file'])
assert ident(original)['sha256']=='d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b'
text=original.read_text()
names=['wnf','j_arm_type','j_primitive_type','j_nat_loop_native','j_nat_shape','j_region_local_type','j_region_local_signature','j_region_capture_eligible']
for name in names:assert text.count('function $'+name+'$(')==1,name
appendix='''
// Phase32 private saved-code experiment. Bindings exist only during emission.
let p32Active=false,p32LastStats=null;
const p32Limit=4096;
const p32Originals=[NAMES];
export function p32Stats(){return p32LastStats}
export function p32Emit(args){
 if(p32Active)throw Error('Nested private emitter experiment refused');
 p32Active=true;
 let entries=0;
 const stats={entries:0,limit:p32Limit,queries:{}};
 const wrappers=p32Originals.map((original,index)=>{
  const root=new Map(),resultKey=Symbol('result');
  const counts=stats.queries[NAMELIST[index]]={calls:0,hits:0,entries:0};
  return function(...xs){
   counts.calls++;
   let table=root;
   for(const x of xs){
    let next=table.get(x);
    if(!next){
     if(entries>=p32Limit)return run_loop(Reflect.apply(original,this,xs));
     next=new Map();table.set(x,next);
    }
    table=next;
   }
   if(table.has(resultKey)){counts.hits++;return table.get(resultKey)}
   const result=run_loop(Reflect.apply(original,this,xs));
   if(entries<p32Limit){table.set(resultKey,result);counts.entries++;stats.entries=++entries}
   return result;
  };
 });
 try {
  ASSIGN
  return run_loop($j_library_selected$(...args));
 }finally{
  RESTORE
  p32LastStats=stats;p32Active=false;
 }
}
'''.replace('NAMES',','.join('$'+n+'$' for n in names)).replace('NAMELIST',json.dumps(names)).replace('ASSIGN','\n  '.join('$'+n+'$=wrappers['+str(i)+'];' for i,n in enumerate(names))).replace('RESTORE','\n  '.join('$'+n+'$=p32Originals['+str(i)+'];' for i,n in enumerate(names)))
# Call the ordinary exported trampoline wrapper, not an alternate request path.
needle='"j_library_selected": run_lib((a0, a1) => { const r = (run_loop($j_library_selected$((a0), (a1)))); (a0); (a1); return r; }, 2),'
assert text.count(needle)==1
appendix=appendix.replace('return run_loop($j_library_selected$(...args));','return p32OrdinaryEmitter(...args);')
appendix=appendix.replace('let p32Active=false', 'const p32OrdinaryEmitter=run_lib((a0,a1)=>{const r=run_loop($j_library_selected$(a0,a1));(a0);(a1);return r},2);\nlet p32Active=false')
(out/'api.mjs').write_text(text+appendix);(out/'appendix.mjs').write_text(appendix)
worker=root/'selfhost/tools/performance/phase32/compact-scoped-worker.mjs'
runner=root/'selfhost/tools/performance/phase32/compact-scoped-run.py'
for src,dst in [(worker,'worker.mjs'),(runner,'run.py'),(pathlib.Path(__file__),'consumed-prepare.py')]: (out/dst).write_bytes(src.read_bytes())
cases=[]
for c in old['cases']:
 c=dict(c)
 if 'text' in c:c['path']=str(out/'request.bend')
 cases.append(c)
inputs=[]
# Historic diagnostics are not loaded and are deliberately outside this plan.
for key in ['manifest','verifier','api','runtime','base','driver','cache']:inputs.append(ident(old['baseline'][key]['file']))
for c in cases:inputs.append(ident(c['source']['file'] if 'source' in c else c['text']['file']))
for x in [source,original,worker,runner,out/'worker.mjs',out/'run.py',out/'api.mjs',out/'appendix.mjs',pathlib.Path(__file__),root/'design/phase32/compact-emitter-scoped.md']:inputs.append(ident(x))
p=dict(kind='phase32-emitter-scoped-query-memo',baseline=old['baseline'],api=ident(out/'api.mjs'),worker=ident(out/'worker.mjs'),node=ident('/home/ai/.nvm/versions/node/v24.18.0/bin/node'),heapMb=768,cpu='2',inputs=inputs,cases=cases,correctnessOrder=['baseline','compact'],screenOrder=['baseline','compact','compact','baseline'],scope='Private immutable-input saved-code experiment only; no production entry or cache.')
p['inputs'].append(p['node'])
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n')
print(out/'plan.json')
