#!/usr/bin/env python3
"""Apply the reviewed zero-metadata layout/helper to a frozen combined project.

This also supplies two pure range constructors for subsequent owned overlays.
It does not collect or resolve source ranges.
"""
from pathlib import Path
import sys,re,json,shutil,hashlib,difflib
ROOT=Path(__file__).resolve().parents[4]
SOURCE=Path(sys.argv[1]).resolve();OUT=Path(sys.argv[2]).resolve()
OUT.mkdir();PROJECT=OUT/'project';PROJECT.mkdir()
for name in ['src','tools','tests']:shutil.copytree(SOURCE/name,PROJECT/name)
def identity(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def records(text):
    for m in re.finditer(r'KTerm\{',text):
        a=m.end();at=a;depth=1;quote=False;escape=False;separators=[]
        while depth:
            c=text[at]
            if quote:
                if escape:escape=False
                elif c=='\\':escape=True
                elif c=='"':quote=False
            elif c=='"':quote=True
            elif c in '{[(':depth+=1
            elif c in '}])':depth-=1
            elif c==',' and depth==1:separators.append(at)
            at+=1
        points=[a-1,*separators,at-1]
        yield m.start(),at,[text[points[i]+1:points[i+1]].strip() for i in range(len(points)-1)]
changes=[];sites=[];rebuilds=[]
for p in sorted((PROJECT/'src').rglob('*.bend')):
    before=p.read_text();edits=[]
    for a,b,args in records(before):
        assert len(args)==6 or args[0].startswith('+tag:'),(p,args)
        if args[0].startswith('+tag:'):extra='+originBegin: U32, +originEnd: U32'
        elif args[5]=='Nil{}':extra='0, 0'
        elif args[5]=='removed':extra='originBegin, originEnd'
        else:
            owner=re.search(r'rm\((\w+)\)',args[5]) or re.fullmatch(r'tg\((\w+)\)',args[0])
            assert owner,(p,args)
            extra=f'kb({owner[1]}), ke({owner[1]})'
        replacement=before[a:b-1]+', '+extra+'}'
        owner=re.fullmatch(r'tg\((\w+)\)',args[0])
        if owner and args[1:4]==[f'nm({owner[1]})',f'ix({owner[1]})',f'qt({owner[1]})'] and args[5]==f'rm({owner[1]})':
            replacement=f'k_with_children({owner[1]}, {args[4]})'
            rebuilds.append({'file':p.relative_to(PROJECT).as_posix(),'line':before[:a].count('\n')+1})
        edits.append((a,b,replacement));sites.append({'file':p.relative_to(PROJECT).as_posix(),'line':before[:a].count('\n')+1})
    after=before
    for a,b,new in reversed(edits):after=after[:a]+new+after[b:]
    if after!=before:p.write_text(after);changes.append((p.relative_to(PROJECT).as_posix(),before))

p=PROJECT/'src/core/term.bend'
helper_source=(ROOT/'selfhost/build/phase16/spans-rebuild-prepare-01/project/src/core/term.bend').read_text()
helpers=helper_source[helper_source.index('# Source ranges are non-semantic metadata.'):]
p.write_text(p.read_text()+'\n'+helpers+'''
# Explicit replacement does not guess or inherit an occurrence.
@unsafe
def k_with_span(+t: KTerm, +begin: U32, +end: U32) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, oldBegin, oldEnd}:
      KTerm{tag, name, id, quant, kids, removed, begin, end}

@unsafe
def kt_span(+tag: String, +name: String, +id: U32, +quant: U32,
  +kids: List<&2,KTerm>, +begin: U32, +end: U32) -> KTerm:
  KTerm{tag, name, id, quant, kids, Nil{}, begin, end}
''')
p=PROJECT/'tools/typed-driver.mjs';before=p.read_text();s=before
s=s.replace('const exports=[...roots];',"const exports=[...roots];\n  if(fs.readFileSync(path.join(project,'src/core/term.bend'),'utf8').includes('def compiler_span_abi('))exports.push('compiler_span_abi');")
s=s.replace('  if(!module.G) return module.default;',"  const spanAbi=module.default.compiler_span_abi?.();\n  if(module.default.compiler_span_abi!==undefined&&spanAbi!==3)throw Error('Unknown compiler span ABI: '+spanAbi);\n  if(!module.G) return module.default;")
s=s.replace("KTerm:['tag','name','id','quant','kids','removed']", "KTerm:spanAbi===3?['tag','name','id','quant','kids','removed','originBegin','originEnd']:['tag','name','id','quant','kids','removed']")
s=s.replace('kids:list(kids),removed:list([])}','kids:list(kids),removed:list([]),originBegin:0,originEnd:0}')
s=s.replace('kids:parsed.parts,removed:list([])}','kids:parsed.parts,removed:list([]),originBegin:0,originEnd:0}')
assert s!=before and s.count('originBegin')==3
p.write_text(s);changes.append((p.relative_to(PROJECT).as_posix(),before))
patch=[]
for rel,before in changes:patch.extend(difflib.unified_diff(before.splitlines(True),(PROJECT/rel).read_text().splitlines(True),fromfile='a/selfhost/'+rel,tofile='b/selfhost/'+rel))
(OUT/'migration.patch').write_text(''.join(patch));shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'kind':'phase16-frozen-combined-source-span-migration','baseline':str(SOURCE),'project':str(PROJECT),'inputs':[identity(Path(__file__).resolve()),identity(ROOT/'selfhost/build/phase16/spans-rebuild-prepare-01/project/src/core/term.bend')],'changes':[{'relative':rel,'before':identity(SOURCE/rel),'after':identity(PROJECT/rel)} for rel,s in changes],'recordSites':sites,'commonRebuilds':rebuilds,'scope':'Reviewed eight-field layout and common child rebuild, plus pure explicit span constructors; no source collection or lookup yet.'},indent=2)+'\n')
print(PROJECT)
