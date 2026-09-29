from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/wave4-source-02/project';out=base/'build/phase16/checker-base-prefix-source-01';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
p=project/'tools/typed-driver.mjs';before=p.read_bytes();s=before.decode();needle="const exports=[...roots];";assert s.count(needle)==1
exports=['f_fresh_defs','fs_load','f_seed_matches','f_graph_result','f_validate_result','f_graph_fresh_result','f_path_dir','f_graph_source','f_source_path']
s=s.replace(needle,needle+'\n  exports.push('+','.join(repr(x) for x in exports)+');');p.write_text(s)
modules=[]
for q in sorted((old/'src').rglob('*.bend')):
 relative=q.relative_to(old);sha=hashlib.sha256(q.read_bytes()).hexdigest();assert sha==hashlib.sha256((project/relative).read_bytes()).hexdigest();modules.append({'path':str(relative),'sha256':sha})
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-exact-base-freshening-proof-exports','implementationParent':str(old),'exports':exports,'hostBeforeSha256':hashlib.sha256(before).hexdigest(),'hostAfterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-base-prefix-proof.md'),'modules':modules,'installationEligible':False},indent=2)+'\n')
(out/'host.patch').write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),s.splitlines(True),fromfile='tools/typed-driver.mjs',tofile='tools/typed-driver.mjs')))
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
print(out)
