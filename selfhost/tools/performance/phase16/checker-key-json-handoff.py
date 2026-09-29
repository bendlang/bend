from pathlib import Path
import sys, shutil, json, hashlib, difflib
root = Path.cwd()
phase = root / 'selfhost/build/phase16'
parent = phase / 'literal-context-source-04/project'
metadata = phase / 'spans-lambda-source-04/project'
metadata_prior = phase / 'spans-lambda-source-03/project'
checked = phase / 'checker-key-json-source-02/project'
out = Path(sys.argv[1]).resolve()
sha = lambda b: hashlib.sha256(b).hexdigest()
def identity(p):
    b = p.read_bytes()
    return {'file': str(p), 'sha256': sha(b), 'bytes': len(b)}
module = 'src/check/specialize.bend'
assert (metadata / module).read_bytes() == (metadata_prior / module).read_bytes()
probe = "\n  exports.push('term_key','sp_keys','sp_len','sk_quote');"
checked_host = (checked / 'tools/typed-driver.mjs').read_text()
assert checked_host.count(probe) == 1
assert checked_host.replace(probe, '') == (metadata_prior / 'tools/typed-driver.mjs').read_text()
assert (metadata / 'tools/typed-driver.mjs').read_bytes() == (metadata_prior / 'tools/typed-driver.mjs').read_bytes()
for f in ['src/check/kernel.bend', 'src/check/annotate.bend']:
    assert (metadata / f).read_bytes() != (metadata_prior / f).read_bytes()
out.mkdir()
project = out / 'project'
shutil.copytree(metadata, project)
shutil.copy2(checked / module, project / module)
assert probe not in (project / 'tools/typed-driver.mjs').read_text()
changes = []
patch = []
parent_files = {p.relative_to(parent) for p in parent.rglob('*') if p.is_file()}
final_files = {p.relative_to(project) for p in project.rglob('*') if p.is_file()}
assert parent_files == final_files
for rel in sorted(parent_files):
    before, after = (parent / rel).read_bytes(), (project / rel).read_bytes()
    if before != after:
        changes.append({'file': str(rel), 'beforeSha256': sha(before), 'afterSha256': sha(after), 'physicalLineDelta': len(after.splitlines())-len(before.splitlines()), 'byteDelta': len(after)-len(before)})
        patch.append(''.join(difflib.unified_diff(before.decode().splitlines(True), after.decode().splitlines(True), fromfile='a/'+str(rel), tofile='b/'+str(rel))))
(out/'combined.patch').write_text(''.join(patch))
(out/'memo.patch').write_text(''.join(difflib.unified_diff((metadata/module).read_text().splitlines(True),(project/module).read_text().splitlines(True),fromfile='a/'+module,tofile='b/'+module)))
manifest = {'kind':'phase16-canonical-memo-production-handoff','parent':str(parent),'metadataParent':str(metadata),'checkedEncoderParent':str(checked),'checkedEncoderAttempt':identity(phase/'checker-key-json-build-02/attempt.json'),'productionSourceCheckedAsUnion':False,'integrationRequirement':'Root must genuinely check this source composition; no prior API reuse claims the source04 semantic overlay was compiled with the encoder.','strippedProbeExports':['term_key','sp_keys','sp_len','sk_quote'],'sourcePolicy':'All final files come byte-for-byte from metadata source04 except the one checked encoder module. Production host is metadata source04 unchanged.','sourceParents':[identity(phase/'spans-lambda-source-04/manifest.json'),identity(phase/'checker-key-json-source-02/manifest.json')],'changes':changes,'completeParentFiles':[{'file':str(rel),'sha256':sha((parent/rel).read_bytes())} for rel in sorted(parent_files)],'completeFinalFiles':[{'file':str(rel),'sha256':sha((project/rel).read_bytes())} for rel in sorted(final_files)],'tool':identity(Path(__file__))}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'out':str(out),'changedFiles':len(changes),'memoSha256':sha((project/module).read_bytes())}))
