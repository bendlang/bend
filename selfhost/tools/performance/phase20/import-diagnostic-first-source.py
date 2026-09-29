"""Compose only two constant-time first-element guards around original parser bodies."""
from pathlib import Path
import json,hashlib,shutil,difflib,re
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';BASE=P/'import-diagnostic-source-02/project';O=P/'import-diagnostic-source-03'
baseline=P/'import-diagnostic-first-baseline-01/report.json';b=json.loads(baseline.read_text());assert b['complete']and b['pass']and b['count']==54
guardfile=R/'selfhost/build/phase19/context-row-source-05/first-element-only.patch';guards=guardfile.read_text()
O.mkdir();C=O/'project';shutil.copytree(BASE,C);p=C/'src/front/declarations.bend';old=p.read_text();lines=old.splitlines(True);bodies=[]
for name,acc in [('f_match_heads','acc'),('f_case_pats','pats')]:
 indexes=[i for i,l in enumerate(lines)if l.startswith('def '+name+'(')];assert len(indexes)==1;i=indexes[0]+1;body=lines[i].strip();assert body.startswith('f_choose(FParsed,')
 prefix='f_choose(FParsed, List.is_empty(&2, KTerm, '+acc+') && (f_eq(f_tx(ts), ":") || f_eq(f_tx(ts), ",")), u => fpe_error(ts, "expected term", "a term"), u => '
 assert ('+  '+prefix)in guards
 wrapped=prefix+body+')';assert wrapped[len(prefix):-1]==body
 lines[i]='  '+wrapped+'\n';bodies.append({'function':name,'preservedBodySha256':hashlib.sha256(body.encode()).hexdigest(),'emptyTest':'List.is_empty','addedHelper':False})
new=''.join(lines);assert 'FInput'not in new and 'f_context_case'not in new;p.write_text(new)
parent19=(R/'selfhost/build/phase19/instance-source-04/project/src/front/declarations.bend').read_text()
for name,left in [('declarations-parent02.patch',old),('declarations-phase19.patch',parent19)]:
 (O/name).write_text(''.join(difflib.unified_diff(left.splitlines(True),new.splitlines(True),fromfile='parent/src/front/declarations.bend',tofile='source03/src/front/declarations.bend')))
shutil.copy2(guardfile,O/'consumed-first-element-only.patch')
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(C);(O/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
delta=lambda before,after:{'physicalLines':len(after.splitlines())-len(before.splitlines()),'bytes':len(after.encode())-len(before.encode()),**{k:len(re.findall(r'^'+word+' ',after,re.M))-len(re.findall(r'^'+word+' ',before,re.M))for k,word in [('definitions','def'),('laws','law'),('types','type')]}}
inputs=[Path(__file__),R/'design/phase20/import-diagnostic-first-elements.md',R/'design/phase20/declaration-checkpoints-integration.md',P/'import-diagnostic-first-controls-01/plan.json',baseline,BASE.parent/'manifest.json',guardfile]
(O/'manifest.json').write_text(json.dumps({'kind':'phase20-first-element-composition','complete':True,'frozen':True,'parent':str(BASE),'project':str(C),'changedFiles':['src/front/declarations.bend'],'preservedOriginalBodies':bodies,'deltaParent02':delta(old,new),'deltaPhase19':delta(parent19,new),'hostChanges':False,'inputs':[identity(p)for p in inputs],'members':{str(f.relative_to(C)):{'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777}for f in sorted(C.rglob('*'))if f.is_file()},'installed':False},indent=2)+'\n');print(O)
