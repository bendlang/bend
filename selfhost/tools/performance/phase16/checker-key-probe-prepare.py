from pathlib import Path
import shutil,json,hashlib
root=Path.cwd();base=root/'selfhost'
for version in ['05','06']:
 old=base/f'build/phase16/checker-source-{version}/project';out=base/f'build/phase16/checker-key-probe-source-{version}';out.mkdir();shutil.copytree(old,out/'project');project=out/'project';p=project/'tools/typed-driver.mjs';before=p.read_bytes();s=before.decode();needle="exports.push('specialize_book','specialized_book','specialized_error');";assert s.count(needle)==1;s=s.replace(needle,needle+"\n    exports.push('term_key','sp_keys','sp_len','sp_initial','sp_definitions','sp_canonical','sp_shift','sp_apply_template','norm_max_book','norm_max_term');");p.write_text(s)
 (out/'manifest.json').write_text(json.dumps({'kind':'phase16-key-length-probe-exports','implementationParent':f'checker-source-{version}','hostBeforeSha256':hashlib.sha256(before).hexdigest(),'hostAfterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-key-length.md'),'installationEligible':False},indent=2)+'\n')
 (out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');print(out)
