# Upstream migration and conformance

Date: 2026-09-28. Status: checked release installed; final full-corpus and
performance consolidation in progress.
Design: [upstream and conformance](../../design/phase8/upstream_and_conformance.md).

## Preserved starting point

The S4 release was verified before edits. Its API is
`9826ac8f2cb2ad17ab07d7a1f3fcefc701c64cd44d3c50333b3410d761d98b7f`;
source is `75a2de1e9fd7ff995d164eb51594c826091bce92430b09fcd0db9732675880cb`.
59 modules contain 14,667 physical / 12,505 nonblank Bend lines.
`selfhost/build/phase8/baseline/manifest.json` records bytes and identities;
the separate old upstream checkout remains unchanged.

Upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` was merged as
`cda0656`, after committing the design (`bb34b5e`). This is the frozen
2.0.32-era target. Earlier reports retain their old 2.0.21 pin.

## Experiments and failures retained

- Bootstrap adapter attempts 01–03 are retained. Initial fixture mistakes were
  corrected, then 33 controls passed on actual emitted programs. Complete book
  checking, selected private dependencies, export eligibility and TODO/law
  rejection are enforced. Public Nat still uses BigInt, including nested values
  and callbacks; upstream internal Number does not alter the public ABI.
- Unchanged compiler source from `69947fc` bootstraps with the new emitter:
  API `870c5dba8a2a79127eeac6387adee4f376f23ae6bc579772fcaea9671a53d144`.
  Its first new-Base check fails at `Word.Con: undefined name`. This isolates
  bootstrap compatibility from language compatibility.
- Candidate01 declares all signatures and ADTs before checking chronological
  bodies. It bootstraps, then fails at `Map.put.go: nondecreasing self-call`.
  A disposable instrumented artifact identifies a nested-constructor binder-ID
  capture in pending recursion patterns. Instrumentation is debugging evidence,
  never a replacement checked compiler. Candidate02 freshens those telescopes
  before constructing pending patterns and checks the new Base. Candidate03
  retains the same freshness boundary using direct fresh IDs, removing the
  temporary whole-telescope copy and five source lines. It bootstraps and
  checks Base; all134 focused public parse/check observations agree semantically.
  81 exact diagnostic/report differences remain in that capsule.
- Frontend reference attempts preserve initial incorrect array fixture types.
  Corrected controls cover unsafe suffixes, identifiers, fields, lets, arrays,
  first errors, namespace visibility and nested constructor recursion. Whole
  module names are visible for qualification; parser family sugar stays ordered.
- 36 pure harness controls pass. Two live reference selections pass all17 trust/
  validation probes and all3 IO.args execution lanes. The harness uses names from
  fixture files so the new argv[0] contract is actually tested.
- 17 relocated release verification controls pass. Checked B1 has its own
  authentic release path; historical equality-derived release verification is
  retained. Installation does not create bootstrap or fixed-point evidence.
- 18 JavaScript host-effect controls pass for Process.run, thread count and
  command-line behavior. These are runtime controls, not emitted-compiler gates.

## Oracle and inventory corrections

The new checkout contains 1,509 Bend source files under tests, but the upstream
fixture gate selects exactly **1,498** direct namespace fixtures. Eleven nested
files are imported support sources with no independent expectation. Inventory
retains their identities without inventing empty positive oracles.

The gate fixtures contain 1,001 positive expectations, 482 validation negatives,
11 declaration-only proof-trust refusals, and four plain Error expectations.
These categories describe expected observations, not unmeasured candidate passes.

Successful type checking and proof trust are independent observations. Unsafe
executable programs can pass type checking and run; declaration-only books can
pass type checking then return SOME PROOFS FAIL because they rely on unsafe or
foreign code. Every result records typeAccepted/proofTrust/kernelChecked.
No result claims independent Lean validation. The port explicitly declines
--verdict; it does not delegate that request to TypeScript.

## Simplification retained

The S4 source remains the starting implementation: one authoritative structured
checker result, provenance from actual loads, shared graph traversal and useful
list operations remain. Rejected generic binder/evaluator experiments remain
research artifacts. Declaration pre-seeding adds necessary new semantics; it
is not advertised as another percentage reduction. Final source counts, measured
performance, full conformance and installed artifact identities follow after gates.

## Current checked candidate

Candidate03 API:
`1f224bce2114db25402f91db506e85612920c2c43107585832776ec2a04f6c1f`.
Full candidate frontend and changed backend gates are in progress. The new
reference run completed2996/2996 parse/check observations without infrastructure
failures:1001 positive parses,1494 strict check passes and4 deferred-error check
mismatches. A separate14-row execution selection proves the four deferred cases
really reject during emission; they are not four checker defects.

The unchanged-source emitter comparison uses serial CPU0 warm ABBA/BAAB probes,
Node24.18.0,4GiB heap and explicit GC outside timing. Against the old installed
S4 equality derivative, the new genuine checked B1 takes about692ms versus1050ms
for parsing the old Base and28.1ms versus40.8ms for checking60 tiny declarations
(upper-middle of four samples per variant). Results are byte-equivalent at the
API boundary. This is1.52× and1.45× on those two workloads, not a new full-source
TypeScript ratio. Raw rows and recipe: `build/phase8/emitter-comparison-01/`.

Shared CID/FID resolution is implemented once in Bend and consumed by both
backends. Foreign identifier resolution and namespace validation remain compiler
work. Host code supplies foreign file bytes and executes the emitted programs.
Native Base effects are explicitly paired with the retained runtime's compatible
sources, even when the new upstream effect path exists. Only audited byte helpers
were added to that runtime; the new queue representation was not mixed into it.
First actual native thread-count compilation/execution and shared scanner controls
pass. Broader native results remain pending.

The first socket-control run was blocked by the network sandbox and is retained;
the subsequent permitted loopback run passes process/argv/thread/TCP contracts.

## Candidate06 corrections and focused gates

The first full candidate03 run records all2,996 observations with stable inputs.
It has743 exact reference differences,991/1001 demonstrated positive type
acceptances, seven incorrect acceptances among validation-negative fixtures, and
two timeouts. This is the migration baseline, not the final release result.

Candidate06 fixes all seven identified incorrect acceptances: typed and quantity-
padded do headers, chronological template-instance body visibility, duplicate
import aliases, alias ambiguity, imported declarations shadowing Base, and the
first angle-bracket type argument's precedence. Positive controls distinguish
an unused erased future function from a live call through a specialized body.
The do header survives parsing as one private node and is consumed by existing
family/scope elaboration. Specialization reuses the checker's declaration/body
environment instead of inventing a second visibility model.

Canonical module namespaces now derive from real file identity relative to the
entry directory. Different spellings of one import share its namespace and book.
Name freshness is checked before qualification can hide a global collision.
The obsolete user-name restriction on Clo.apply is removed; native closure
application uses BEND_CLO_APPLY, outside emitted user function IDs' FID_ prefix.
Collision detection remains enabled. Actual native and JS controls print False{}
for the upstream user-Clo.apply regression.

Candidate06 passes the maintained21 development controls,134 earlier frontend
controls,32 new soundness observations and the complete import capsule's35
eligible interpreter/JS executions. Exact diagnostic differences remain separate
from those explicitly declared acceptance/phase oracles. The native capsule
passes13 controls including actual C execution, shared foreign CID/FID resolution,
byte-offset effects, Window compilation and user closure naming. See
[native compatibility](native-compatibility.md) and
[selected JS execution](selected-js-execution.md).

Foreign-source namespace resolution now receives reachable effects separately
from the full declaration context. An unused second import sharing a foreign
file no longer causes rejection; two reachable incompatible namespaces still do.
One shared scanner validates CID/FID, and native rendering consumes its parsed
result rather than scanning again.

The first foreign-tag guard was rejected by42 actual execution probes: it also
rejected valid native primitive values. The next runtime passes42/42 after limiting
this check to aggregate conversion that contains Nat, matching upstream's boundary.
A stronger generic-descriptor falsifier then exposed visitation order: parameters
must be considered before suppressing repeated datatype expansion. That correction
has its own subsequent runtime gate. Earlier passing subsets and failed attempts
remain preserved; none is retroactively relabeled complete.

## Explicit remaining scope

Compact literal representation remains a deliberate follow-up. Expanded long
strings can overflow or time out; large Nat conversion applications do not give
the checker upstream's compact-Lit descent/unfolding behavior. Weakening the
termination rule to accept these forms would be unsound and was not attempted.
Imported law fills currently fail early where upstream accepts the types then
reports proof trust. Diagnostic text and some rejection phases still differ.

Native Process compilation requires posix_spawn_file_actions_addclosefrom_np,
which this glibc2.31 host lacks; the actual pinned TypeScript compiler fails for
the same reason. This is an environment limitation. Full Process/file_binary
native fixtures also retain their original bounded timeouts; smaller actual
byte-offset controls establish only their tested contracts. Foreign source
symlink aliases are not fully normalized to realpath at the scanner boundary.
GPU execution, audio and interactive Window behavior are unmeasured here.


## Installed release and source accounting

Release07 is installed as genuine checked B1. Its API is
`e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`;
source is `0f5425ac8a2298f444b0907632088b406da61420407331e80708d9fea6a47822`;
runtime is `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0`.
The API and all59 Bend modules are byte-identical to candidate06. The final JS
runtime corrects the separately demonstrated generic marshalling case; its44
actual execution observations pass. This explicit identity link transfers
candidate06 frontend observations without claiming its older runtime tested the
new boundary. Release07 has its own genuine bootstrap and maintained21-case gate.

The [source inventory](source-inventory.json) records each file's bytes/hash.

| Measure | Preserved S4 | Phase8 |
| --- | ---: | ---: |
| Bend modules | 59 | 59 |
| Physical Bend lines | 14,667 | 14,977 |
| Nonblank Bend lines | 12,505 | 12,779 |
| Bend source bytes | 470,062 | 489,150 |
| Definitions / forward laws / datatypes | 1,433 / 789 / 61 | 1,470 / 790 / 62 |
| Installed generated API bytes | 1,023,803 | 739,211 |

Migration adds310 physical lines; it does not claim another source simplification.
The original16,509-line baseline is still1,532 lines larger (9.28%). Structural
counts are not a subjective count of concepts. The added shared foreign scanner,
declaration/body visibility rule and private do marker directly serve new behavior.
Existing authoritative diagnostics, shared provenance, loaders and persistent
indexes remain. The obsolete ownership worker and duplicate native scanner call
were removed; speculative generic representations remain unpromoted.

All19 maintained component groups were exercised. Eighteen pass, including
kernel/annotation, provenance, index/reachability, prefix/seed caches, freshening,
normalization, specialization, JS primitives and52 harness/ABI tests. The exact
source-diagnostic group fails6/8 cases because caret ranges differ; its original
fail-fast report and unchanged-group continuation remain separate evidence.
See [frontend and semantics](frontend-semantics.md) for the complete chronology.
