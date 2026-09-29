from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/checker-literal-source-03/project';out=base/'build/phase16/checker-literal-source-05';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
p=project/'src/front/elaborate.bend';s=p.read_text();a=s.index('@unsafe\ndef f_word(');b=s.index('@unsafe\ndef f_u32(',a);s=s[:a]+s[b:];p.write_text(s)
p=project/'src/diagnostic/trace.bend';s=p.read_text();needle='String.eq(ce(r), "constructor requires a datatype goal") && String.eq(dk(lookup(cb(e), nm(t))), "ADT")';assert s.count(needle)==1;s=s.replace(needle,needle+' && String.eq(dg_family(cb(e), nm(t)), "")');p.write_text(s)
p=project/'tools/typed-driver.mjs';s=p.read_text();exports=['core_literal_step','core_literal_same','core_literal_type','norm_exact','compare','wnf','kp_show','graph_strong','term_key','f_literal','f_pattern_literal','j_literal','nc_compact','f_fresh_defs'];exports.remove('f_fresh_defs')
# Confirm public names before extending the checked probe API.
allcode='\n'.join(q.read_text() for q in (project/'src').rglob('*.bend'))
for name in exports:assert ('def '+name+'(') in allcode,name
s=s.replace('const exports=[...roots];','const exports=[...roots];\n  exports.push('+','.join(repr(x) for x in exports)+');')
s=s.replace("if(!module.G) return module.default;","if(literalAbi===1&&spanAbi!==3)throw Error('Literal ABI requires source-range ABI3');\n  if(!module.G) return module.default;")
needle="value.kind==='String'?value.number!==0:value.text!==''";assert needle in s;s=s.replace(needle,"value.kind==='String'?(value.number!==0||Array.from(value.text).some(c=>{const n=c.codePointAt(0);return n>=0xd800&&n<=0xdfff;})):value.text!==''")
p.write_text(s)
changes=[]
for p in sorted(project.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(project);before=(old/rel).read_bytes();after=p.read_bytes()
 if before!=after:
  changes.append({'file':str(rel),'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)})
  (out/(str(rel).replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=str(rel),tofile=str(rel))))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-compact-literal-boundary-probe','parent':str(old),'changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'f32NotePrerequisite':'checker-note-source-01, checked36 plus strict2','generationEnabled':True,'installationEligible':False},indent=2)+'\n')
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
