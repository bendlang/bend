"""Keep historical public specialization payload; rename expanded private result."""
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4];OLD=ROOT/'selfhost/build/phase18/instance-world-source-03';OUT=ROOT/'selfhost/build/phase18/instance-world-source-04';PLAN=ROOT/'design/phase18/instance-world-public-boundary.md'
prior=json.loads((OLD/'manifest.json').read_text());BASE=Path(prior['parent'])
def change(s,a,b,n=1):assert s.count(a)==n,(a,s.count(a));return s.replace(a,b)
def function(s,name,fn):
 m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
 end=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M);b=m.end()+end.start() if end else len(s);old=s[m.start():b];new=fn(old);assert old!=new,name;return s[:m.start()]+new+s[b:]
texts={n:(OLD/'project'/n).read_text() for n in prior['after'] if n.endswith('.bend')}
occurrences={n:len(re.findall(r'\bKChecked\b',s)) for n,s in texts.items() if re.search(r'\bKChecked\b',s)}
updated={n:re.sub(r'\bKChecked\b','KChecking',texts[n]) for n in occurrences}
s=updated['src/check/specialize.bend']
s=change(s,'type KSpecialized is Data:\n  KSpecialized{+book: List<&2, KDef>, +error: KChecking}', 'type KChecked is Data:\n  KChecked{+term: KTerm, +typ: KTerm, +uses: List<&2,KTerm>, +error: String}\n\ntype KSpecialized is Data:\n  KSpecialized{+book: List<&2, KDef>, +error: KChecked}')
s=function(s,'specialized_error',lambda b:change(b,'case KSpecialized{book, error}:\n      ce(error)','case KSpecialized{book, KChecked{term, typ, uses, error}}:\n      error'))
s=function(s,'specialized_diagnostic',lambda b:change(b,'case KSpecialized{book, error}: DResult{ce(error), book, dg_report(error, "")}','case KSpecialized{book, KChecked{term, typ, uses, error}}: DResult{error, book, dg_report_payload(term, error, "")}'))
s=function(s,'sp_finish',lambda b:change(b,'  KSpecialized{index_remove(sp_book(st), "$kernel.max-id"), sp_checked(st)}','  +r = sp_checked(st)\n  KSpecialized{index_remove(sp_book(st), "$kernel.max-id"), KChecked{ct(r), cy(r), cs(r), ce(r)}}'))
updated['src/check/specialize.bend']=s
s=updated['src/diagnostic/trace.bend'];m=re.search(r'^def dg_report\([\s\S]*?\) -> DDiagnostic:\n  ([^\n]+)',s,re.M);assert m
oldbody=m[1];newbody=oldbody.replace('ct(r)','term').replace('ce(r)','error')
s=change(s,oldbody,'dg_report_payload(ct(r), ce(r), name)')
s+='\n@unsafe\ndef dg_report_payload(+term: KTerm, +error: String, +name: String) -> DDiagnostic:\n  '+newbody+'\n'
updated['src/diagnostic/trace.bend']=s
# Audit before writing a compiler source: advertised roots and finite producer/projectors.
api=ROOT/'selfhost/build/phase18/instance-world-build-03/equality/api.mjs';exports=re.findall(r'^  "([^"\n]+)": run_lib',api.read_text().split('export default {',1)[1],re.M)
assert not set(exports)&{'infer','check','check_definition_result','sp_checked','dg_report'}
assert set(['specialize_book','specialized_book','specialized_error','specialized_diagnostic'])<=set(exports)
host=(OLD/'project/tools/typed-driver.mjs').read_text();assert "KSpecialized:['book','error']" in host;assert 'KChecked' not in host
OUT.mkdir();project=OUT/'project';shutil.copytree(OLD/'project',project)
for n,s in updated.items():(project/n).write_text(s)
def members(root):return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777} for p in sorted(root.rglob('*')) if p.is_file()}
def census(root):
 strings=[(root/n).read_text() for n in prior['after'] if n.endswith('.bend')]
 return {'physicalLines':sum(len(s.splitlines()) for s in strings),'nonblankLines':sum(sum(bool(l.strip()) for l in s.splitlines()) for s in strings),'bytes':sum(len(s.encode()) for s in strings),'definitions':sum(len(re.findall(r'^def ',s,re.M)) for s in strings),'laws':sum(len(re.findall(r'^law ',s,re.M)) for s in strings),'types':sum(len(re.findall(r'^type ',s,re.M)) for s in strings)}
after=members(project);changes=[n for n in prior['before'] if prior['before'][n]!=after[n]]
for filename,parent,names in [('source.patch',BASE,changes),('public-boundary.patch',OLD/'project',sorted(updated))]:
 (OUT/filename).write_text(''.join(''.join(difflib.unified_diff((parent/n).read_text().splitlines(True),(project/n).read_text().splitlines(True),fromfile='a/'+n,tofile='b/'+n)) for n in names))
new=census(project);incremental={k:new[k]-prior['newSource'][k] for k in new}
manifest={**prior,'project':str(project),'after':after,'newSource':new,'delta':{k:new[k]-prior['oldSource'][k] for k in new},'incrementalDelta':incremental,'correction':'Expanded KChecking is internal; sp_finish emits historical KChecked4, diagnostic payload renderer shared.','previousSource':str(OLD),'internalRenameOccurrences':occurrences,'publicExports':exports,'publicSpecializationProducer':'sp_finish','publicProjectors':['specialized_book','specialized_error','specialized_diagnostic'],'publicConsumer':'driver_program_specialized uses only stable projections; typed host recognizes KSpecialized book/error, no KChecked decoder.','inputs':prior['inputs']+[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [Path(__file__),PLAN,api]]}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');config=json.loads((OLD/'workflow.json').read_text());config['project']=str(project);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');print(json.dumps({'delta':manifest['delta'],'incremental':incremental,'renameOccurrences':occurrences,'exports':len(exports)}))
