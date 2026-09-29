#!/usr/bin/env python3
"""Prepare the zero-origin metadata ablation from the immutable Phase15 image."""
from pathlib import Path
import difflib, hashlib, json, re, shutil

ROOT = Path(__file__).resolve().parents[4]
BASE = ROOT / 'selfhost/build/phase15/combined-02/snapshot'
OUT = ROOT / 'selfhost/build/phase16/spans-prepare-03'
OUT.mkdir()
PROJECT = OUT / 'project'
PROJECT.mkdir()
for name in ['src', 'tools', 'tests']:
    shutil.copytree(BASE / name, PROJECT / name)

def identity(p):
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

changes = []
sites = 0
for p in sorted((PROJECT / 'src').rglob('*.bend')):
    before = p.read_text()
    if 'KTerm{' not in before:
        continue
    # Find top-level arguments while respecting nested constructors and strings.
    chunks, at = [], 0
    for match in re.finditer(r'KTerm\{', before):
        start = match.end()
        depth = 1
        quote = False
        escaped = False
        separators = []
        end = start
        while depth:
            c = before[end]
            if quote:
                if escaped: escaped = False
                elif c == '\\': escaped = True
                elif c == '"': quote = False
            elif c == '"': quote = True
            elif c in '{[(': depth += 1
            elif c in '}])': depth -= 1
            elif c == ',' and depth == 1: separators.append(end)
            end += 1
        points = [start - 1, *separators, end - 1]
        args = [before[points[i]+1:points[i+1]].strip() for i in range(len(points)-1)]
        assert len(args) == 6 or args[0].startswith('+tag:'), (p, args)
        if args[0].startswith('+tag:'):
            extra = '+originBegin: U32, +originEnd: U32'
        elif args[5] == 'Nil{}':
            extra = '0, 0'
        elif args[5] == 'removed':
            extra = 'originBegin, originEnd'
        else:
            owner = re.search(r'rm\((\w+)\)', args[5]) or re.fullmatch(r'tg\((\w+)\)', args[0])
            assert owner, (p, args)
            extra = f'kb({owner[1]}), ke({owner[1]})'
        chunks.extend([before[at:end-1], ', ' + extra])
        at = end-1
        sites += 1
    chunks.append(before[at:])
    after = ''.join(chunks)
    p.write_text(after)
    changes.append((p.relative_to(PROJECT).as_posix(), before))
assert sites == 40, sites

p = PROJECT / 'src/core/term.bend'
p.write_text(p.read_text() + '''
# Source ranges are non-semantic metadata. Zero/zero is absent; positive
# inclusive-start/exclusive-end coordinates belong to one source interval.
@unsafe
def kb(+t: KTerm) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      originBegin

@unsafe
def ke(+t: KTerm) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      originEnd

@unsafe
def compiler_span_abi() -> U32:
  3
''')

p = PROJECT / 'tools/typed-driver.mjs'
before = p.read_text()
after = before.replace("const exports=[...roots];", "const exports=[...roots];\n  if(fs.readFileSync(path.join(project,'src/core/term.bend'),'utf8').includes('def compiler_span_abi('))exports.push('compiler_span_abi');")
after = after.replace("KTerm:['tag','name','id','quant','kids','removed']", "KTerm:module.default.compiler_span_abi?.()===3?['tag','name','id','quant','kids','removed','originBegin','originEnd']:['tag','name','id','quant','kids','removed']")
after = after.replace("kids:list(kids),removed:list([])}", "kids:list(kids),removed:list([]),originBegin:0,originEnd:0}")
after = after.replace("kids:parsed.parts,removed:list([])}", "kids:parsed.parts,removed:list([]),originBegin:0,originEnd:0}")
assert before != after and after.count('originBegin') == 3
p.write_text(after)
changes.append((p.relative_to(PROJECT).as_posix(), before))

patch = []
for relative, before in changes:
    after = (PROJECT / relative).read_text()
    patch.extend(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='a/selfhost/'+relative, tofile='b/selfhost/'+relative))
(OUT / 'metadata.patch').write_text(''.join(patch))
config = {'project': str(PROJECT), 'upstream': str(ROOT/'selfhost/.bootstrap/upstream-phase8'), 'cpu': '2', 'jobs': 1, 'profile': 'equality', 'timeoutMs': 30000}
(OUT / 'workflow.json').write_text(json.dumps(config, indent=2)+'\n')
shutil.copy2(__file__, OUT / Path(__file__).name)
cost = lambda s: {'physicalLines': len(s.splitlines()), 'nonblankLines': sum(bool(x.strip()) for x in s.splitlines()), 'bytes':len(s.encode()), 'definitions':len(re.findall(r'^def ',s,re.M)), 'laws':len(re.findall(r'^law ',s,re.M)), 'types':len(re.findall(r'^type ',s,re.M))}
before = ''.join(s for rel,s in changes if rel.startswith('src/'))
after = ''.join((PROJECT/rel).read_text() for rel,s in changes if rel.startswith('src/'))
manifest = {'kind':'phase16-source-span-zero-metadata-preparation', 'complete':True, 'baseline':str(BASE), 'project':str(PROJECT), 'directRecordSites':sites,
    'inputs':[identity(Path(__file__).resolve()),identity(ROOT/'design/phase16/source-spans.md'),identity(ROOT/'experiments/phase16/P16-002-source-spans.md')],
    'changes':[{'relative':rel,'before':identity(BASE/rel),'after':identity(PROJECT/rel)} for rel,s in changes],
    'patch':identity(OUT/'metadata.patch'),'config':identity(OUT/'workflow.json'),
    'cost':{k:cost(after)[k]-cost(before)[k] for k in cost(before)},
    'scope':'Eight-field KTerm, origins zero; no parser instrumentation or diagnostic changes. Maintained v5 and runtime unchanged.'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(OUT)
