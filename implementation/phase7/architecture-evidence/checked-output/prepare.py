#!/usr/bin/env python3
"""Freeze a bounded checked-output kernel candidate without editing production."""
import difflib
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'selfhost/src/check/kernel.bend'
OUT = HERE / 'candidate-01'
OUT.mkdir(exist_ok=False)
before = SOURCE.read_text()
after = before

def replace(old, new):
    global after
    assert after.count(old) == 1, old
    after = after.replace(old, new)

helpers = '''# P7-A01 research: preserve successful checked children and their exact types.
# This is a bounded output contract. Let, Mat, Rwt and template materialization
# still need their own output construction and are not supported by this slice.
@unsafe
def co_typed(+r: KChecked, +ty: KTerm) -> KChecked:
  kc(KChecked, good(r), u => ok(kt("Ann", "", 0, 0, [strip(ct(r)), ty]), cy(r), cs(r)), u => r)

@unsafe
def co_inferred(+r: KChecked) -> KChecked:
  co_typed(r, cy(r))

@unsafe
def co_right(+a: KChecked, +b: KChecked, +ty: KTerm) -> KChecked:
  both(a, b, ct(b), ty, False{})

@unsafe
def co_application(+f: KChecked, +x: KChecked, +fty: KTerm, +ty: KTerm) -> KChecked:
  both(f, x, app(kt("Ann", "", 0, 0, [strip(ct(f)), fty]), ct(x)), ty, False{})

@unsafe
def co_constructor(+t: KTerm, +ty: KTerm, +r: KChecked) -> KChecked:
  checked(r, KTerm{tg(t), nm(t), ix(t), qt(t), ks(ct(r)), rm(t)}, ty)

'''
replace('@unsafe\ndef ctx_get(', helpers + '@unsafe\ndef ctx_get(')
replace('  dg_trace(e, ctx, t, atom("Absent"), infer_node(e, ctx, core_beta(t), dem, sp))',
        '  co_inferred(dg_trace(e, ctx, t, atom("Absent"), infer_node(e, ctx, core_beta(t), dem, sp)))')
replace('u => both(check(e, ctx, kid(t, 1), 0, typ(1)), check(e, ctx, kid(t, 0), dem, kid(t, 1)), kid(t, 0), kid(t, 1), False{}),',
        'u => co_right(check(e, ctx, kid(t, 1), 0, typ(1)), check(e, ctx, kid(t, 0), dem, kid(t, 1)), kid(t, 1)),')
replace('u => both(r, check(e, ctx, kid(t, 1), qdem(qt(ty), dem), kid(ty, 0)), t, subst(kid(ty, 1), ix(ty), kid(t, 1)), False{}),',
        'u => co_application(r, check(e, ctx, kid(t, 1), qdem(qt(ty), dem), kid(ty, 0)), ty, subst(kid(ty, 1), ix(ty), kid(t, 1))),')
replace('  both(a, b, ct(b), cy(b), False{})',
        '  both(a, b, kt("Args", "", 0, 0, Con{ct(a), ks(ct(b))}), cy(b), False{})')
replace('  dg_trace(e, ctx, t, ty, check_node(e, ctx, core_beta(t), dem, ty))',
        '  co_typed(dg_trace(e, ctx, t, ty, check_node(e, ctx, core_beta(t), dem, ty)), ty)')
replace('check_lam_done(t, ty, q, both(check(e, ctx, kid(ty, 0), 0, typ(kindq(e, q))), check(lhs_step(e, var(nm(t), ix(t))), ctx_bind(ctx, ix(t), q, nm(t), kid(ty, 0)), kid(t, 0), dem, subst(kid(ty, 1), ix(ty), var(nm(t), ix(t)))), t, ty, False{}))',
        'check_lam_done(t, ty, q, co_right(check(e, ctx, kid(ty, 0), 0, typ(kindq(e, q))), check(lhs_step(e, var(nm(t), ix(t))), ctx_bind(ctx, ix(t), q, nm(t), kid(ty, 0)), kid(t, 0), dem, subst(kid(ty, 1), ix(ty), var(nm(t), ix(t)))), ty))')
replace('u => ok(t, ty, uses_del(cs(r), ix(t)))), u => r)',
        'u => ok(kt("Lam", nm(t), ix(t), q, [ct(r)]), ty, uses_del(cs(r), ix(t)))), u => r)')
replace('u => checked(tele_check(e, ctx, tele_fill(cb(e), dt(ctr), ks(ty)), ks(t), dem), t, ty),',
        'u => co_constructor(t, ty, tele_check(e, ctx, tele_fill(cb(e), dt(ctr), ks(ty)), ks(t), dem)),')

(OUT / 'kernel.bend').write_text(after)
(OUT / 'kernel.patch').write_text(''.join(difflib.unified_diff(
    before.splitlines(True), after.splitlines(True),
    fromfile='a/selfhost/src/check/kernel.bend', tofile='b/selfhost/src/check/kernel.bend')))
def identity(s):
    b = s.encode()
    return {'physicalLines': len(s.splitlines()), 'nonblankLines': sum(bool(x.strip()) for x in s.splitlines()),
            'bytes': len(b), 'sha256': hashlib.sha256(b).hexdigest()}
(OUT / 'source-counts.json').write_text(json.dumps({'baseline': identity(before), 'candidate': identity(after),
    'addedHelpers': ['co_typed', 'co_inferred', 'co_right', 'co_application', 'co_constructor'],
    'removedModules': [], 'retiredProductionLines': 0,
    'scope': 'Supported checked-output mechanics only; all original annotation and specialization functionality remains.'}, indent=2) + '\n')
print(OUT)
