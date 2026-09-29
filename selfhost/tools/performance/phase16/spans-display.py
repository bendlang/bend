#!/usr/bin/env python3
from pathlib import Path
import shutil,json,hashlib,difflib
R=Path(__file__).resolve().parents[4];base=R/'selfhost/build/phase16/spans-integration-source-03/project';out=R/'selfhost/build/phase16/spans-display-source-01';out.mkdir();P=out/'project';shutil.copytree(base,P)
p=P/'src/diagnostic/render.bend';old=p.read_text();s=old.replace('dg_location_text(name, dg_snippet(span))','dg_location_text(name, dg_module_snippet(span))');assert s!=old
s+='''
# book_load blanks leading imports while retaining their newlines. Coordinates
# still use the immutable raw source; only the displayed lines differ.
@unsafe
def dg_module_snippet(+span: DSpan) -> String:
  match span:
    case DNoSpan{}: ""
    case DSpan{source, begin, end}:
      dg_snippet_at(dg_module_lines(String.lines(source)), dg_line_at(source, begin, 1), dg_marker_left(source, begin, ""), kc(U32, U32.is_gt(end, begin), u => U32.sub(end, begin), u => 0))

@unsafe
def dg_module_lines(+lines: List<&2,String>) -> List<&2,String>:
  match lines:
    case Nil{}: Nil{}
    case Con{head, rest}:
      +line = String.trim_start(head)
      kc(List<&2,String>, String.is_empty(line) || String.starts_with(line, "#"),
        u => Con{head, dg_module_lines(rest)},
        u => kc(List<&2,String>, String.starts_with(line, "import") && dg_import_tail(String.drop(line, 6n)),
          u => Con{"", dg_module_lines(rest)}, u => lines))

@unsafe
def dg_import_tail(+text: String) -> Bool:
  match text:
    case SNil{}: True{}
    case SCon{head, rest}: Char.is_space(head)
'''
p.write_text(s);shutil.copy2(__file__,out/Path(__file__).name);(out/'render.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='a/src/diagnostic/render.bend',tofile='b/src/diagnostic/render.bend')));(out/'manifest.json').write_text(json.dumps({'baseline':str(base),'project':str(P),'changes':[{'relative':'src/diagnostic/render.bend','before':hashlib.sha256(old.encode()).hexdigest(),'after':hashlib.sha256(s.encode()).hexdigest()}],'scope':'Checker-only module line display; generic raw snippet unchanged; no source-offset or ABI changes.'},indent=2)+'\n');print(P)
