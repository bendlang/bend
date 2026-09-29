from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/checker-literal-source-02/project';out=base/'build/phase16/checker-literal-source-03';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
# Static source review of source02 found the preparation wrapper included a
# following law in three functions. Preserve02 and repair delimiters only.
for name,func,law,result in [('src/back/js/literals.bend','j_u32_node','j_word','Maybe<&2, U32>'),('src/back/js/literals.bend','j_string','j_string_head','Maybe<&2, String>'),('src/back/native/bridge.bend','nc_literal','nc_compact','KTerm')]:
 p=project/name;s=p.read_text();a=s.index('def '+func+'(');b=s.index('\nlaw '+law+':',a);c=s.index('\n@unsafe',b);block=s[b:c];assert block.rstrip().endswith(result+')');s=s[:b].rstrip()+')\n'+block.rstrip()[:-1]+'\n'+s[c:];p.write_text(s)
changes=[]
for p in sorted(project.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(project);before=(old/rel).read_bytes();after=p.read_bytes()
 if before!=after:
  changes.append({'file':str(rel),'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest()})
  (out/(str(rel).replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=str(rel),tofile=str(rel))))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-compact-literal-preparation-correction','parent':str(old),'changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'source02Status':'static preparation rejection, never built; three law delimiters misplaced by wrapper','generationEnabled':True,'installationEligible':False},indent=2)+'\n')
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
