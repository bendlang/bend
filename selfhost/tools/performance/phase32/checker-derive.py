#!/usr/bin/env python3
"""Append isolated private copies; never change H17's original public program."""
import argparse, hashlib, json, re
from pathlib import Path

def sha(b): return hashlib.sha256(b).hexdigest()
def identity(p):
 p=Path(p).resolve(); b=p.read_bytes(); return dict(file=str(p),sha256=sha(b),bytes=len(b))
def end_call(s,start):
 # The prefix ends immediately before the literal argument vector. Scan exact
 # emitted JavaScript strings/comments, balancing all bracket kinds.
 pairs={'(':')','[':']','{':'}'}; stack=[];i=start;quote=None
 while i<len(s):
  c=s[i]
  if quote:
   if c=='\\': i+=2;continue
   if c==quote:quote=None
   i+=1;continue
  if c in '\"\'`':quote=c;i+=1;continue
  if s.startswith('/*',i):
   j=s.find('*/',i+2);assert j>=0;i=j+2;continue
  if c in pairs:stack.append(pairs[c])
  elif c in ')]}':
   assert stack and stack.pop()==c
   if not stack:return i+1
  i+=1
 raise AssertionError('unclosed vector')

ap=argparse.ArgumentParser();ap.add_argument('out');args=ap.parse_args()
root=Path.cwd();out=Path(args.out).resolve();out.mkdir(parents=True,exist_ok=False)
h=root/'selfhost/build/phase30/self-emission-correspondence17/compiler.mjs'
raw=h.read_bytes();assert sha(raw)=='a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5'
s=raw.decode();lines=s.splitlines()
definitions={}
for l in lines:
 m=re.fullmatch(r'G\["([^"\n]+)"\]=(.*);',l)
 if m:
  assert m[1] not in definitions;definitions[m[1]]=m[2]
lookup=['lookup','lookup_cached','lookup_named','index_lookup','index_find','index_find_absent','index_find_leaf','index_find_hash','index_child','index_child_list','index_first','index_bucket','index_hash']
second=['infer_ref']
selected=lookup+second
projections={}
for n,body in definitions.items():
 m=re.fullmatch(r'fn\(1,(function\(a\)\{return project\("([^"\n]+)",a\[0\]\)\.slice\(\)\[(\d+)\];\})\)',body)
 if m:projections[n]=dict(code=m[1],constructor=m[2],field=int(m[3]))
# Only KDef and the second helper's direct KEnv fields are part of this ablation.
projections={n:p for n,p in projections.items() if p['constructor'] in ['KDef','KEnv','KChecking','KWorld']}
changed=[];used=set();private={}
for name in selected:
 source=definitions[name]
 # Copy recursion, but do not change dependencies outside this bounded group.
 for target in selected:source=source.replace('get(G,'+json.dumps(target)+')','get($CheckerG,'+json.dumps(target)+')')
 before=source;count={}
 for pn,proof in projections.items():
  prefix='callOwned(get(G,'+json.dumps(pn)+'),'
  start=source.find(prefix)
  while start>=0:
   astart=start+len(prefix); assert source[astart]=='['
   aend=end_call(source,astart);assert source[aend]==')'
   expr=source[astart:aend]
   replacement='force($Checker_'+pn+'('+expr+'))'
   source=source[:start]+replacement+source[aend+1:]
   count[pn]=count.get(pn,0)+1;used.add(pn)
   start=source.find(prefix,start+len(replacement))
 private[name]=(before,source)
 changed.append(dict(name=name,replacements=count,before=before,after=source))
assert sum(sum(x['replacements'].values()) for x in changed)>0
variants={}
for role,pos in [('baseline',0),('direct',1),('fields',0),('combined',1),('captured',0)]:
 suffix='\n// Phase32 diagnostic-only trusted private entries; original module is unchanged.\nconst $CheckerG=Object.create(G);\n'
 for n in sorted(used):
  proof=projections[n]
  code=proof['code'] if role in ['baseline','direct','captured'] else 'function(a){return a[0].a['+str(proof['field'])+'];}'
  suffix+='const $Checker_'+n+'='+code+';\n'
  if role in ['fields','captured']:suffix+='$CheckerG['+json.dumps(n)+']=fn(1,$Checker_'+n+');\n'
 for n in selected:
  body=private[n][pos]
  if role in ['fields','captured']:
   for pn in sorted(used):body=body.replace('get(G,'+json.dumps(pn)+')','get($CheckerG,'+json.dumps(pn)+')')
  suffix+='$CheckerG['+json.dumps(n)+']='+body+';\n'
 suffix+='export const checkerProbe=Object.freeze({lookup:(book,name)=>call(get($CheckerG,"lookup"),[book,name]),infer_ref:(...args)=>call(get($CheckerG,"infer_ref"),args)});\n'
 target=out/(role+'.mjs');target.write_bytes(raw+suffix.encode());assert target.read_bytes()[:len(raw)]==raw
 variants[role]=identity(target);variants[role]['originalPrefixBytes']=len(raw);variants[role]['originalPrefixSha256']=sha(raw)
manifest=dict(kind='phase32-checker-projection-direct-derivation',complete=True,**{'pass':True},scope='Private immutable harness graphs only; all original public program bytes unchanged; no production admission',inputs=[identity(h),identity(__file__),identity(root/'design/phase32/checker-direct-calls.md'),identity(root/'design/phase32/checker-private-fields.md'),identity(root/'design/phase32/checker-matched-projections.md')],variants=variants,selected=selected,projections={n:projections[n] for n in sorted(used)},changes=changed)
(out/'derive.json').write_text(json.dumps(manifest,indent=2)+'\n')
(out/'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps(dict(complete=True,**{'pass':True},definitions=len(selected),projections=len(used),replacements=sum(sum(x['replacements'].values()) for x in changed))))
