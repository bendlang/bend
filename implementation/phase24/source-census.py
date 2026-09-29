#!/usr/bin/env python3
"""Count canonical Bend modules and compare the immutable Phase23 checkpoint.
Run from repository root: python3 implementation/phase24/source-census.py NEW_OUTPUT
"""
import hashlib,json,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
BASELINE='8eb2cc01145041ce7c0dce199daaf7087038e962'
EXPECTED={'modules':60,'physicalLines':15748,'nonblankLines':13442,'bytes':586637,'defs':1700,'laws':640,'types':68}
def revision_file(name):
 return subprocess.check_output(['git','-C',str(ROOT),'show',BASELINE+':selfhost/'+name])
def census(read):
 manifest=read('src/compiler.json'); modules=json.loads(manifest)['modules'];assert len(modules)==len(set(modules))
 rows=[]
 for name in modules:
  raw=read(name);text=raw.decode('utf8');lines=text.splitlines()
  rows.append({'file':name,'sha256':hashlib.sha256(raw).hexdigest(),'physicalLines':len(lines),'nonblankLines':sum(bool(line.strip()) for line in lines),'bytes':len(raw),'defs':len(re.findall(r'^def\s+',text,re.M)),'laws':len(re.findall(r'^law\s+',text,re.M)),'types':len(re.findall(r'^type\s+',text,re.M))})
 total={'modules':len(rows),**{key:sum(row[key] for row in rows) for key in ['physicalLines','nonblankLines','bytes','defs','laws','types']}}
 return {'totals':total,'manifestSha256':hashlib.sha256(manifest).hexdigest(),'files':rows}
baseline=census(revision_file);assert baseline['totals']==EXPECTED,(baseline['totals'],EXPECTED)
current=census(lambda name:(ROOT/'selfhost'/name).read_bytes())
old={x['file']:x for x in baseline['files']};new={x['file']:x for x in current['files']}
report={'kind':'phase24-canonical-bend-source-census','complete':True,'baselineCommit':BASELINE,'method':{'membership':'Exactly src/compiler.json modules, each once; excludes host/runtime JavaScript/C, generated code, tooling, tests and documentation.','physicalLines':'len(UTF-8 decoded text.splitlines()); blank/comment lines included.','nonblankLines':'Count split lines with nonempty str.strip().','bytes':'Raw UTF-8 file bytes, including line terminators.','declarations':'Anchored multiline regex ^def\\s+, ^law\\s+, ^type\\s+; counts declaration heads, not constructors, signatures or semantic concepts.','reproduce':'python3 implementation/phase24/source-census.py NEW_OUTPUT','scriptSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},'baseline':baseline,'current':current,'delta':{key:current['totals'][key]-baseline['totals'][key] for key in EXPECTED},'percentDelta':{key:(current['totals'][key]/baseline['totals'][key]-1)*100 for key in EXPECTED},'changedModules':[name for name in sorted(set(old)|set(new)) if old.get(name,{}).get('sha256')!=new.get(name,{}).get('sha256')],'scope':'A reproducible size census of canonical compiler Bend modules; declaration counts are not a proof of conceptual simplicity or a count of all implementation code.'}
out=Path(sys.argv[1]);out=out if out.is_absolute() else ROOT/out
with out.open('x') as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'current':current['totals'],'delta':report['delta'],'output':str(out)}))
