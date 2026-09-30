# P30-028 — Remove redundant constructor-arm prebinding

Owner: phase30 lead; independent reviewer: phase30_review. Source checkpoint
[`73912c3`](https://github.com/rom1504/bend/commit/73912c3) implements the
[prospective retirement plan](../../design/phase30/retire-arm-prebinding.md).
This follows the isolated runtime repair in
[P30-027](P30-027-generic-runtime-row.md); it does not combine another performance
intervention with that attribution experiment.

**Hypothesis:** after restoring generic delayed field application in checked15,
the specialized constructor-arm admission and bridge can be removed from the
compiler without changing generated-program behavior. The shared matcher and
lambda emitter already express the same computation, so removal should reduce
maintained code and concepts without requiring a replacement optimization.

**Invariant:** a selected arm still projects once, reads the projected length,
creates its fresh callback/descriptor at the same point and returns the original
unsliced bounce or zero-field descriptor. Generic application retains subsequent
copying, partial/oversaturated scheduling and call hooks. Scalar Nat loops and
trees retain their registered final worker callback, guards and exact-entry
permission; only the outer partial matcher uses the common spelling.

Checked16 removes **64 maintained implementation lines** relative to the
separately checked runtime repair15: the58-line arm.bend module and its eight
functions, one manifest entry and the five-line runtime bridge. Two emission
lines are replaced. The generated runtime copy is regenerated, not counted as
an additional source reduction. Shared j_arm_type/j_arm_tel, scalar-region IR,
worker entry tokens and guards remain. No new compiler state or runtime metadata
is introduced.

## Checked artifact and controls

The immutable attempt is `selfhost/build/phase30/attempt-16`:

- Manifest: `4560e31fb1dd3afc7b38656fb890ea6f0b63928d0663dbae285df1642623c74e`.
- API: `33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637`.
- Runtime: `fab241aefeb2ad1626d7079a3b798eb163207cd38b3e0d80318941a01f8255f1`.
- Canonical Base: `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661`.

The Base identity is inherited from the unchanged canonical source; exact
consumed identities and commands are bound by the checked-emission receipts.
The independent [retirement review](../../implementation/phase30/retired-arm-independent-review.md)
contains the complete artifact paths and retained tooling failure. Its structural
auditor checks the complete runtime AST after only bridge deletion and the
complete generated AST after only the recognized old-to-generic matcher rewrite.
It is an evidence tool, never a compiler postprocessor.

| Gate | Fresh checked16 result |
|---|---|
| Checked build |36 focused exact checks pass. |
| Row / scalar helper / original Mandel structural correspondence |All pass;6 ordinary,1 registered, and2 ordinary plus3 registered sites respectively. |
| Public scalar boundary and numeric observations |146 +72 pass against15. |
| Exact-entry, raw callback and reentry observations |9 pass. |
| Callable shape across row / helper / original Mandel |315 /296 /312 pass; selected Nat/tree callback registration and identity remain. |
| Actual compiler arm suite |72 original +22 later observations pass with specialized emission disabled. |
| Fresh selected upstream JS |15 reference/candidate programs exact. |
| Primitive and worker integration |56,205 scalar +58 observations;3,759 scalar +14 observations;144 nested checks;1,129 primitive guards +25 observations;40 worker guards +2 observations. |
| Corpus / components / HVM |23 libraries with127 points;22 component checks; exact retained HVM stdout. |

The prototype owner also renews complete row states, alias/ordered boundaries
and all ten original-program acquisitions. These results and the precise fresh
integration scope are linked from
[final integration](../../implementation/phase30/final-integration.md). Selected
integration success is not a claim of complete backend conformance.

## Decision and measurement boundary

**Correctness:** promote the source retirement into the reviewed checked16
candidate under the named structural and public gates. **Measurement:** the fresh five-way row/scalar confirmation is complete at
`runtime-cleanup-confirm-16/report.json`,209.802 seconds outer. Complete row
medians are29 0.448173, held14 0.601983, repair15 0.448121, and16 0.444585 ms;
16's range0.442894–0.458928 overlaps15's0.447231–0.451254. It removes26.15% of
held14 time and recovers29's range, but the0.79% median15→16 change provides
**no separate deletion-speed claim**. Row16 half drift is−0.163% to+2.310%.
Scalar14/15/16 medians0.006965/0.006972/0.006975 ms and their ranges overlap;
all scalar half drift is at most3%. Scalar16 retains56.83×29 throughput and
costs4.096× the same-window TypeScript output. The row remains about52.8×
TypeScript output. These are two scoped programs, not a generated-program
average. Full transfer and installation remain separate release steps. See
[the current timing report](../../implementation/phase30/final-timing-16.md).

The first structural audit incorrectly parsed an exported generated suffix as
an independent module; Acorn rejected missing runtime declarations. Its three
failures remain immutable. The corrected16b audit parses the complete module
before selecting its generated nodes, and passes without disabling export
validation or widening the correspondence rule. The failed held14 matrix,
original prebinding counterexamples and intermediate checked15 remain preserved.

Tracked designs, review tools and implementation reports provide regeneration
instructions. Large emitted modules and raw receipts remain in the Phase30
artifact tree; final campaign archival and installation are parent-owned release
steps, not implied by this record. See the [ledger](../ledger.md).
