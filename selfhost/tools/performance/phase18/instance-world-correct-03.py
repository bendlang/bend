"""Preserve result metadata through completed-check failures and successful rebuilds."""
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4];OLD=ROOT/'selfhost/build/phase18/instance-world-source-02';OUT=ROOT/'selfhost/build/phase18/instance-world-source-03'
prior=json.loads((OLD/'manifest.json').read_text());BASE=Path(prior['parent']);OUT.mkdir();project=OUT/'project';shutil.copytree(OLD/'project',project)
def change(s,a,b,n=1):assert s.count(a)==n,(a,s.count(a));return s.replace(a,b)
def function(s,name,fn):
 m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
 end=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M);b=m.end()+end.start() if end else len(s);old=s[m.start():b];new=fn(old);assert old!=new,name;return s[:m.start()]+new+s[b:]
def wrap_calls(s,target,r):
 positions=list(re.finditer(r'\b'+target+r'\(',s));assert positions,target
 for m in reversed(positions):
  depth=1;quote=False;escape=False;i=m.end()
  while depth:
   c=s[i]
   if quote:
    if escape:escape=False
    elif c=='\\':escape=True
    elif c=='"':quote=False
   elif c=='"':quote=True
   elif c=='(':depth+=1
   elif c==')':depth-=1
   i+=1
  s=s[:m.start()]+'kr_from('+r+', '+s[m.start():i]+')'+s[i:]
 return s
p=project/'src/check/kernel.bend';s=p.read_text()
for name in ['infer_app_type','check_rwt_type']:
 s=function(s,name,lambda b:wrap_calls(change(b,'dg_bad_detail(cw(e),','dg_bad_detail(rw(r),'),'dg_bad_detail','r'))
s=function(s,'check_fits',lambda b:wrap_calls(b,'dg_bad_detail','r'))
s=function(s,'check_rwt_goal',lambda b:wrap_calls(b,'dg_bad_detail','motive'))
s=function(s,'check_lam_done',lambda b:change(wrap_calls(b,'dg_quant_error','r'),'ok(rw(r), t, ty, uses_del(cs(r), ix(t)))','KChecked{t, ty, uses_del(cs(r), ix(t)), "", rw(r), rx(r)}'))
s=function(s,'check_let_done',lambda b:change(change(wrap_calls(b,'dg_quant_error','r'),'ok(rw(r), ct(r), cy(r), uses_merge(us, cs(r), False{}))','KChecked{ct(r), cy(r), uses_merge(us, cs(r), False{}), "", rw(r), rx(r)}'),'ok(rw(r), ct(r), cy(r), uses_del(cs(r), ix(h)))','KChecked{ct(r), cy(r), uses_del(cs(r), ix(h)), "", rw(r), rx(r)}'))
s+='''
# A translated failure retains the completed check's actual world and transport.
@unsafe
def kr_from(+origin: KChecked, +derived: KChecked) -> KChecked:
  KChecked{ct(derived), cy(derived), cs(derived), ce(derived), rw(origin), rx(origin)}
''';p.write_text(s)
p=project/'src/diagnostic/trace.bend';s=p.read_text();s=function(s,'dg_template_result',lambda b:wrap_calls(b,'dg_bad_detail','r'));p.write_text(s)
def members(root):return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777} for p in sorted(root.rglob('*')) if p.is_file()}
after=members(project);changes=[n for n in prior['before'] if prior['before'][n]!=after[n]]
(OUT/'source.patch').write_text(''.join(''.join(difflib.unified_diff((BASE/n).read_text().splitlines(True),(project/n).read_text().splitlines(True),fromfile='a/'+n,tofile='b/'+n)) for n in changes))
strings=[(project/n).read_text() for n in after if n.endswith('.bend')]
new={'physicalLines':sum(len(s.splitlines()) for s in strings),'nonblankLines':sum(sum(bool(l.strip()) for l in s.splitlines()) for s in strings),'bytes':sum(len(s.encode()) for s in strings),'definitions':sum(len(re.findall(r'^def ',s,re.M)) for s in strings),'laws':sum(len(re.findall(r'^law ',s,re.M)) for s in strings),'types':sum(len(re.findall(r'^type ',s,re.M)) for s in strings)}
manifest={**prior,'project':str(project),'after':after,'newSource':new,'delta':{k:new[k]-prior['oldSource'][k] for k in new},'correction':'Independent review: derived failures keep completed world/count; successful lambda/let rebuilds keep count. Error-only kr_from helper.','previousSource':str(OLD),'inputs':prior['inputs']+[{'file':str(Path(__file__)),'sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}]}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');config=json.loads((OLD/'workflow.json').read_text());config['project']=str(project);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');print(json.dumps(manifest['delta']))
