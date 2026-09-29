from pathlib import Path
import shutil,json,hashlib,difflib,re
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/wave6-source-01/project';tested=base/'build/phase16/checker-literal-source-05/project';out=base/'build/phase16/checker-literal-handoff-01';out.mkdir();project=out/'project';shutil.copytree(tested,project)
p=project/'tools/typed-driver.mjs';s=p.read_text();lines=s.splitlines(True);removed=[l for l in lines if l.startswith('  exports.push(')];assert len(removed)==2;assert all('core_literal' in l for l in removed);s=''.join(l for l in lines if l not in removed);p.write_text(s)
changes=[];patch=[]
for p in sorted(project.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(project);before=(old/rel).read_bytes();after=p.read_bytes()
 if before!=after:
  row={'file':str(rel),'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'testedSource05Sha256':hashlib.sha256((tested/rel).read_bytes()).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)};changes.append(row)
  patch.append(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='a/'+str(rel),tofile='b/'+str(rel))))
(out/'combined.patch').write_text(''.join(patch));(out/'manifest.json').write_text(json.dumps({'kind':'phase16-compact-literal-production-handoff','parent':str(old),'testedSource':str(tested),'changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'probeExportsRemoved':removed,'hostOnlyDifferenceFromTestedSource05':'Remove two probe-only exports.push lines; Bend module bytes identical. Root must build integrated image.','plannedNextABI':'carets-owned compiler_term_abi1 +cachev6 unifying KLiteral/KLambda; literal-only ABI1/cachev5 remains frozen tested prototype','installationEligible':False,'openContract':'Exact pinned memoJSON serialization/UTF16size awaits explicit KLambda metadata; current compact term_key incidental length is unselected.'},indent=2)+'\n')
print(json.dumps({'out':str(out),'files':len(changes),'sourceLineDelta':sum(x['physicalLineDelta'] for x in changes if x['file'].endswith('.bend')),'sourceByteDelta':sum(x['byteDelta'] for x in changes if x['file'].endswith('.bend'))}))
