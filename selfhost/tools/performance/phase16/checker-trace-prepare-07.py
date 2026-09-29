"""Bind existing checker failures to their actual binder/proof occurrence."""
from pathlib import Path
import difflib
import hashlib
import json
import shutil
root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'spans-integration-source-04/project'
out = phase / 'checker-trace-source-07'
out.mkdir()
shutil.copytree(base, out / 'project')
def replace(s, old, new):
    assert s.count(old) == 1, (old, s.count(old))
    return s.replace(old, new)
relative = 'src/check/kernel.bend'
p = out / 'project' / relative
s = p.read_text()
s = replace(s, 'check_let_done(check(e, ctx, let_cells(h, bindings), dem, ty), bindings, us)',
            'check_let_done(e, outer, check(e, ctx, let_cells(h, bindings), dem, ty), bindings, us)')
s = replace(s, 'dg_kind_check(e, outer, cy(r), qt(h), nm(h))',
            'dg_kind_at(e, outer, cy(r), qt(h), nm(h), h)')
s = replace(s, 'def check_let_done(r, bs, us):', 'def check_let_done(e, ctx, r, bs, us):')
s = replace(s, 'u => dg_quant_error("let binder consumed more than allowed", nm(h), qt(h), uses_get(cs(r), ix(h)))',
            'u => dg_trace(e, ctx, h, cy(r), dg_quant_error("let binder consumed more than allowed", nm(h), qt(h), uses_get(cs(r), ix(h))))')
s = replace(s, 'check_let_done(ok(ct(r), cy(r), uses_del(cs(r), ix(h))), t, us)',
            'check_let_done(e, ctx, ok(ct(r), cy(r), uses_del(cs(r), ix(h))), t, us)')
s = replace(s, 'u => dg_bad_detail("rewrite requires equality evidence", dg_text("an equation {a == b : T}"), cy(r)))',
            'u => dg_trace(e, ctx, kid(t, 0), ty, dg_bad_detail("rewrite requires equality evidence", dg_text("an equation {a == b : T}"), cy(r))))')
p.write_text(s)
relative = 'src/diagnostic/trace.bend'
p = out / 'project' / relative
s = p.read_text()
s = replace(s, '  +kind = typ(kindq(e, q))\n  dg_kind_result(t, q, name, kind, check(e, ctx, t, 0, kind))',
'''  dg_kind_at(e, ctx, t, q, name, t)

@unsafe
def dg_kind_at(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +q: U32, +name: String, +site: KTerm) -> KChecked:
  +kind = typ(kindq(e, q))
  dg_kind_result(t, q, name, site, kind, check(e, ctx, t, 0, kind))''')
s = replace(s, 'def dg_kind_result(+t: KTerm, +q: U32, +name: String, +kind: KTerm, +r: KChecked)',
            'def dg_kind_result(+t: KTerm, +q: U32, +name: String, +site: KTerm, +kind: KTerm, +r: KChecked)')
s = replace(s, 'U32.is_eq(q, 2) && String.eq(ce(r), "type mismatch")', 'String.eq(ce(r), "type mismatch")')
s = replace(s, 'norm_exact(kid(ct(r), 3), t), u => KChecked',
            'norm_exact(kid(ct(r), 3), t) && (U32.is_eq(kb(t), 0) || U32.is_eq(kb(kid(ct(r), 3)), 0) || (U32.is_eq(kb(t), kb(kid(ct(r), 3))) && U32.is_eq(ke(t), ke(kid(ct(r), 3))))), u => KChecked')
s = replace(s, 'kid(ct(r), 3), kid(ct(r), 4), dg_text("Note: +" ++ name ++ " can be used many times, so its type must be Data.")',
            'site, kid(ct(r), 4), kc(KTerm, U32.is_eq(q, 2), u => dg_text("Note: +" ++ name ++ " can be used many times, so its type must be Data."), u => kid(ct(r), 5))')
p.write_text(s)
def identity(p):
    return {'file':str(p.resolve()), 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
changes=[]
for relative in ['src/check/kernel.bend', 'src/diagnostic/trace.bend']:
    p=out/'project'/relative
    patch=out/(relative.replace('/','_')+'.patch')
    patch.write_text(''.join(difflib.unified_diff((base/relative).read_text().splitlines(True),p.read_text().splitlines(True),fromfile=relative,tofile=relative)))
    changes.append({'relative':relative,'before':identity(base/relative),'after':identity(p),'patch':identity(patch)})
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'changes':changes,'tool':identity(Path(__file__)),
    'plan':identity(root/'design/phase16/checker-trace-points.md'),
    'baseline':identity(phase/'checker-trace-baseline-03/selected/paired.json'),
    'scope':'Only source sites and immediate kind-note guard. Closing order is deliberately unchanged; no first-order evidence yet justifies reversing it.'},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py')
print(out)
