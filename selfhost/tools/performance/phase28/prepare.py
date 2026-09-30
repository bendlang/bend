#!/usr/bin/env python3
"""Freeze ten successful identical-source library pairs before clean timing."""
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
RAW=ROOT/'selfhost/build/phase28';PIN='018751270e800bc222a93dad7f257083ee53a5f7'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
ident=lambda p:{'file':str(Path(p).resolve()),'sha256':sha(p)}
selected=json.loads((RAW/'runtime-pairs.json').read_text());assert selected['complete']
apps=json.loads((HERE/'application-cases.json').read_text())
upstream=ROOT/'selfhost/.bootstrap/upstream-phase23'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=upstream,text=True).strip()==PIN
assert not subprocess.check_output(['git','status','--porcelain'],cwd=upstream,text=True).strip()
manifest={'kind':'phase28-frozen-library-pairs','complete':False,'pin':PIN,'cases':[],'inputs':[]}
cases=[]
for c in selected['cases']:
    p=c['point'];cases.append({'id':c['id'],'category':'algorithm','inputDescription':c['wrapperParameters'],
       'source':str(ROOT/c['fixture']['path']),'exportName':'bench','args':[p['size'],p['seed']],'expected':p['expected'],
       'modules':{v:c['variants'][v]['module'] for v in ['upstream','selfhost']}})
for c in apps['cases']:
    if c['mode']!='library':continue
    cases.append({'id':c['id'],'category':'small-integration','inputDescription':c['inputScope'],
       'source':str(ROOT/c['source']),'exportName':c['exportName'],'args':c['args'],'expected':c['expected'],
       'modules':{v:str(RAW/'applications-01'/c['id']/(v+'.mjs')) for v in ['upstream','selfhost']}})
# Keep the known expensive ray tracer last; every named case remains selected.
cases=[c for c in cases if c['id']!='raytrace']+[next(c for c in cases if c['id']=='raytrace')]
assert len(cases)==10
for c in cases:
    receipts={};source=ident(c['source'])
    for side,module in c['modules'].items():
        receipt=Path(module+'.json');r=json.loads(receipt.read_text());assert r['complete']
        assert r.get('checked') or r['observation']['checked']
        assert r['input']['sha256']==source['sha256'] and r['output']['sha256']==sha(module)
        if side=='selfhost':
            assert r['api']['sha256']=='5a89c775e903374341da4b4e32c29d26ffe687677f088c590046f748b69d81c5'
            assert r['runtime']['sha256']=='40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f'
            for key in ['api','runtime','base','driver','attempt']:
                assert sha(r[key]['file'])==r[key]['sha256'];manifest['inputs'].append(ident(r[key]['file']))
        receipts[side]=ident(receipt);manifest['inputs'].extend([ident(receipt),ident(module)])
    manifest['cases'].append({**c,'source':source,'receipts':receipts});manifest['inputs'].append(source)
manifest['inputs'].extend(ident(p) for p in sorted((upstream/'bend2').rglob('*')) if p.is_file() and p.suffix in ['.ts','.bend','.js'])
manifest['inputs'].extend(ident(p) for p in [HERE/'prepare.py',HERE/'execute.mjs',HERE/'measure.py',RAW/'runtime-pairs.json',HERE/'application-cases.json',ROOT/'selfhost/dist/release.json'])
manifest['complete']=True
for name,value in [('library-provenance.json',manifest),('timing-config.json',{'cases':cases})]:
    p=RAW/name;assert not p.exists();p.write_text(json.dumps(value,indent=2)+'\n')
