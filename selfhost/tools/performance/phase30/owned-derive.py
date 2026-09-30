#!/usr/bin/env python3
"""Derive a non-tail fresh-argument-vector prototype; never a compiler image."""
from pathlib import Path
import hashlib,json,sys

def ident(p):
 p=Path(p).resolve(); b=p.read_bytes()
 return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
def replacements(s):
 # Tokenize only the generated program suffix. Strings/comments are opaque.
 result=[];i=0
 while i<len(s):
  if s[i] in '\"\'`':
   q=s[i];i+=1
   while i<len(s):
    if s[i]=='\\':i+=2
    elif s[i]==q:i+=1;break
    else:i+=1
   continue
  if s.startswith('//',i):
   e=s.find('\n',i+2);i=len(s) if e<0 else e+1;continue
  if s.startswith('/*',i):
   e=s.find('*/',i+2);assert e>=0;i=e+2;continue
  if s[i].isalpha() or s[i] in '_$':
   end=i+1
   while end<len(s) and (s[end].isalnum() or s[end] in '_$'):end+=1
   if s[i:end]=='call' and s[end:end+1]=='(' and not s[:i].rstrip().endswith('.'):
    j=end+1;depth=0;q=None
    while j<len(s):
     c=s[j]
     if q:
      if c=='\\':j+=2;continue
      if c==q:q=None
     elif c in '\"\'`':q=c
     elif s.startswith('/*',j):
      e=s.find('*/',j+2);assert e>=0;j=e+2;continue
     elif c in '([{':depth+=1
     elif c in ')]}':
      if depth==0:break
      depth-=1
     elif c==',' and depth==0:
      if s[j+1:].lstrip().startswith('['):result.append(i)
      break
     j+=1
   i=end;continue
  i+=1
 return result

source,out=map(lambda s:Path(s).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
root=Path(__file__).resolve().parents[4];runtime=root/'selfhost/src/runtime.mjs'
b=source.read_text();rt=runtime.read_text();assert b.startswith(rt),'runtime mismatch'
report={'kind':'phase30-owned-nontail-argument-prototype','complete':False,'inputs':[ident(p) for p in [source,runtime,Path(__file__)]], 'scope':'Only generated non-tail call sites with fresh literal vectors; public call, tail jumps, matcher vectors, bound concatenation and oversaturation slices unchanged. Runtime apply adds explicit ownership flag.'}
save(out/'report.json',report)
(out/'consumed-owned-derive.py').write_bytes(Path(__file__).read_bytes())
old='function apply(f,args){';new='function apply(f,args,owned=false){'
assert rt.count(old)==1;rt=rt.replace(old,new)
old='const all=f.bound.length?f.bound.concat(args):args.slice();';new='const all=f.bound.length?f.bound.concat(args):owned?args:args.slice();'
assert rt.count(old)==1;rt=rt.replace(old,new)
rt+='\nconst callOwned=(f,args)=>force(apply(f,args,true));\n'
program=b[len(runtime.read_text()):];positions=replacements(program)
assert positions,'no eligible calls'
for p in reversed(positions):program=program[:p]+'callOwned'+program[p+4:]
(out/'unchanged.mjs').write_text(b);(out/'owned.mjs').write_text(rt+program)
report.update(complete=True,sites=len(positions),offsets=positions,outputs={k:ident(out/(k+'.mjs')) for k in ['unchanged','owned']})
save(out/'report.json',report);print(json.dumps({'complete':True,'sites':len(positions),'out':str(out)}))
