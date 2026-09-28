#!/usr/bin/env python3
import pathlib,json,shutil,hashlib
ROOT=pathlib.Path(__file__).resolve().parents[4]
OUT=ROOT/'selfhost/build/phase14/differences-prepare-02'
OUT.mkdir();project=OUT/'project';project.mkdir()
original=ROOT/'selfhost/build/phase12/integrated-03/snapshot'
for name in ['src','tools','tests']:shutil.copytree(original/name,project/name)
p=project/'src/diagnostic/render.bend';s=p.read_text();(OUT/'before-render.bend').write_text(s)
s=s.replace('law dg_snippet_at:\n  for +lines: List<&2, String>\n  for +at: U32\n  String','law dg_snippet_at:\n  for +lines: List<&2, String>\n  for +at: U32\n  for +left: String\n  for +length: U32\n  String')
s=s.replace('  for +line: U32\n  String','  for +line: U32\n  for +left: String\n  for +length: U32\n  String',1)
s=s.replace('    case DSpan{source, begin, end}: dg_snippet_at(String.lines(source), dg_line_at(source, begin, 1))','    case DSpan{source, begin, end}: dg_snippet_at(String.lines(source), dg_line_at(source, begin, 1), dg_marker_left(source, begin, ""), kc(U32, U32.is_gt(end, begin), u => U32.sub(end, begin), u => 0))')
a=s.index('@unsafe\ndef dg_snippet_at(');b=s.index('@unsafe\ndef dg_scope(',a)
s=s[:a]+'''@unsafe
def dg_marker_left(
  +source: String,
  +offset: U32,
  +left: String,
) -> String:
  match source:
    case SNil{}: left
    case SCon{c, rest}:
      kc(String, U32.is_eq(offset, 0), u => left, u => kc(String, U32.is_lt(offset, dg_units(c)), u => left ++ dg_padding(offset), u => dg_marker_left(rest, U32.sub(offset, dg_units(c)), kc(String, Char.is_eq(c, '\\n'), u => "", u => left ++ kc(String, Char.is_eq(c, '\\t'), u => "\\t", u => dg_padding(dg_units(c)))))))

@unsafe
def dg_carets(
  +count: U32,
) -> String:
  kc(String, U32.is_eq(count, 0), u => "", u => "^" ++ dg_carets(U32.sub(count, 1)))

@unsafe
def dg_marker_size(
  +length: U32,
  +remaining: U32,
) -> U32:
  kc(U32, U32.is_lt(length, remaining), u => length, u => remaining)

@unsafe
def dg_marker(
  +text: String,
  +width: U32,
  +left: String,
  +length: U32,
) -> String:
  dg_padding(width) ++ " | " ++ left ++ dg_carets(norm_max(1, dg_marker_size(length, kc(U32, U32.is_gt(dg_width(text), dg_width(left)), u => U32.sub(dg_width(text), dg_width(left)), u => 0))))

@unsafe
def dg_snippet_at(lines, at, left, length):
  dg_snippet_lines(lines, at, kc(U32, U32.is_lt(dg_lines_count(lines), U32.add(at, 1)), u => dg_lines_count(lines), u => U32.add(at, 1)), 1, left, length)

@unsafe
def dg_snippet_lines(lines, at, end, line, left, length):
  match lines:
    case Nil{}: ""
    case Con{h, rest}:
      kc(String, U32.is_gt(line, end), u => "", u => kc(String, U32.is_lt(U32.add(line, 1), at), u => "", u => "\\n" ++ dg_lpad(U32.show(line), dg_width(U32.show(end))) ++ kc(String, U32.is_eq(line, at), u => ">| " ++ h ++ "\\n" ++ dg_marker(h, dg_width(U32.show(end)), left, length), u => " | " ++ h)) ++ dg_snippet_lines(rest, at, end, U32.add(line, 1), left, length))

''' + s[b:]
assert s!=p.read_text();p.write_text(s)
config={'project':str(project),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'1','jobs':1,'profile':'equality','timeoutMs':30000}
(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda f:{'file':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
shutil.copy2(__file__,OUT/pathlib.Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'project':str(project),'inputs':[identity(pathlib.Path(__file__).resolve()),identity(ROOT/'experiments/phase14/P14-002-family.md'),identity(original/'src/diagnostic/render.bend')],'candidate':identity(p),'config':identity(OUT/'workflow.json'),'scope':'Only isolated checker span renderer changed.'},indent=2)+'\n')
print(str(OUT))
