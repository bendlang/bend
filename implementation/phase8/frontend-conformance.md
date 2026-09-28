# Phase8 complete frontend comparison

Date: 2026-09-28. The new target is upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`. Candidate06 completes all **2,996
parse/check observations over 1,498 fixtures**. It establishes type acceptance
for **997/1,001 positive fixtures**, refuses **481/482 validation-negative
fixtures**, and has **zero observed extra validation type acceptances**. The
remaining validation negative times out, so its outcome is unresolved.

Strict compatibility remains substantially incomplete: **1,002 check passes,
494 failures and two timeouts**. These counts retain error wording, location,
phase, verdict and exit requirements. They are distinct from semantic
acceptance/refusal counts and from exact comparison against TypeScript.

## Controlled scope and artifact identities

The immutable reference vector is
`selfhost/build/phase8/reference-frontend-01/reference.json`, SHA-256
`827e80c14d500f8ff77dd4e30f1e0fa4817780055ef783839741150fbf0fad31`.
Candidate06 is `selfhost/build/phase8/candidate-frontend-06/candidate.json`,
SHA-256 `185a19b4c17218a915b12830de7a9f26bf3bd473d93b8ad97048adba20c0b858`.
Its checked API is
`e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`.

The candidate used Node 24.18.0, one persistent worker, a 30-second request cap,
4 GiB heap and 4 MiB stack. All 2,996 rows completed; the two timeouts caused
worker replacement and remain explicit observations. There are no changed
inputs/artifacts or worker protocol errors. The vector finished at
01:58:57.330 UTC. Both `complete` and `selectedComplete` are false. This is a
correctness run, not a controlled timing experiment.

The comparison requires exact fixture paths, contents, expected output and
target-manifest identity. It normalizes no paths or diagnostics. Every row pairs
with its reference counterpart; **zero rows are missing**. The result has
**734 exact observation differences: 536 check and 198 parse**. That unit
includes verdict/evidence, type acceptance, proof trust, kernel metadata,
exit, diagnostic and output. It is not a count of unsafe type acceptances.
All **1,001 positive parse rows pass**; negative parse observations are retained
without being relabeled as strict parse passes.

## Semantic outcomes

| Fixture category | Count | Reference behavior | Candidate06 behavior |
|---|---:|---|---|
| Positive | 1,001 | All type accepted | 997 accepted; three refusals and one timeout |
| Validation negative | 482 | All refused | 481 refused; one timeout; zero extra acceptances |
| Deferred compile error | 4 | Type accepted | Same four type accepted; later execution gates are separate |
| Proof-trust refusal | 11 | Type accepted, then verdict refusal | Seven reach verdict refusal; four fail earlier; three exact passes |

The four remaining positive gaps are:

| Fixture | Observed result |
|---|---|
| `check/string_literal_descends.bend` | Request timeout |
| `check/string_literal_long.bend` | Stack overflow reported during checking |
| `compile/nat_pattern_deep.bend` | False refusal of the decreasing call `down(299n)` under the `300n` pattern |
| `proof/nat_literal_unfolds.bend` | Same deep-literal termination gap |

The unresolved negative is `halt/literal_descent_linear.bend` (timeout). Of the
481 established validation refusals, 289 occur at check, 183 at parse and nine
at load. A refusal in a different phase or with different diagnostic text is
still a strict failure. Only **two of 482** validation-negative check oracles
match exactly; the category has 479 strict failures and one timeout.

Candidate03 had seven additional validation type acceptances; candidate06 fixes
all seven: `check/do_header_quantity_span`, `check/do_header_typed`,
`comptime/later_def`, `import/alias_shadow`, `import/alias_twice`,
`import/shadow_base` and `parse/type_arg_parens` (all `.bend`). Its positive type
acceptance improves from 991 to 997. The later erroneous compile refusal of
`check/name_owned_def.bend` is also gone. No accepted positive now suffers a
later refusal inside the check lane.

## Trust and deferred errors remain separate

Seven trust fixtures reach the expected verdict refusal. Four of those still
have incompatible unsafe-definition ordering: `check/unsafe_field.bend`,
`check/unsafe_relies.bend`, `import/unsafe_used.bend` and
`io/marshal_imported_nullary_type.bend`. The four newly added imported-law cases
`import/unsafe_law_{derived,fill,own,unused}.bend` fail earlier at parse. They do
not establish the intended trust behavior. Thus the trust category has seven
semantic verdict refusals but only **three exact passes**. No Lean proof kernel
was run; `kernelChecked` remains false.

The four deferred-error fixtures are `io/cid_unknown.bend`,
`io/effect_ctr_name.bend`, `io/main_foreign.bend` and
`reg/array_open_element.bend`. Both reference and candidate type-accept them.
All four consequently fail the strict check-only fixture oracle even on the
reference. Their intended later compile refusals are independently exercised
in [the harness report](conformance-harness.md); this frontend vector alone
does not demonstrate those refusals. They are not counted as new validation
unsoundness or silently removed from the denominator.

## U2: old and new fixture coverage

Discovery follows the actual gate: `tests/<namespace>/*.bend`. Nested support
modules do not become fixtures. The old pin
`6018e28ecc67cf1fffc0c20c64b11023474c2df8` has **1,378** direct fixtures and the
new pin has **1,498**. There are **121 added paths, one removed path and 1,377
common paths**. Of the common paths, **510 source hashes changed and 867 are
byte-identical**. The removed fixture is `io/audio_open.bend`. The new tree's
11 nested Bend support files remain outside the 1,498-fixture denominator.

| New-target subset | Fixtures | Positive type acceptance | Validation refusals | Correct trust-refusal phase | Deferred-error type acceptance |
|---|---:|---:|---:|---:|---:|
| Added paths | 121 | 84/88 | 26/27; one timeout | 0/4 | 2/2 |
| Common paths | 1,377 | 913/913 | 455/455 | 7/7 | 2/2 |
| Common, source changed | 510 | 48/48 | 455/455 | 7/7 | 0/0 |
| Common, source unchanged | 867 | 865/865 | 0/0 | 0/0 | 2/2 |

The common subrows partition the common row. All four positive gaps and the
negative timeout are in newly added fixtures. Added paths have 84 strict check
passes, 35 failures and two timeouts; common paths have 918 passes and 459
failures. These are **new-target outcomes**, even for unchanged fixture source.
Common names do not demonstrate compatibility with the old compiler or Base.

## Release transfer and reproduction

Release07 uses the identical candidate06 API, driver, compiler ABI, Node
resource policy, assembler, typed adapter and target manifest. The runtime
changed; the final compiler/runtime combination therefore received a fresh
**44/44 passing actual foreign execution gate**, recorded in the
[selected execution report](selected-js-execution.md). The raw candidate06
frontend vector is retained under its original artifact identity.

The [evidence directory](frontend-conformance-evidence/) retains the strict
comparison, semantic triage, old/new path-and-hash inventory, run summary and
explicit release-transfer identities. Full raw vectors are the paths above.
From the repository root, reproduce the reports with:

```sh
node selfhost/tools/conformance/compare-artifacts.mjs --strict-paths \
  selfhost/build/phase8/reference-frontend-01/reference.json \
  selfhost/build/phase8/candidate-frontend-06/candidate.json \
  /tmp/phase8-reference-comparison.json
node implementation/phase8/conformance-harness-evidence/frontend-triage.mjs \
  selfhost/build/phase8/reference-frontend-01/reference.json \
  selfhost/build/phase8/candidate-frontend-06/candidate.json \
  /tmp/phase8-semantic-triage.json
node implementation/phase8/conformance-harness-evidence/corpus-migration.mjs \
  selfhost/.bootstrap/upstream selfhost/.bootstrap/upstream-phase8 \
  /tmp/phase8-corpus-migration.json \
  selfhost/build/phase8/candidate-frontend-06/candidate.json
```
