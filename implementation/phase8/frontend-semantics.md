# Phase 8 frontend and bounded semantic migration evidence

This report covers the frontend/binding work delegated to the semantic research
agent. Root owns release integration, full conformance totals and performance.
The target is upstream b2111cf43244e65f76ddc278ee695e669f720cbf. No speedup is
claimed from these changes; the separate unchanged-source emitter comparison
must not be attributed to frontend fixes.

## Implemented changes

- Accept adjacent unsafe definition suffix `?` as well as the decorator, with
  upstream-compatible header whitespace. Preserve an earlier type error.
- Share strict dotted-name validation; reject empty or digit-leading segments.
  Reject duplicate constructor field names without banning telescope shadowing.
- Validate typed-let binder syntax, array separators, and first parser errors.
  Count physical newlines inside quoted tokens for the following token cursor.
- Qualify module references using all declared local names. Preserve chronological
  family/template elaboration: future constructor patterns and omitted family
  parameters are not made visible merely because checker signatures are.
- Implement prefix `+` with lexical scope, distinguishing bare names from empty
  calls and qualified references. A private FUnboundVar marker becomes an ordinary
  fresh Var without entering the lexical binder mapping. Datatype quantified
  parameter filling remains a separate rule. The obsolete Phase6 marker-specific
  namespace flags and generic empty-call unwrap were deliberately not adopted.
- Fix capture in termination-checker left-hand columns for nested use of the same
  constructor telescope. Generated binders and matching constructor-field Vars
  are fresh above the book, current lhs, telescope, match term, goal and context.
  Telescope names and quantities are retained; domains need not be alpha-copied.
  The direct counter version deletes five physical lines relative to candidate02
  and avoids the previous full telescope freshening/rebuild.
- Further candidate04 edits implement current upstream bare-Ref eta conversion,
  preserving nominal direct Ref heads in stuck applications; restrict the live
  unfilled-law guard to Def; and share `mat_rest` between checker and annotation
  to replace a final impossible non-Mat fallback with Efq. These edits require
  the candidate04 genuine-build and paired gates described below before success
  is claimed.

## Genuine candidate and selected evidence

Candidate02 API SHA256:
`3cacbfcac16def0f804d1be0180d3d0aa7fa059cedb5cbd3c24ca542cf33f704`.
It genuinely bootstrapped and checked the complete new Base after the capture
fix. `candidate-02/frontend-paired-02/paired.json` has 88 observations, 86
semantic agreements and 32 exact agreements. The two remaining differences were
future `+Q` acceptance/phase cases subsequently addressed by the prefix work.

Candidate03 API SHA256:
`1f224bce2114db25402f91db506e85612920c2c43107585832776ec2a04f6c1f`.
Assembled source SHA256:
`fa271f071ba639e5b63ebe2cb7adc6b4bb3cd56fba8ab9aaee76e071b8ad6b69`.
It genuinely bootstrapped and checked complete new Base. Its public capsule,
`candidate-03/frontend-paired-01/paired.json`, has **134/134 semantic agreements**,
all explicit fixture verdicts passing, and **53 exact agreements / 81 exact
report or diagnostic differences**. This is selected evidence, not full
conformance. Exact disagreement must not be assumed cosmetic without audit.

The selected harness binds actual B1 API/bootstrap/module identities, current
upstream and Base, frozen host/harness, explicit selection, resource limits,
CPU3, and retained observations. Persistent workers recycle after 32 probes.
No wall time from these correctness runs is a performance comparison.

## Capture diagnosis and direct controls

Candidate01 failed full Base at `Map.put.go`, whose two nested MNode patterns
reuse a constructor telescope. Disposable generated-JS instrumentation recorded
an inner field replacing an outer pending sibling. The evidence is
`map-descent-01/report.json`; it is diagnostic instrumentation, not a checked
compiler or proof artifact. Actual candidate02/03 builds validate the fix.

`lhs-component-04/build-report.json` additionally binds complete frozen
candidate03 source, individual module hashes, stage0 helper, Node, upstream
bend.ts/comp.ts/Base, and output artifact. The upstream checks the complete
Bend source before selecting actual existing `mat_lhs` and `kapply` workers.
This supplemental component is stage0-checked, **not a B1 self-host artifact**.
`lhs-component-04/controls/report.json` passes all seven controls:

