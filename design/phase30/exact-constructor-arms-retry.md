# Retry exact constructor arms under corrected entry permission

Prospective bounded retry, after checked attempt07. The original widening from
`0 < count < total` to `0 < count <= total` remains rejected with its old runtime
and all its evidence unchanged. This is a new hypothesis about the corrected
runtime, not a reinterpretation of the earlier three failures or 1.023× timing.
No production source change is authorized by this investigation plan alone.

The earlier exact-arm callback evaluated its field body before the enclosing
oversaturated application performed a later copied-vector length read. That
changed effect order, leaked an Array.get before a throwing getter, and missed
a callee replacement at that boundary. See
[the rejected report](../../implementation/phase30/exact-arms.md) and the retained
`selfhost/build/phase30/review-exact-arm-outer-01/report.json`.

Checked attempt07's matcher1p now uses the reviewed exactCode permission. Its
raw, oversaturated, callback-hooked and reentrant unprivileged paths return the
original generic result after the same projection, first length read and
literal code construction:

```js
n ? jump(fn(arity, code), projected) : fn(arity, code)
```

They neither copy the projected vector nor execute its field body early. This
appears to repair the precise boundary that rejected the earlier widening.
Only a true exact application may take the prebinding path; exact apply has no
post-callback argument-length or arity read. The existing helper already mirrors
the copied-field vector's exact, partial and oversaturated branches, including
changing lengths and the final force boundary.

The remaining scope is the existing literal, unlifted arm proof. Its new arm
descriptor and code are fresh compiler-created objects, so their removed generic
metadata reads have no user-defined accessors under the established stable-host-
intrinsics contract. Projection, foreign field-vector slice methods, scalar/body
effects, lexical captures and returned bounce/build values remain observable and
must retain their order. No callee G lookup, public descriptor or argument
evaluation is replaced. Zero fields, erased fields, too-short arms, lifted code
and unknown/effectful factories continue to decline.

## Smallest discriminator

Start from the immutable checked attempt07 output of the original edit-distance
program, with its corrected runtime already embedded. Apply only the same five
literal cell/cell.f1–f4 constructor-arm prefix replacements used by the rejected
generated-JavaScript ablation. Preserve the original module, capture exact source,
tool and runtime identities, and assert every changed site. Do not transplant
the old uncorrected runtime or mix private workers, array bypasses, loop changes
or lexical helper experiments into this comparison.

Use the maintained complete four-array row wrapper and independent oracle for
the generated-output fixture. A wrapper derived from the original program is a
fixture, not another checked compiler emission. Keep those identities separate.
Run zero/one/many rows, diverse seeds and the existing full-state points. If the
generated output does not match the expected five shapes, inspect the new shape
and freeze an amended derivation before replacing it.

Run the three historical outer-vector witnesses first in repaired mode: plain
event order, throwing fourth length read, and late Array.get replacement. They
must match corrected unchanged output exactly. Preserve fresh failure receipts
if they do not. Also retain raw/overapplied callback bounce observations and a
code.call observer that sees the callback's result before forcing it.

Then cover projected vectors whose original and copied lengths differ, change
on later reads, or throw; custom slice/getter/Proxy behavior; zero/short/exact/long
vectors; function-valued field-body results; nested tail returns and malformed
overapplication. Check public matcher arity, null environment, bound ownership,
anonymous arrow callback name/length/own properties/nonconstructibility, captured
arm variables, and independent saved partials. The existing 33 projected-vector
controls are useful but insufficient alone: they missed the original outer
boundary. The current seven exact-entry/prebinding controls supply additional
raw, hooked and reentrant coverage and should run against the same runtime.

## Measure before changing admission

Only a passing corrected-runtime derivative proceeds to clean paired timing.
Freeze the same complete 32-cell row point, `[32,17]`, consuming all four arrays;
use the maintained rotating screen and separate long-warm confirmation, with
the lead's exclusive CPU3 slot. Keep runtime and all unrelated program bytes
identical. Record first call, warmup, timed halves, every sample, output bytes and
the full result check. Any named operation counters use separate copies.

The earlier 2.3% saving cannot transfer: registering the public matcher callback
changes the overhead being measured. The corrected extension may be neutral or
slower. Reject or defer a noisy or negligible result even when semantic controls
pass. This is a lower-priority, bounded retry of existing machinery, not a reason
to interrupt a larger confirmed improvement.

## Conditional compiler integration

If the new semantic and performance evidence justifies it, the implementation
should be only the count comparison and accurate admission comment in arm.bend.
Do not add another runtime helper, token, guard, IR tag, public ABI or special
five-name case. A fresh checked compiler must then run the actual arm harness:
72 historical observations plus the separate 22 exact-arm observations, with
`expectExactArms:true`; the current checked baseline remains explicitly false.
Reacquire the real edit-distance output and repeat the outer-boundary witnesses,
full-array oracles, callable-shape controls and paired timing on actual compiler
output before promotion. Keep the rejected old experiment and the new retry
separate in design, implementation reports and the ledger.
