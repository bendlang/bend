#!/usr/bin/env python3
"""Freeze checked07 semantic/query instrumentation; no compiler execution."""
import hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[4]
out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=pathlib.Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
previous=root/'selfhost/build/phase31/final-plan-07/compiler-cost-plan/config.json'
p=json.loads(previous.read_text());v=p['variants']['candidate']
names=['check_definition_world','wnf','j_arm_type','j_primitive_type','j_nat_loop_native','j_nat_shape','j_nat_loop_worker','j_tree_worker','j_region_root','j_region_plan','j_region_local_type','j_region_local_check','j_region_local_signature','j_region_capture_eligible','j_u32_worker']
old=pathlib.Path(v['api']['file']).read_text();suffix='\n// Phase32 diagnostic derivative: all calls remain ordinary compiler calls.\n'
for name in names:
 symbol='$'+name+'$';assert old.count('function '+symbol+'(')==1,name
 suffix+=f'const p32_original_{name}={symbol};\n{symbol}=function(...args){{return globalThis.__p32Hook ? globalThis.__p32Hook({json.dumps(name)},args,()=>run_loop(Reflect.apply(p32_original_{name},this,args))) : Reflect.apply(p32_original_{name},this,args)}};\n'
(out/'api.mjs').write_text(old+suffix);(out/'appendix.mjs').write_text(suffix)
(out/'consumed-prepare.py').write_bytes(pathlib.Path(__file__).read_bytes())
worker=root/'selfhost/tools/performance/phase32/reuse-worker.mjs';(out/'worker.mjs').write_bytes(worker.read_bytes())
small=(root/'selfhost/build/phase30/self-emission-plan-16/positive.bend').read_text()
fixtures=[('small',small),('unchanged',small),('body-edit',small.replace('value, 3','value, 4')),('type-error',small.replace('value, 3','value, True{}')),('restored',small),('signature-edit',small.replace('def main() -> U32:', 'def main() -> Bool:')),('origin-shift','# coordinate shift\n'+small),('dependency','import Base\nimport ./dep.bend as D\ndef main() -> U32:\n  D.value()\n'),('dependency-edit','import Base\nimport ./dep.bend as D\ndef main() -> U32:\n  D.value()\n')]
cases=[]
for name,text in fixtures:
 f=out/(name+'.txt');f.write_text(text);cases.append(dict(id=name,text=ident(f),path=str(out/'request.bend'),dependency='import Base\ndef value() -> U32:\n  '+('5' if name=='dependency-edit' else '4')+'\n'))
for c in p['cases']:cases.append(dict(id=c['id'],source=c['source']))
inputs=[ident(previous),ident(worker),ident(__file__),ident(root/'design/phase32/reuse-exact-state.md'),ident(root/'design/phase32/compact-query-counts.md')]+[ident(v[k]['file']) for k in ['api','runtime','base','driver','cache']]+[ident(out/'api.mjs'),ident(out/'worker.mjs')]+[c.get('text',c.get('source')) for c in cases]
plan=dict(kind='phase32-reuse-compact-diagnostic',cpu='2',timeoutSeconds=120,complete=True,baseline=v,api=ident(out/'api.mjs'),worker=ident(out/'worker.mjs'),inputs=inputs,cases=cases,names=names,merkleObjectCap=1000000,queryCap=1000000,derivation=dict(original=ident(v['api']['file']),appendix=ident(out/'appendix.mjs'),originalPrefixExact=(out/'api.mjs').read_text()[:-len(suffix)]==old),scope='Diagnostic counts and inclusive instrumented costs only, never clean speed ratios.')
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');print(out/'plan.json')
