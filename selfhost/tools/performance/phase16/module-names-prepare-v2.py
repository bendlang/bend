from pathlib import Path
import difflib, hashlib, json, shutil

root=Path(__file__).resolve().parents[4]
phase=root/'selfhost/build/phase16'
base=phase/'module-names-source-01/project'
out=phase/'module-names-source-02'
out.mkdir();shutil.copytree(base,out/'project')
p=out/'project/src/diagnostic/frontend.bend'
before=p.read_text();s=before
def replace(a,b):
    global s
    assert s.count(a)==1,(a,s.count(a))
    s=s.replace(a,b)
replace('@unsafe\ndef fp_range_env(','''@unsafe
def fp_span_matches(+span: DSpan, +source: FSource, +begin: U32, +end: U32) -> Bool:
  match span:
    case DNoSpan{}: False{}
    case DSpan{text, left, right}: U32.is_eq(left, U32.sub(begin, f_source_begin(source))) && U32.is_eq(right, U32.sub(end, f_source_begin(source))) && String.eq(text, f_source_text(source))

@unsafe
def fp_range_env(''')
replace('def fp_range_env(+sources: List<&2,FSource>, +done: List<&2,KTerm>, +begin: U32, +end: U32)', 'def fp_range_env(+sources: List<&2,FSource>, +done: List<&2,KTerm>, +begin: U32, +end: U32, +span: DSpan)')
replace('u => fp_module_env(done, f_source_path(head)), u => fp_range_env(rest, done, begin, end)', 'u => kc(List<&2,KPName>, fp_span_matches(span, head, begin, end), u => fp_module_env(done, f_source_path(head)), u => Nil{}), u => fp_range_env(rest, done, begin, end, span)')
replace('def fp_diagnostic_env(+trail: List<&2,KTerm>, +sources: List<&2,FSource>, +done: List<&2,KTerm>)', 'def fp_diagnostic_env(+trail: List<&2,KTerm>, +sources: List<&2,FSource>, +done: List<&2,KTerm>, +span: DSpan)')
replace('u => fp_range_env(sources, done, kb(head), ke(head)), u => fp_diagnostic_env(rest, sources, done)', 'u => fp_range_env(sources, done, kb(head), ke(head), span), u => fp_diagnostic_env(rest, sources, done, span)')
replace('fp_diagnostic_env(trail, sources, done))))', 'fp_diagnostic_env(trail, sources, done, span))))')
p.write_text(s)
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'located-context-guard.patch';patch.write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='src/diagnostic/frontend.bend',tofile='src/diagnostic/frontend.bend')))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/diagnostic/frontend.bend'),'after':ident(p),'patch':ident(patch),'tool':ident(Path(__file__))},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py');print(out)
