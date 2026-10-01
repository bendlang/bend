# Exact-entry reflection ablation: rejected

Skipping repeated exact-entry reflection checks inside the full-root proof does
**not show a reliable speed gain**, so it is not promoted. No production patch or
actual-checked successor adapter was written or applied for this hypothesis.
Checked03 remains selected for Phase36 integration.

The saved-output parent is actual checked03 API
`93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`.
The transform keeps exact-code membership, call/environment read order, exact
entry consumption and finally restoration. Only code-prototype/own-call/global
call descriptor checks under an active complete-root proof are omitted. The
independent cost owner reviewed both the proof premise and exact transform.

## Measured result

`exact-screen03` completes five balanced fresh-process rounds in **64.257s**,
CPU3, using the maintained unprofiled execution worker and original full ray
point. Exact outputs pass. Diagnostic counters are absent from these modules.

| Variant | Median ms | Min–max ms | Individual ms samples |
|---|---:|---:|---|
| Actual checked03 | 792.012 | 786.446–883.071 | 786.446, 792.012, 789.340, 799.164, 883.071 |
| Reflection ablation | 793.867 | 758.223–804.623 | 798.216, 793.867, 758.223, 804.623, 760.878 |
| Pinned TypeScript | 34.260 | 34.004–34.445 | 34.242, 34.402, 34.260, 34.004, 34.445 |

The candidate median is **0.234% slower**. Samples overlap and are nonstationary;
two fast candidate samples do not establish a repeatable improvement. This is a
null/inconclusive performance observation, not proof the transformation is
intrinsically slower. The predeclared admission criterion is unmet.

The clean module grows by 57 bytes (130,368→130,425). A tiny code-size cost does
not justify an unmeasured production benefit or another final compiler build.

## Controls and mechanism witness

- Existing colf controls: **57 oracle rows / 200 boundaries** (`exact-colf03`).
- Scope cleanup/admission controls: **10 observations** (`exact-scope03`).
- Actual compiled overflow fixture with runtime-only ablation: **16 benign
  oracle rows / four Error callback boundaries** (`exact-error03`).
- Exact-entry counters and public mutation: **seven observations**
  (`exact-counts03`), including own-call replacement, code-prototype replacement,
  and a call getter which reenters colf. Public callbacks have inactive proof.

On the first live center-pixel colf point both variants execute 380 invokeExact
calls; 25 reach exact-member reflection, and 24 are inside the proof. The
ablation skips those 24 checks, while retaining the outside public check. Thus
only 6.3% of these invokeExact calls even reach the newly removed work. Membership
and ordinary generic dispatch remain. Counter evidence confirms an active
transformation; it also explains why this was a narrower opportunity than the
previous repeated whole-graph guard checks. It does not establish the timing's
JIT/GC cause.

These named semantic controls pass, but they do not constitute broad conformance
or authorize production integration. The rejection avoids unnecessary new
runtime assumptions. All producers, originals, diagnostics and samples remain
preserved; [the summary](guard-exact-summary.json) records report hashes. The
[design](../../design/phase36/guard-exact-entry.md) remains the original admission
plan, and [P36-004](../../experiments/phase36/P36-004-exact-entry.md) records the
decision separately.
