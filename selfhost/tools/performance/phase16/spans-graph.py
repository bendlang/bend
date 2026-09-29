#!/usr/bin/env python3
from pathlib import Path
import shutil,json,hashlib,difflib,subprocess
R=Path(__file__).resolve().parents[4];base=R/'selfhost/build/phase16/spans-origin-source-03/project';out=R/'selfhost/build/phase16/spans-integration-source-03';out.mkdir();P=out/'project';shutil.copytree(base,P)
parser=R/'selfhost/build/phase16/parser-span-source-07/project';names=['lexer','parser','declarations','validate','parallel','sugar','literals_arrays']
for name in names:shutil.copy2(parser/'src/front'/f'{name}.bend',P/'src/front'/f'{name}.bend')
p=P/'src/front/parser.bend';s=p.read_text();old='kt_span("Ref", "Empty", 0, 1, Nil{}, opBegin, opEnd)';assert s.count(old)==1;s=s.replace(old,'kt_span("FGlobal", "Empty", 0, 1, Nil{}, opBegin, opEnd)');p.write_text(s)
checker=R/'selfhost/build/phase16/checker-source-04/src_check_kernel.bend.patch';subprocess.run(['patch','--batch','--forward',str(P/'src/check/kernel.bend'),str(checker)],check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
p=P/'tools/typed-driver.mjs';s=p.read_text();s=s.replace('if(located&&!prior&&!seeded)validateSpanBook(parsed.book,[range]);','// A rejected partial book is not consumed by the semantic loader. Preserve\n    // its original parse/import error before inspecting successful-book metadata.\n    if(located&&!prior&&!seeded&&!parsed.error)validateSpanBook(parsed.book,[range]);');p.write_text(s)
p=P/'src/load/graph.bend';s=p.read_text();old='u => fpe_source_render(legacy, kid(owner, 0), fpe_unique_source(fpe_owner_path(List.reverse(&2, KTerm, done), ix(owner)), sources, atom("Absent"))), u => legacy)';new='u => fpe_source_render(legacy, kid(owner, 0), f_choose(KTerm, U32.is_gt(kb(kid(owner, 0)), 0), u => fpe_located_source(kid(owner, 0), sources), u => fpe_unique_source(fpe_owner_path(List.reverse(&2, KTerm, done), ix(owner)), sources, atom("Absent")))), u => legacy)';assert old in s;s=s.replace(old,new)
s=s.replace('f_eq(tg(source), "ParseSource"), u => fpe_render(nm(source), error), u => legacy)', 'f_eq(tg(source), "ParseSource"), u => f_choose(String, U32.is_gt(kb(source), 0), u => fpe_origin_render(nm(source), kb(source), error), u => fpe_render(nm(source), error)), u => legacy)')
s+='''
# The first selected frontend Error keeps its existing traversal order. Located
# errors resolve directly through source ownership, including imported aliases.
@unsafe
def fpe_located_source(+error: KTerm, +sources: List<&2,FSource>) -> KTerm:
  match sources:
    case Nil{}: atom("Absent")
    case Con{head, rest}:
      f_choose(KTerm, U32.is_gt(f_source_begin(head), 0) && U32.is_ge(kb(error), f_source_begin(head)) && U32.is_ge(ke(error), kb(error)) && U32.is_lt(ke(error), f_source_end(head)),
        u => kt_span("ParseSource", f_source_text(head), 0, 0, Nil{}, f_source_begin(head), f_source_end(head)),
        u => fpe_located_source(error, rest))
''';p.write_text(s)
(out/'workflow.json').write_text(json.dumps({'project':str(P),'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'cpu':'2','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n');shutil.copy2(__file__,out/Path(__file__).name)
rows=[];patch=[]
for folder in ['src','tools']:
 for p in sorted((P/folder).rglob('*')):
  if not p.is_file():continue
  rel=p.relative_to(P);old=base/rel
  if old.is_file() and old.read_bytes()!=p.read_bytes():
   rows.append({'relative':str(rel),'before':hashlib.sha256(old.read_bytes()).hexdigest(),'after':hashlib.sha256(p.read_bytes()).hexdigest()});patch.extend(difflib.unified_diff(old.read_text().splitlines(True),p.read_text().splitlines(True),fromfile='a/'+str(rel),tofile='b/'+str(rel)))
(out/'manifest.json').write_text(json.dumps({'baseline':str(base),'project':str(P),'parser':str(parser),'checkerPatch':str(checker),'changes':rows},indent=2)+'\n');(out/'source.patch').write_text(''.join(patch));print(P)
