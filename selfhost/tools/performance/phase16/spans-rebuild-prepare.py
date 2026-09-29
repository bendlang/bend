#!/usr/bin/env python3
"""One exact common child-rebuild rewrite; no provenance instrumentation."""
from pathlib import Path
import re, json, shutil, hashlib, difflib
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'selfhost/build/phase16/spans-prepare-03/project'
OUT=ROOT/'selfhost/build/phase16/spans-rebuild-prepare-01'
OUT.mkdir();PROJECT=OUT/'project';PROJECT.mkdir()
for name in ['src','tools','tests']:shutil.copytree(BASE/name,PROJECT/name)
def identity(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
changes=[];sites=[]
for p in sorted((PROJECT/'src').rglob('*.bend')):
    before=p.read_text();edits=[]
    for m in re.finditer(r'KTerm\{tg\((\w+)\), nm\(\1\), ix\(\1\), qt\(\1\), ',before):
        owner=m[1];start=m.end();end=start;depth=0;quote=False;escape=False
        while True:
            c=before[end]
            if quote:
                if escape:escape=False
                elif c=='\\':escape=True
                elif c=='"':quote=False
            elif c=='"':quote=True
            elif c in '{[(':depth+=1
            elif c in '}])':depth-=1
            elif c==',' and depth==0:break
            end+=1
        suffix=f', rm({owner}), kb({owner}), ke({owner})}}'
        if before[end:end+len(suffix)]!=suffix:continue
        replacement=f'k_with_children({owner}, {before[start:end]})'
        edits.append((m.start(),end+len(suffix),replacement))
        sites.append({'file':p.relative_to(PROJECT).as_posix(),'line':before[:m.start()].count('\n')+1,'original':before[m.start():end+len(suffix)],'replacement':replacement})
    after=before
    for a,b,new in reversed(edits):after=after[:a]+new+after[b:]
    if after!=before:p.write_text(after);changes.append((p.relative_to(PROJECT).as_posix(),before))
assert len(sites)==15,len(sites)
p=PROJECT/'src/core/term.bend';before=p.read_text();p.write_text(before+'''
# Replace only semantic children; every other immutable field is preserved.
@unsafe
def k_with_children(+t: KTerm, +kids: List<&2,KTerm>) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, oldKids, removed, originBegin, originEnd}:
      KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}
''');changes.append((p.relative_to(PROJECT).as_posix(),before))
p=PROJECT/'tools/typed-driver.mjs';before=p.read_text();s=before
needle='  if(!module.G) return module.default;'
assert s.count(needle)==1
s=s.replace(needle,"  const spanAbi=module.default.compiler_span_abi?.();\n  if(module.default.compiler_span_abi!==undefined&&spanAbi!==3)throw Error('Unknown compiler span ABI: '+spanAbi);\n"+needle)
s=s.replace("KTerm:module.default.compiler_span_abi?.()===3?", "KTerm:spanAbi===3?")
p.write_text(s);changes.append((p.relative_to(PROJECT).as_posix(),before))
patch=[]
for rel,before in changes:patch.extend(difflib.unified_diff(before.splitlines(True),(PROJECT/rel).read_text().splitlines(True),fromfile='a/selfhost/'+rel,tofile='b/selfhost/'+rel))
(OUT/'rebuild.patch').write_text(''.join(patch))
(OUT/'workflow.json').write_text(json.dumps({'project':str(PROJECT),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'2','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n')
shutil.copy2(__file__,OUT/Path(__file__).name)
cost=lambda s:{'physicalLines':len(s.splitlines()),'nonblankLines':sum(bool(x.strip()) for x in s.splitlines()),'bytes':len(s.encode()),'definitions':len(re.findall(r'^def ',s,re.M))}
a=''.join(s for rel,s in changes if rel.startswith('src/'));b=''.join((PROJECT/rel).read_text() for rel,s in changes if rel.startswith('src/'))
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'kind':'phase16-common-child-rebuild-preparation','inputs':[identity(Path(__file__).resolve()),identity(ROOT/'experiments/phase16/P16-002B-source-rebuild.md')],'project':str(PROJECT),'changes':[{'relative':rel,'before':identity(BASE/rel),'after':identity(PROJECT/rel)} for rel,s in changes],'sites':sites,'removedProjectorCalls':len(sites)*7,'addedHelperCalls':len(sites),'cost':{k:cost(b)[k]-cost(a)[k] for k in cost(a)},'hostScope':'Reject explicitly present unknown span ABI; zero-metadata ABI3 and legacy no-ABI retained.'},indent=2)+'\n')
print(OUT)
