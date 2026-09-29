#!/usr/bin/env python3
"""Prepare a parser-rendering-only candidate and freeze controls before execution."""
import pathlib,json,shutil,hashlib,difflib,re
ROOT=pathlib.Path(__file__).resolve().parents[4]
OUT=ROOT/'selfhost/build/phase15/carets-prepare-01'
OUT.mkdir(); project=OUT/'project';project.mkdir()
original=ROOT/'selfhost/build/phase14/combined-01/snapshot'
for name in ['src','tools','tests']:shutil.copytree(original/name,project/name)
p=project/'src/front/parser.bend';s=p.read_text();before=s
s=s.replace('  for +column: U32\n  for +error: KTerm','  for +column: U32\n  for +offset: U32\n  for +error: KTerm',1)
s=s.replace('law fpe_here:\n  for +source: String\n  for +rest: String','law fpe_here:\n  for +source: String\n  for +rest: String\n  for +offset: U32',1)
s=s.replace('law fpe_message:\n  for +source: String','law fpe_message:\n  for +source: String\n  for +offset: U32',1)
a=s.index('law fpe_snippet:');b=s.index('@unsafe\ndef fpe_error(',a);s=s[:a]+s[b:]
s=s.replace('fpe_seek(source, source, 1, 0, error)','fpe_seek(source, source, 1, 0, 0, error)')
s=s.replace('def fpe_seek(source, rest, line, column, error):','def fpe_seek(source, rest, line, column, offset, error):')
s=s.replace('fpe_here(source, rest, error)','fpe_here(source, rest, offset, error)')
s=s.replace('fpe_seek(source, f_tail(rest), U32.add(line, 1), 0, error)','fpe_seek(source, f_tail(rest), U32.add(line, 1), 0, U32.add(offset, 1), error)')
s=s.replace('fpe_seek(source, f_tail(rest), line, U32.add(column, 1), error)','fpe_seek(source, f_tail(rest), line, U32.add(column, 1), U32.add(offset, dg_units(f_head(rest))), error)')
s=s.replace('fpe_message(source, error,','fpe_message(source, offset, error,')
s=s.replace('fpe_snippet(String.lines(source), ix(error))','dg_snippet(DSpan{source, offset, offset})')
a=s.index('@unsafe\ndef fpe_lines_count(');b=s.index('# The pinned parser tests constructor freshness',a);s=s[:a]+s[b:]
assert s!=before and 'fpe_snippet' not in s and s.count('def fpe_seek(')==1
p.write_text(s);(OUT/'before-parser.bend').write_text(before)
(OUT/'parser.patch').write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='a/selfhost/src/front/parser.bend',tofile='b/selfhost/src/front/parser.bend')))
config={'project':str(project),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'1','jobs':1,'profile':'equality','timeoutMs':30000}
(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
baseline=json.loads((ROOT/'selfhost/build/phase14/frontend-audit-02/candidate.json').read_text())
reference=json.loads((ROOT/'selfhost/build/phase8/reference-frontend-01/reference.json').read_text())
refs={(r['id'],r['lane']):r for r in reference['results']}
strip=lambda t:re.sub(r'\n[ \t]*\|[ \t]*\^+[ \t]*(?=\n|$)','',t or '')
family=[]
for row in baseline['results']:
 r=refs[row['id'],row['lane']];a=row['result'];b=r['result']
 if a.get('phase')=='parse' and a.get('diagnostic')!=b.get('diagnostic') and a.get('diagnostic')==strip(b.get('diagnostic')):
  family.append({'id':row['id'],'lanes':[row['lane']]})
assert len(family)==132 and len({r['id'] for r in family})==66
(OUT/'family-selection.json').write_text(json.dumps({'cases':family},indent=2)+'\n')
controls=[
 ('positive-empty',''),('positive-simple','def main() -> U32:\n  0\n'),
 ('body-symbol','def main() -> U32:\n  !\n'),('tab-symbol','def main() -> U32:\n\t!\n'),
 ('two-tabs','def main() -> U32:\n\t\t!\n'),('eof','def main() -> U32:\n  ('),
 ('eof-newline','def main() -> U32:\n  (\n'),('blank-lines','\n\ndef main() -> U32:\n\n  !\n\n'),
 ('multidigit-lines','\n'*9+'def main() -> U32:\n  !\n'),
 ('unicode-prior-line','# 😀 Unicode comment\ndef main() -> U32:\n  !\n'),
 ('unicode-before-point','def main() -> U32:\n  ("😀" foo)\n'),
 ('tab-after-string','def main() -> U32:\n  ("x"\tfoo)\n'),
 ('multichar-token','def main() -> U32:\n  (0 foobar)\n'),
 ('list-separator','def main() -> U32:\n  [0;1]\n'),
 ('args-separator','def main() -> U32:\n  f(0;1)\n'),
 ('crlf','def main() -> U32:\r\n\t!\r\n'),
 ('precedence','def main() -> U32:\n  (!;)\ndef broken(\n'),
 ('supplementary-at-point','def main() -> U32:\n  😀\n'),
 ('surrogate-at-point','def main() -> U32:\n  \ud800\n'),
 ('legacy-error','def main( -> U32:\n  !\n')]
(OUT/'parser-controls.json').write_text(json.dumps({'scope':'f_parse paired with pinned parse_book and baseline; exact matches are counted separately from semantic/error-order invariants; legacy fallback gaps stay explicit. Shared renderer DSpan boundary controls use Phase14 unchanged control script.','cases':[{'label':label,'source':source} for label,source in controls]},indent=2)+'\n')
identity=lambda f:{'file':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size}
shutil.copy2(__file__,OUT/pathlib.Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'project':str(project),'inputs':[identity(pathlib.Path(__file__).resolve()),identity(ROOT/'experiments/phase15/P15-002-parser-carets.md'),identity(original/'src/front/parser.bend')],'candidate':identity(p),'config':identity(OUT/'workflow.json'),'controls':[identity(OUT/'family-selection.json'),identity(OUT/'parser-controls.json')],'scope':'Only isolated parser error rendering changes; existing codepoint coordinates and conservative fallback retained; shared UTF-16 renderer reused.','cost':{'physicalLines':len(s.splitlines())-len(before.splitlines()),'nonblankLines':sum(bool(l.strip()) for l in s.splitlines())-sum(bool(l.strip()) for l in before.splitlines()),'bytes':len(s.encode())-len(before.encode()),'defs':len(re.findall(r'^def ',s,re.M))-len(re.findall(r'^def ',before,re.M)),'laws':len(re.findall(r'^law ',s,re.M))-len(re.findall(r'^law ',before,re.M))}},indent=2)+'\n')
print(str(OUT))
