#!/usr/bin/env python3
"""Five exact constructor arms only. Existing runtime and all calls unchanged."""
from pathlib import Path
import hashlib,json,re,sys
source,out=map(lambda s:Path(s).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):
 b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
s=source.read_text();rows=[];lines=s.splitlines(keepends=True)
for i,line in enumerate(lines):
 m=re.match(r'G\["(cell(?:\.f[1-4])?)"\]=fn\(',line)
 if not m:continue
 matches=list(re.finditer(r'matcher1\("(Dp|Tuple)",\(\)=>fn\((\d+),function\(a\)\{',line))
 assert len(matches)==1,m.group(1)
 match=matches[0];tag,n=match.groups();n=int(n);assert n=={'Dp':4,'Tuple':2}[tag]
 old=match.group(0);new=f'matcher1p("{tag}",{n},{n},()=>(0,function(a){{'
 lines[i]=line[:match.start()]+new+line[match.end():]
 rows.append({'name':m.group(1),'old':old,'new':new})
assert len(rows)==5,rows
p=out/'exact.mjs';p.write_text(''.join(lines))
(out/'consumed-exact-arm-derive.py').write_bytes(Path(__file__).read_bytes())
save(out/'report.json',{'complete':True,'kind':'phase30-five-exact-constructor-arm-prototype','scope':'Generated-JS-only;5prefixes replaced with existingmatcher1p. Runtime, arithmetic, calls, loops, arrays andbodybytesunchanged.','inputs':[ident(source),ident(Path(__file__))],'output':ident(p),'rewrites':rows})
print(json.dumps({'complete':True,'sites':len(rows),'output':str(p)}))
