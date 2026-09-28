# Upstream migration and conformance

Date: 2026-09-28. Status: implementation and validation in progress.
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
