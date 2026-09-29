"""Retain pinned parser refusal05; project stable term in its own match scope."""
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4];OLD=ROOT/'selfhost/build/phase18/instance-world-source-05';OUT=ROOT/'selfhost/build/phase18/instance-world-source-06';PLAN=ROOT/'design/phase18/instance-world-public-binding.md'
prior=json.loads((OLD/'manifest.json').read_text());BASE=Path(prior['parent']);OUT.mkdir();project=OUT/'project';shutil.copytree(OLD/'project',project)
p=project/'src/check/specialize.bend';s=p.read_text();a='''      match payload:
        case KChecked{term, typ, uses, message}: DResult{error, book, dg_report_payload(term, error, "")}''';b='''      DResult{error, book, dg_report_payload(sp_payload_term(payload), error, "")}''';assert s.count(a)==1;s=s.replace(a,b)
s+='''
@unsafe
def sp_payload_term(+payload: KChecked) -> KTerm:
  match payload:
    case KChecked{term, typ, uses, error}: term
''';p.write_text(s)
def members(root):return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777} for p in sorted(root.rglob('*')) if p.is_file()}
def census(root):
 strings=[(root/n).read_text() for n in prior['after'] if n.endswith('.bend')]
 return {'physicalLines':sum(len(s.splitlines()) for s in strings),'nonblankLines':sum(sum(bool(l.strip()) for l in s.splitlines()) for s in strings),'bytes':sum(len(s.encode()) for s in strings),'definitions':sum(len(re.findall(r'^def ',s,re.M)) for s in strings),'laws':sum(len(re.findall(r'^law ',s,re.M)) for s in strings),'types':sum(len(re.findall(r'^type ',s,re.M)) for s in strings)}
after=members(project);changes=[n for n in prior['before'] if prior['before'][n]!=after[n]]
(OUT/'source.patch').write_text(''.join(''.join(difflib.unified_diff((BASE/n).read_text().splitlines(True),(project/n).read_text().splitlines(True),fromfile='a/'+n,tofile='b/'+n)) for n in changes))
(OUT/'binding.patch').write_text(''.join(difflib.unified_diff((OLD/'project/src/check/specialize.bend').read_text().splitlines(True),s.splitlines(True),fromfile='a/src/check/specialize.bend',tofile='b/src/check/specialize.bend')))
new=census(project);manifest={**prior,'project':str(project),'after':after,'newSource':new,'delta':{k:new[k]-prior['oldSource'][k] for k in new},'incrementalDelta':{k:new[k]-prior['newSource'][k] for k in new},'correction':'Project stable term in a helper to satisfy pinned match-binder rule; failed05 retained.','previousSource':str(OLD),'inputs':prior['inputs']+[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [Path(__file__),PLAN]]}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');config=json.loads((OLD/'workflow.json').read_text());config['project']=str(project);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');print(json.dumps({'delta':manifest['delta'],'incremental':manifest['incrementalDelta']}))
