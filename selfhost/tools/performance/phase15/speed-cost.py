import hashlib,json,pathlib,sys
base,candidate,out=map(pathlib.Path,sys.argv[1:])
identity=lambda p:{'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
cost=lambda p:{'physical':len(p.read_text().splitlines()),'nonblank':sum(bool(x.strip()) for x in p.read_text().splitlines()),'bytes':p.stat().st_size}
modules=json.loads((base/'src/compiler.json').read_text())['modules']
assert modules==json.loads((candidate/'src/compiler.json').read_text())['modules']
rows=[{'module':m,'baseline':identity(base/m),'candidate':identity(candidate/m),'before':cost(base/m),'after':cost(candidate/m)} for m in modules]
changed=[r['module'] for r in rows if r['baseline']['sha256']!=r['candidate']['sha256']]
assert changed==['src/core/term.bend'],changed
helper=[]
for m in ['tools/development/equality.mjs','tools/development/equality.test.mjs']:
 a,b=identity(base/m),identity(candidate/m);assert a['sha256']==b['sha256'];helper.append({'file':m,'before':a,'after':b,'cost':cost(base/m)})
research=[{'identity':identity(p),'cost':cost(p)} for p in sorted(pathlib.Path(__file__).parent.glob('speed-*')) if p.is_file()]
report={'kind':'phase15-lookup-cost-audit','complete':True,'pass':True,'inputs':[identity(pathlib.Path(__file__))], 'source':rows,'changed':changed,'unchangedHelper':helper,'researchTools':research,'scope':'Production source and helper costs separated from experimental tools, including failed versions. Existing reused controls are dependencies, not newly authored lines.'}
with out.open('x')as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'modules':len(rows),'changed':changed,'researchPhysical':sum(r['cost']['physical'] for r in research),'researchBytes':sum(r['cost']['bytes'] for r in research)}))
