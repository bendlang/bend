# Prefix identity and live-checker boundary controls

The installed Phase17 compiler's `exact_prefix` omits compact literal payloads
and lambda quantity presence. The isolated prefix correction fixes all five
observed false equalities in the frozen 12-case public API suite. This result
does not yet establish the larger live-checker migration.

Inputs were frozen in
`selfhost/build/phase19/instance-boundary-inputs-01/plan.json` before consuming
either candidate. The independent pinned TypeScript oracle at
`instance-boundary-oracle-01/result/report.json` passes all 22 observations:
12 syntax identities and 10 source-checking fixtures. It imports only pinned
TypeScript for semantic observations; no candidate produces its expectations.
Every run has a supervised CPU2 process record, consumed tools, and file/API
identities. Original failures remain in their original output directories.

## Closed prefix identity experiment

| Image | API SHA prefix | Result |
| --- | --- | --- |
| Installed Phase17 `find-worker-build-01` | `9b20de5032e306a0` | 7/12 pass; five false equalities |
| Isolated Phase19 `prefix-build-01` | `66d6ce45c0c6ea89` | 12/12 pass, in both argument directions |

The failing parent cases change a Nat value, U32 value, String value, affine
lambda quantity presence, or Many lambda quantity presence. Controls preserve
literal equality, astral string equality, literal-kind distinctions, compact
versus expanded constructor syntax, historical explicit `KTerm` lambdas, and
the established omission of source ranges from syntax identity.

Reports are `instance-boundary-exact-parent-01/result/report.json` and
`instance-boundary-exact-candidate-01/result/report.json`. Their outer launcher
reports distinguish a healthy completed failure witness from process failure.
The test uses exported `exact_prefix`; no generated-code instrumentation or
private-helper replacement is involved.

## Frozen proof-safety extension

A separate `instance-boundary-proof-inputs-01` freezes a self-contained Nat
declaration and reflexivity proof. The original goal is `{0n == 0n : Nat}`;
the changed goal is `{0n == 1n : Nat}` with the same `{==}` proof body. Only the
second literal payload changes. This is the same cache-identity mechanism as a
U32 witness and avoids depending on Base loading.

The independent oracle accepts the original proof and rejects the changed
proof. The installed compiler also rejects the changed proof under ordinary
checking, with `proof: reflexivity endpoints differ`, but returns true from
`exact_prefix` and **accepts the invalid proof through
`check_from_exact_prefix(changed, original)`**. Its report explicitly records
`acceptedInvalidCachedProof: true` and fails the required safety contract.

The isolated correction returns false for that prefix and rejects the changed
proof through both full and cached checking. This closes an actual proof-checking
bypass, beyond the direct equality discrepancy. Reports are
`instance-boundary-proof-{oracle,parent,candidate}-01/result/report.json`;
the original failed parent observation remains immutable. All six oracle/direct/
proof launcher processes have closed. [The machine receipt](instance-boundary.json)
binds the tools, fixtures, reports and process records by file size and SHA256.

## Prepared live-checker boundary suite

The 10 source fixtures cover prefix memo reuse, nested instances, law fill,
future-body visibility before and after fill, failed live instances, private
generic failure scope, successful generic output, TODO bodies, and unfilled
laws. The prepared `boundary` mode records 100 public rows: each fixture loads,
checks program completion and legacy diagnostics with empty/partial/full/changed
prefixes, and exercises raw plus repeated materialized specialization.

Success checks distinguish the legacy original source book from completed
program output and compare instance names and checked references with the pin.
Failure checks compare full rendered diagnostics, deepest owner, and visible
semantic-world membership, including an active instance placeholder or generic
private binding. The suite waits for a genuinely checked integrated candidate;
these prepared controls are not yet passing migration evidence.

Immediate checking intentionally changes the old Phase18 public18 assumption
that `check_book` accepts the `instance-failure` fixture before a later
`specialize_book` refusal. Stable public `KSpecialized`/four-field `KChecked`
shapes and projection demand controls remain required separately. Repeated raw
specialization checks success, instance identity, reference shape, and subsequent
checking; it does not claim byte equality of deliberately canonicalized output.

No compiler source was edited by this control owner. No install, speed gain,
full conformance, or remote publication follows from these results.
