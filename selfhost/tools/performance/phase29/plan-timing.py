#!/usr/bin/env python3
"""Freeze final checked-candidate comparisons before any clean timing starts."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
raw=ROOT/'selfhost/build/phase29'
transfer,fixture,component,corpus,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(name,x):(out/name).write_text(json.dumps(x,indent=2)+'\n')
original=json.loads((raw/'prototype-confirm-config.json').read_text())
base=original['cases'][0]
inputs=[*original['inputs'],ident(fixture/'candidate.mjs.json'),ident(fixture/'1.stdout'),ident(Path(__file__))]
modules={'upstream':base['modules']['upstream'],'old':base['modules']['unchanged'],
 'arithmetic':base['modules']['compiler-arithmetic'],'candidate':str(fixture/'candidate.mjs')}
for protocol,name,sides in [('screen','fixture-screen.json',['old','candidate']),('confirm','fixture-confirm.json',list(modules))]:
    save(name,{'protocol':protocol,'inputs':inputs,'cases':[{'id':base['id'],'point':base['point'],'modules':{s:modules[s] for s in sides}}]})
full=json.loads((transfer/'timing-config.json').read_text())
assert json.loads((transfer/'report.json').read_text())['complete']
arith=json.loads((raw/'transfer-01/report.json').read_text())
assert arith['complete']
arithcases={c['id']:c for c in arith['cases']}
full['inputs'] += [ident(raw/'transfer-01/report.json'),ident(Path(__file__))]
for c in full['cases']:
    if c['id'] in arithcases:
        module=Path(arithcases[c['id']]['modules']['candidate'])
        full['inputs'].append(ident(Path(str(module)+'.json')))
        c['modules']['arithmetic']=str(module)
save('transfer.json',full)
# The same four cases triggered longer warmup in Phase28. Fix their follow-up
# now, preserving both windows even if the new short window looks favorable.
warm={'protocol':'confirm','inputs':full['inputs'],'cases':[
 c for c in full['cases'] if c['id'] in ['mandelbrot','tree-bitonic','test-morning-program','test-map-set-ops']]}
save('transfer-confirm.json',warm)
component_report=json.loads((component/'report.json').read_text());assert component_report['complete']
component_case={'id':'compiler-membership','point':{'args':[256,17],'expected':17},'modules':{
 'upstream':str(ROOT/'selfhost/build/phase27/component-upstream-01/upstream.mjs'),
 'old':str(ROOT/'selfhost/build/phase27/component-candidate-02/selfhost.mjs'),
 'candidate':str(component/'candidate.mjs')}}
controls=[component_case]
for key,args,expected in [('term-substitution',[256,18],131602),('boolean-worker',[1024,18],4114)]:
    controls.append({'id':key,'point':{'args':args,'expected':expected},'modules':{
      'upstream':str(ROOT/'selfhost/build/phase25/corpus-01'/key/'upstream.mjs'),
      'old':str(ROOT/'selfhost/build/phase27/corpus-02'/key/'candidate.mjs'),
      'candidate':str(corpus/key/'candidate.mjs')}})
control_inputs=[ident(component/'report.json'),ident(component/'candidate.mjs.json'),ident(corpus/'report.json'),ident(Path(__file__))]
for c in controls:
    for module in c['modules'].values():
        receipt=Path(module+'.json')
        if receipt.exists():control_inputs.append(ident(receipt))
save('components-confirm.json',{'protocol':'confirm','inputs':control_inputs,'cases':controls})
save('plan.json',{'complete':True,'configs':[ident(p) for p in sorted(out.glob('*.json'))],
 'scope':'All clean comparisons fixed before execution; final checked output against unchanged checked baselines. Warm follow-up retains all four previously flagged original programs. Component controls retain substitution and Boolean traversal. No survivor-only aggregate.'})
print(json.dumps({'complete':True,'output':str(out)}))