1. Nested telescope IDs do not capture a pending sibling.
2. The pending column count changes correctly.
3. Generated IDs are distinct and above the context's maximum ID1200.
4. The outer pending binder survives unchanged.
5. Repeating the same constructor preserves both nested levels.
6. A nullary match preserves the pending sibling.
7. A completed lhs is unchanged.

The fresh-counter proof relies on the existing finite U32 binder-ID-space
invariant. It does not claim meaningful freshness beyond overflow.

## Retained failed or corrected attempts

- `frontend-reference-01`: three positive array fixtures incorrectly supplied a
  second Array type parameter. Frozen original inputs/report remain. Gate02
  corrected them to Array<U32> and passed all 84 observations.
- `frontend-reference-03`: four nested-descent fixture observations pass.
- `frontend-reference-04`: all 46 prefix fixture observations pass.
- `candidate-02/frontend-paired-01`: setup failed before probes because the
  launcher assumed the wrong bootstrap sidecar name. Gate02 uses the actual
  `dist/typed-bootstrap-report.json`; original setup failure remains.
- `lhs-component-03`: sandbox child-process EPERM occurred before compilation.
  Fresh directory04 used the known sandbox exception and passed. Neither result
  was overwritten or relabelled.
- `frontend-reference-05`: a negative duplicate surface-case fixture was invalid;
  the upstream flattener removes a redundant surface row. Frozen inputs/report
  remain. Gate06 changes it to explicit first-class repeated Mat syntax; all
  **26/26 observations** match intended acceptance and rejection phase.

## Boundaries and source accounting

The eight frontend modules changed from 2555 to 2598 physical lines (**+43**).
The initial whole-module qualification change added two lines to graph.bend;
root's subsequent canonical-path changes are separate. Kernel total delta also
includes root declaration pre-seeding and must not be attributed wholly here.
The candidate03 direct-counter replacement reduced its own previous version by
five physical lines. This migration prioritizes correctness and reuses shared
name validation and a shared residual helper; it is not a net line-reduction
claim for the compiler.

A lexically bound empty-call typed-let binder remains a known preexisting scope
boundary: raw parsing lacks the lexical environment needed to accept it exactly
as upstream does. Case/name/field error span parity remains separate from
classification. Compact generalized Lit is not ported here. In particular,
`nat_pattern_deep` exposes the preexisting >256 Nat literal translation into a
U32.to_nat application, while constructor patterns expand into Succ spines.
Structural descent correctly does not unfold an arbitrary function application.
Removing the cutoff or treating a user-redefinable name as a literal would be an
unsafe shortcut; compact literals need a coherent representation change. Long
string/recursive string-literal stress failures likewise remain explicit gaps.

## Follow-up genuine semantic gate

Candidate04 stopped before an API was generated because a separate new loader
helper violated affine usage. The source was corrected in candidate05; the
failed snapshot remains owned by root. Candidate05 API SHA256 is
`9827e7fd58d73ba42f9fbfc48102f2d6d4450dba1cd7dc2a7f9b76b1d957ece8`.
`candidate-05/semantic-paired-01/paired.json` passes all 26 semantic observations,
with 20 exact agreements and six diagnostic/report differences. This validates
bare-reference eta, forward live datatype use, and impossible default checking.

`candidate-05/semantic-execution-paired-01` did not execute: persistent workers
explicitly returned unsupported for interpreter/JS lanes. The immutable attempt
and configuration remain. Corrected isolated attempt02 passes **8/8 exact
output observations** across interpreter and JavaScript: residual default
`Unit{}`, eta-long `6`, mutual type/def `6`, and the explicitly ill-typed but
unreachable fallback `0`. This tests the shared checker/annotation residual
choice through emitted execution, rather than acceptance alone.

## Further bounded false-acceptance fixes, candidate06 pending

The root full candidate03 census found four more frontend/specialization false
acceptances in this agent's scope. A new 32-observation `soundness-cases.json`
includes their exact current-upstream examples and positive controls.

- A final bare `do` statement now retains its header as an annotation. The raw
  parser has no family book, so one private FDo node postpones the expansion
  until normal scope elaboration can distinguish ADT and def families.
- The same node preserves header arguments until the existing datatype quantity
  filling rule can pad them before generating `.bind` and `.pure` arguments.
  It is consumed before core checking; no new core/runtime form is introduced.
