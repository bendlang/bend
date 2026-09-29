# Lambda quantity presence

This isolated experiment preserves one syntax distinction required by pinned
TypeScript's memo keys. It does not claim a performance improvement or change
the installed compiler. The authoritative parent is
`selfhost/build/phase16/literal-context-source-04/project`, genuinely checked as
`literal-context-build-01` before this work began.

The independent `spans-lam-review-01` witness shows the problem: the generated
Lambda in `&x:Type -> Type` and the written Lambda in
`Exists(Type, x => Type)` previously had identical Bend representations. Pinned
TypeScript's lowered keys differ by the optional quantity property, costing
17 UTF16 code units. The full example keys contain 184 and 201 units. Neither
semantic quantity nor binder/source identity recovers this distinction.

## Representation and scope

`spans-lambda-source-04` adds one eight-field `KLambda` variant. It replaces the
generic tag field with `quantityPresent:Bool`; ordinary terms and compact
literals gain no fields. Existing children and removed-name lists retain their
roles. `tg` still exposes Lam and `qt` still exposes the original numeric
quantity. A common field-changing rebuild preserves the variant and presence.
All production Lambda constructors are explicit; ordinary `kt` and `kt_span`
allocation remains branch-free.

Written lambdas, definition parameters, do-bind continuations and pattern
flattening binders retain their explicit quantity. Existential/refinement and
rewrite sugar, left-hand-side extension, strong-normalizer results and checked
backend output omit it, matching the corresponding pinned producers.
Substitution, alpha-renaming, freshening, source-range changes, specialization
shifts and alias/path/namespace rewriting preserve it. Semantic term equality
ignores this syntax fact; memo-key identity is the separate checker-owner task.

The coordinated host changes advertise `compiler_term_abi1`, replacing only
the uninstalled literal prototype's capability. Cache version 6 binds termAbi1
alongside source ABI3. It rejects unknown present capabilities, malformed
Lambda presence and stale cache formats. Historical installed API paths remain
available; frozen literal-only experiments retain their own historical hosts.

The cumulative patch is 23 files, **83 additional physical lines** and 5120
additional bytes. Of those,75 lines are in the core representation, seven in
source rebuild pattern matches, and one in host validation; remaining changes
replace existing expressions.
There are 16 explicit producer constructions. These are representation costs,
not a simplification or speed claim. Exact files and hashes are in the source02
manifest and cumulative patches in `spans-lambda-handoff-01`.

## Retained evidence and pending gates

Source01 is retained. Read-only producer review found its rewrite-motive helper
name differed from the preparer's classification; both nested Lambdas were
incorrectly marked present. Source02 fixes that mapping before the first build.
No source01 compiler build ran. The original preparer and corrective preparer
are preserved separately.

The first direct run, `spans-lambda-direct-01`, retained two failures. One was a
real metadata loss: scope lowering passed a Lambda through a temporary Var and
reconstructed it with an explicit quantity. Source03 restores only the original
presence on the resulting outer Lambda. The other was an incorrect test count
assumption (raw Base has 37 direct Lambdas, not more than 100); full raw projection
already matched. The corrected test binds the old/new count and requires every
new Lambda to use the explicit variant. Neither original failure was rewritten.

Source03/build02 passes **110 direct controls** and **39 host controls**. They
cover all numeric quantities 0/1/2/4 with both presence states, ten rebuild paths,
normalization, semantic equality, legacy KTerm/Lam inputs, pinned implicit and
written examples, full raw Base projection (37 Lambdas), full loaded Base
projection (2038 Lambdas), malformed payloads, unknown ABI, stale caches and
positional transport. Probe exports were appended only to a derived checked API
copy; no probe exports enter the production source or handoff.

The separate `spans-lambda-demand-01` witness found a semantic consequence:
absent q on a Lambda retaining numeric q2 must follow the expected affine type;
the old predicate incorrectly upgraded it to Many. Under a Kind(&0) domain,
TypeScript accepts absent q and rejects explicit Many, whereas the initial
candidate rejected both. Root reviewed source04 adding presence to exactly three
existing predicates: check_lam, check_lam_q and ka_lam. Legacy KTerm/Lam still
means present quantity. This correction adds no lines or representation fields.

Final **source04/build03** is genuinely checked, uses the unchanged current v5
derivative, and passes all 36 maintained observations (the two inherited strict
differences remain). Its **25 independent quantity-mode controls** pass:
affine-only/Data domains, absent/explicit annotations, zero/one/two uses,
expected affine/Many/erased quantities, checked output quantities and legacy
inputs. It fixes both incorrect rejection of absent q and incorrect acceptance
of duplicated affine use. The original witness and all prior attempts remain.

Authoritative files and cumulative patches are bound by
`spans-lambda-handoff-01/manifest.json`; API identity and genuine lineage are in
`spans-lambda-build-03/attempt.json`. Source04 differs from the fully controlled
source03 only in those three reviewed predicates. Host/cache transport and
metadata policy are unchanged. The memo encoder is independently owned; final
corpus, historical helper replay, backend and serial timing gates remain root's
responsibility. No speed claim follows from these representation controls, and
no installed compiler or historical API was modified here.
