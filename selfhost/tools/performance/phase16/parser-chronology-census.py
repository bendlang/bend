#!/usr/bin/env python3
from pathlib import Path
import re,json,hashlib
root=Path(__file__).resolve().parents[4];base=root/'selfhost/build/phase16/wave7-source-01/project/src/front';out=root/'selfhost/build/phase16/parser-chronology-census-01.json';assert not out.exists();defs={};inputs=[]
for p in sorted(base.glob('*.bend')):
 inputs.append({'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});s=p.read_text();starts=list(re.finditer(r'^def ([A-Za-z0-9_]+)\(',s,re.M))
 for i,m in enumerate(starts):
  end=starts[i+1].start()if i+1<len(starts)else len(s);defs[m.group(1)]={'file':p.name,'line':s.count('\n',0,m.start())+1,'calls':sorted(set(re.findall(r'\b(f_[A-Za-z0-9_]+)\(',s[m.start():end]))-{m.group(1)})}
seeds={'f_let_value','f_case_pats','f_lambda_valid'};seen=set(seeds)
while True:
 add={n for n,d in defs.items()if set(d['calls'])&seen}-seen
 if not add:break
 seen|=add
counts={}
for n in seen:
 if n in defs:counts[defs[n]['file']]=counts.get(defs[n]['file'],0)+1
out.write_text(json.dumps({'kind':'read-only-static-parser-caller-census','complete':True,'method':'Lexical function/call extraction and transitive caller closure, a conservative upper bound; no compiler execution or implementation-size claim.','seeds':sorted(seeds),'callerFunctions':len(seen),'byFile':counts,'functions':{n:defs[n]for n in sorted(seen)if n in defs},'inputs':inputs,'tool':{'file':str(Path(__file__)),'sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}},indent=2)+'\n');print(out)