- Specialization initializes its existing book with `check_declarations` and
  installs each event with `check_event_install`, sharing the checker's temporal
  visibility model. Future closed arguments still check dead; instances that
  call those future bodiless definitions live now encounter the usual guard.
  Prior definitions, unused erased future arguments and unsafe templates have
  dedicated controls. This replaces the incorrect all-bodies-visible context;
  it does not add per-term chronology metadata.
- The first angle type argument is parsed at comparison precedence so an
  unparenthesized `&`, `|`, or `->` cannot be consumed there. Parenthesized
  compound first arguments, full later comma arguments and ordinary numeric
  comparisons remain controls. This is deliberately narrower than rewriting
  the complete existing angle/comparison parser.

The earlier eight-module +43 line count describes the candidate03 frontend
capsule. These additional helpers and root integration need fresh final source
accounting; do not reuse that count for the final phase release. Additional
literal limitations found by the root full gate include `proof/nat_literal_unfolds`
and `halt/literal_descent_linear`, both part of the deferred representation work.

Candidate06 has now genuinely bootstrapped. The soundness32 reference assumption
gate07 passed 32/32 before candidate comparison.
`candidate-06/soundness-paired-01/paired.json` passes **32/32 semantic observations**
and every explicit fixture verdict; 26 exact observations agree and six retain
diagnostic/report differences. This provides bounded evidence for all four
additional false-acceptance fixes, not a new full-suite conformance count.

The first candidate06 old134 regression attempt must not be counted as a clean
paired gate: while all 134 reference/candidate observations and explicit
verdicts agreed, its reference half detected a changed sibling README in the
fixture directory. The candidate half had unchanged inputs. The harness checks
the full fixture directory, including documentation, and correctly set
referenceSelectedComplete=false. This attempt remains `frontend-paired-01`;
a fresh `frontend-paired-02` rerun uses a frozen fixture directory. No compiler
change caused this invalidation, but the identity failure is not waived.

The clean candidate06 `frontend-paired-02` rerun passes 134/134 semantic
observations and all fixture verdicts with unchanged inputs; 53 exact
observations agree and 81 retain report/diagnostic differences.
Candidate06 API SHA256 is
`e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`;
assembled source SHA256 is
`0f5425ac8a2298f444b0907632088b406da61420407331e80708d9fea6a47822`.

Between frozen candidate03 and candidate06, the delegated follow-up files change
by +15 parser lines, +15 family elaboration lines, +5 specialization lines,
+21 normalization lines and +10 checker lines. Do sugar, scope dispatch and
annotation replacements preserve their physical line counts. The total for
those follow-up changes is **+66 physical lines**; the private FDo marker is
front-end-only, and temporal specialization reuses the existing checker book
model rather than introducing a second chronological representation.

Candidate06 `semantic-paired-01` passes the 26 semantic observations (20 exact,
six report differences). Its `soundness-execution-paired-01` passes **18/18
exact interpreter/JavaScript outputs**, including the earlier eight outputs and
new constructor/padded do headers, prior template targets, unused future erased
arguments and unsafe template instantiation. Across the three clean candidate06
parse/check capsules this is 192 selected observations, plus 18 selected runtime
observations; these are independent from the root full-corpus denominator.

## Maintained component verification

`component-01/report.json` checks all 59 final compiler modules with the pinned
stage0 helper, then passes dependent checker/annotation and structured diagnostic
rendering. It stops at the maintained direct upstream diagnostic-source gate:
6/8 cases have matching error content and source line windows but lack the new
upstream caret ranges. The two deliberately span-independent cases pass. This
is a real remaining compatibility gap, not a stale oracle; no assertion was
relaxed and no production diagnostic source changed during the final full gate.

`component-rest-01/report.json` continues the other 15 maintained groups against
that same checked component, keeping the original failure authoritative. All 15
pass with unchanged inputs: source provenance; native constructor identity;
persistent index; reachability; validated prefix; parsed-source handoff; seeded
loader; binder and declaration freshening; main names; readback; normalization;
specialization; JavaScript primitive ABI; and harness/host ABI safeguards. The
last group contains 52 passing tests. `runner.mjs` retains the exact continuation
commands and `candidate-module-comparison.json` confirms that all **59 component
source-module hashes match genuine candidate06**. This is supplemental stage0
component validation, not B1 or fixed-point proof.

Thus all maintained groups were exercised: **18/19 pass**, with one documented
caret-range compatibility failure. CPU3 was released after these checks. There
are no untested production edits in this agent's scope after candidate06.
