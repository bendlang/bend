import pathlib,shutil,json,hashlib,difflib
root=pathlib.Path.cwd();old=root/'selfhost/build/phase15/behavior-source-01/project';out=root/'selfhost/build/phase15/behavior-source-02';out.mkdir();project=out/'project'
for name in ['src','tools','tests/frontend/phase2-rules']:shutil.copytree(old/name,project/name)
(project/'dist').mkdir()
p=project/'tools/typed-driver.mjs';before=p.read_text();needle="  if(fs.readFileSync(path.join(project,'src/load/imports.bend'),'utf8').includes('def f_import_missing('))exports.push('f_import_missing');";assert before.count(needle)==1
s=before.replace(needle,"  if(files.includes('src/load/imports.bend')&&fs.readFileSync(path.join(project,'src/load/imports.bend'),'utf8').includes('def f_import_missing('))exports.push('f_import_missing');");p.write_text(s)
(out/'host-vs-candidate01.patch').write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='tools/typed-driver.mjs',tofile='tools/typed-driver.mjs')))
original=(root/'selfhost/build/phase14/combined-01/snapshot/tools/typed-driver.mjs').read_text();(out/'host-vs-release.patch').write_text(''.join(difflib.unified_diff(original.splitlines(True),s.splitlines(True),fromfile='tools/typed-driver.mjs',tofile='tools/typed-driver.mjs')))
ident=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(out/'manifest.json').write_text(json.dumps({'kind':'phase15-behavior-host-guard-revision','purpose':'Guard optional source-module feature detection in historical or minimal bootstrap trees.','host':ident(p),'originalHost':ident(root/'selfhost/build/phase14/combined-01/snapshot/tools/typed-driver.mjs'),'parentHost':ident(old/'tools/typed-driver.mjs'),'sourceUnchanged':all((project/p.relative_to(old)).read_bytes()==p.read_bytes() for p in (old/'src').rglob('*') if p.is_file()),'checkedBendAttempt':str(root/'selfhost/build/phase15/behavior-build-01'),'claim':'Host-only probe revision; new combined checked attempt required before release.','tool':ident(pathlib.Path(__file__).resolve())},indent=2)+'\n')
print(out)
