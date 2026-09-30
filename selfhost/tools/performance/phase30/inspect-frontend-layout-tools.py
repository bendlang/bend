#!/usr/bin/env python3
"""Freeze the existing exact frontend gate with explicit supported layout audit."""
from pathlib import Path
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
out = Path(sys.argv[1]).resolve()
source = HERE.parent / 'phase23/frontend-gate-v2.mjs'
compare = HERE.parent / 'phase22/frontend-layout-compare.mjs'
before = ROOT / 'selfhost/build/phase23/frontend-main-01/selected/harness/src/compiler.json'
after = ROOT / 'selfhost/build/phase30/attempt-16/snapshot/src/compiler.json'


def identity(file):
    raw = file.read_bytes()
    return {'file': str(file.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


assert identity(source)['sha256'] == 'c982231adf6142ea6daaa78ece81ef4568fc7b34e8c08f034b16617d55ffd078'
assert identity(before)['sha256'] == 'ab196d008363b3bb403fe3c5b43fb5cf17605e614eb23e7f807408c05b358814'
assert identity(after)['sha256'] == '954e4cfb54fc94a81e4a55bb264c121b0d860ebd201c1a743b4eff1a0042c63d'
a, b = json.loads(before.read_text()), json.loads(after.read_text())
non = lambda d: {k: v for k, v in d.items() if k != 'modules'}
assert non(a) == non(b) == {'upstream': '018751270e800bc222a93dad7f257083ee53a5f7', 'targetVersion': '2.0.34'}
assert len(a['modules']) == 60 and len(b['modules']) == 65
assert [x for x in a['modules'] if x not in b['modules']] == []
assert [x for x in b['modules'] if x not in a['modules']] == ['src/back/js/u32.bend', 'src/back/js/primitive.bend', 'src/back/js/region.bend', 'src/back/js/worker.bend', 'src/back/js/tree.bend']
text = source.read_text()
changes = []


def replace(old, new):
    global text
    assert text.count(old) == 1, old
    text = text.replace(old, new)
    changes.append({'old': old, 'new': new})


replace("from '../phase22/frontend-layout-compare.mjs'", 'from ' + json.dumps(str(compare)))
replace("path.resolve(import.meta.dirname,'../phase22/frontend-layout-compare.mjs')", json.dumps(str(compare)))
replace("[attemptArg,outArg,scope='main',reuseArg,selectionArg]", "[attemptArg,outArg,scope='main',reuseArg,selectionArg,layoutArg,reuseCandidateGateArg]")
replace("const read=f=>JSON.parse(fs.readFileSync(f)),write=(f,x)=>fs.writeFileSync(f,JSON.stringify(x,null,2)+'\\n');",
        "const read=f=>JSON.parse(fs.readFileSync(f)),write=(f,x)=>fs.writeFileSync(f,JSON.stringify(x,null,2)+'\\n');\nconst layoutFile=fs.realpathSync(layoutArg),moduleLayoutMigration=read(layoutFile);")
replace('const inputs=[import.meta.filename,process.execPath,', 'const inputs=[layoutFile,...(reuseCandidateGateArg?[fs.realpathSync(reuseCandidateGateArg)]:[]),import.meta.filename,process.execPath,')
replace("kind:'phase23-attested-reference-frontend-gate'", "kind:'phase30-explicit-layout-frontend-gate'")
replace('compareReports(a,b,{strictPaths:true})', 'compareReports(a,b,{strictPaths:true,moduleLayoutMigration})')
start = text.index(" const destination=path.join(out,'candidate.json');")
end = text.index(' const a=read(referenceFile),b=read(destination);', start)
original_acquisition = text[start:end]
body = original_acquisition.replace(" const destination=path.join(out,'candidate.json');\n", '', 1)
replacement = ''' let destination;
 if(reuseCandidateGateArg){
  const reused=read(fs.realpathSync(reuseCandidateGateArg));
  assert.equal(reused.error.split('\\n')[0],'Error: Different target manifests in strict comparison');
  assert.equal(reused.complete,false);assert.equal(reused.pass,false);assert.equal(reused.scope,scope);assert.equal(reused.expected,expected);
  assert.equal(reused.api.sha256,m.api.sha256);assert.equal(reused.referencePin,inv.revision);
  assert.equal(reused.execution.timedOut,false);assert.equal(reused.execution.error,null);assert.equal(reused.execution.signal,null);
  assert.equal(reused.execution.overflow,false);assert.ok([0,1].includes(reused.execution.exitCode));
  reused.inputs.forEach(verifyIdentity);verifyIdentity(reused.candidate);
  destination=fs.realpathSync(reused.candidate.file);
  report.acquisitionReuse={gate:identity(fs.realpathSync(reuseCandidateGateArg)),candidate:identity(destination),policy:'Retained complete worker acquisition; original strict-manifest gate failure preserved separately.'};save();
 }else{
  destination=path.join(out,'candidate.json');
''' + body + ''' }
'''
replace(original_acquisition, replacement)
replace(' const a=read(referenceFile),b=read(destination);', ''' const a=read(referenceFile),b=read(destination);
 for(const [key,expected]of [['compiler',m.api],['runtime',m.runtime],['base',m.base]]){
  const actual=b.identity.artifacts[key];assert.equal(fs.realpathSync(actual.file),fs.realpathSync(expected.file));assert.equal(actual.sha256,expected.sha256);
 }
''')
out.mkdir(parents=True, exist_ok=False)
descriptor = {'kind': 'explicit-compiler-module-layout-migration', 'expectedNonModules': non(a),
              'before': {'sha256': identity(before)['sha256'], 'modules': a['modules']},
              'after': {'sha256': identity(after)['sha256'], 'modules': b['modules']}}
(out / 'migration.json').write_text(json.dumps(descriptor, indent=2) + '\n')
(out / 'gate.mjs').write_text(text)
(out / 'original-gate.mjs').write_bytes(source.read_bytes())
(out / 'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
(out / 'derive.json').write_text(json.dumps({'kind': 'phase30-exact-frontend-layout-gate-derivation', 'complete': True,
    'inputs': [identity(p) for p in [Path(__file__), source, compare, before, after, ROOT / 'design/phase30/frontend-layout-renewal.md']],
    'output': identity(out / 'gate.mjs'), 'migration': identity(out / 'migration.json'), 'changes': changes,
    'scope': 'Existing strict-path comparator with exact supported module-layout descriptor; optional saved main acquisition with full identity/worker/all-fields revalidation. No fixtures run by derivation.'}, indent=2) + '\n')
print(json.dumps({'complete': True, 'out': str(out)}))
