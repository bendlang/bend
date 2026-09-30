#!/usr/bin/env python3
"""Retain exact Phase 30 worker and derive diagnostic instrumentation only."""
import difflib
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[3]
out = pathlib.Path(sys.argv[1]).resolve()
out.mkdir()

def identity(p):
    p = pathlib.Path(p).resolve()
    data = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))

old_path = root / 'tools/performance/phase30/inspect-generated-compiler-cost-worker.mjs'
original = old_path.read_text()
worker = original
changes = []

def change(old, new):
    global worker
    assert worker.count(old) == 1, (old, worker.count(old))
    worker = worker.replace(old, new)
    changes.append(dict(old=old, new=new, occurrences=1))

change("const report={kind:'phase30-generated-compiler-small-worker'", "const report={kind:'phase31-generated-compiler-attribution-worker'")
change("const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\\n');save();", """const traceEvents=[];report.traceEvents=traceEvents;
const event=(kind,data={})=>traceEvents.push({ms:performance.now(),kind,...data});
const originalWrite=process.stderr.write;
process.stderr.write=function(chunk,...args){
 const text=typeof chunk==='string'?chunk:Buffer.from(chunk).toString();
 event('stderr',{text});return Reflect.apply(originalWrite,this,[chunk,...args]);
};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\\n');save();""")
change("BEND_TYPED_TRACE:''", "BEND_TYPED_TRACE:'1'")
change("const imported=performance.now(),D=await import(pathToFileURL(p.driver.file)),api=await D.loadApi();", "const imported=performance.now(),D=await import(pathToFileURL(p.driver.file));let api=await D.loadApi();")
change("const location=createHash('sha256')", """const originalApi=api;
 api=Object.fromEntries(Object.entries(originalApi).map(([name,method])=>[name,function(...args){
  event('api-enter',{name});
  try{return Reflect.apply(method,this===api?originalApi:this,args)}finally{event('api-leave',{name})}
 }]));
 const location=createHash('sha256')""")
change("const prepareStart=performance.now(),cache=await D.prepareBase(api);", "event('prepare-start');const prepareStart=performance.now(),cache=await D.prepareBase(api);event('prepare-end');")
change("const start=performance.now(),result=await D.inspect(p.source.file,{mode:'library',api}),elapsedMs=performance.now()-start;", "event('request-start',{index:i});const start=performance.now(),result=await D.inspect(p.source.file,{mode:'library',api}),elapsedMs=performance.now()-start;event('request-end',{index:i});")
change("report.requests.push({kind:r.mode==='prepare'?'preparation':i===0?'warm':'timed',elapsedMs,outputSha256:digest});", "report.requests.push({kind:r.mode==='prepare'?'preparation':i===0?'warm':'diagnostic',elapsedMs,outputSha256:digest});")
change("const values=report.requests.filter(x=>x.kind==='timed')", "const values=report.requests.filter(x=>x.kind==='diagnostic')")

(out/'original-worker.mjs').write_text(original)
(out/'worker.mjs').write_text(worker)
(out/'worker.patch').write_text(''.join(difflib.unified_diff(original.splitlines(True), worker.splitlines(True), fromfile='phase30-worker.mjs', tofile='phase31-worker.mjs')))
(out/'consumed-derive.py').write_bytes(pathlib.Path(__file__).read_bytes())
source_plan = root/'build/phase30/generated-compiler-cost-plan17/plan.json'
prepared_path = root/'build/phase30/generated-compiler-cost-prepare17/report.json'
plan = json.loads(source_plan.read_text())
prepared = json.loads(prepared_path.read_text())
assert prepared['pass'] and prepared['complete']
assert prepared['plan']['sha256'] == identity(source_plan)['sha256']
plan['kind'] = 'phase31-generated-compiler-attribution-plan'
plan['scope'] = 'Instrumented CPU2 attribution; overlapping correctness work permitted. No clean timing ratio or steady-state claim.'
plan['originalPlan'] = identity(source_plan)
plan['prepared'] = identity(prepared_path)
plan['design'] = identity(root.parent/'design/phase31/h-attribution.md')
plan['cpu'] = '2'
plan['worker'] = identity(out/'worker.mjs')
plan['inputs'] += [plan['originalPlan'], plan['prepared'], plan['design'], plan['worker'], identity(__file__)]
for row in prepared['rows']:
    plan['inputs'] += [row['resultIdentity'], row['observation']['cache']['after']]
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
receipt = dict(kind='phase31-attribution-derivation', complete=True,
               original=identity(old_path), derivative=identity(out/'worker.mjs'),
               patch=identity(out/'worker.patch'), changes=changes)
# Compare content separately from the saved copies' differing paths.
receipt['originalUnchanged'] = old_path.read_bytes() == (out/'original-worker.mjs').read_bytes()
receipt['pass'] = receipt['originalUnchanged']
(out/'derivation.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'plan':str(out/'plan.json'),'replacements':len(changes)}))
