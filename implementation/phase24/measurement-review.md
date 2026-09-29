# Phase24 final cost measurement review

Independent bounded read-only review of
`selfhost/build/phase24/cost-02/report.json`, the frozen configuration, unchanged
Phase23 matrix/Phase8 worker, variant identities and all15 recorded rows. No new
compiler runs were performed. No measurement blocker was found.

## Result checked from raw rows

| Bundle | Samples | Mean process, s | Mean request, s | Maximum observed RSS, KiB |
| --- | ---: | ---: | ---: | ---: |
| Pinned TypeScript |3|3.737002|2.429041|498,780|
| Released Phase23 |3|11.730025|10.400364|730,352|
| Local lookup guard |3|11.299033|9.971786|727,948|
| Lookup + membership worker |3|11.085634|9.755974|730,492|
| Final combined02 |3|11.156469|9.820528|730,132|

Recomputed changes, with negative percentages meaning lower cost:

| Comparison | Process | Request | Maximum RSS |
| --- | ---: | ---: | ---: |
| Local / released |−3.67426049%|−4.12078918%|−0.32915635%|
| Membership / local |−1.88864967%|−2.16422978%|+0.34947551%|
| Final / membership |+0.63898508%|+0.66168100%|−0.04928185%|
| Final / released |**−4.88963393%**|**−5.57515129%**|**−0.03012246%**|

The same-window process ratio to TypeScript is3.13888662× for the release and
2.98540656× for the final candidate. The combined backend/driver changes cost
about0.64% over the faster membership-only image in this screen; they must not
be presented as another checking speedup. The220KiB difference between release
and final maximum RSS is negligible relative to run-to-run variation: report
memory as essentially unchanged, not a demonstrated reduction.

All final process samples (11.1351–11.1706 s) are below all release samples
(11.6674–11.8118 s). Final request samples (9.8064–9.8457 s) are likewise below
release samples (10.3438–10.4802 s). Membership and local process ranges are
11.0672–11.1106 s and11.2165–11.3817 s. These separated ranges support the
bounded screen result, but three observations per image do not provide a
statistical population guarantee. The earlier local-only screen showed a1.50%
process improvement, versus3.67% here; this variation is another reason not to
promote one small-window percentage into a universal effect size.

## Identity, correctness and timing controls

The final API is
`7b523bdffc0acde702dda1005a5e8201f7b65b2e432d1be95b07f2cfcc0346fa`,
from immutable `combined-build-02`. Every variant checks the identical frozen
Phase21 compiler source, SHA256
`fac061286a2683914244178eb1f9b4dc2fbc2d393560739663e8bd08bbc12996`.
It is the workload, not a claim that the current compiler contains the old
workload's source or declaration count.

All15 worker processes exit0 without a signal, timeout, launch error or output
overflow. Every observation reports CPU0 affinity, input verification and the
expected successful type acceptance followed by unsafe-proof refusal. Rechecking
complete result objects finds exact equality of status, phase, checked,
typeAccepted, proofTrust, unsafeDefinitions, kernelChecked, diagnostic and
compiler exitCode. The harness separately checks each actual host provenance
against that variant's driver/adapter before excluding that metadata from the
cross-host equality comparison. The ordinary compiler observation has1660 unsafe
definitions in every row; no proof-kernel or emission pass is inferred.

The recorded188 canonical src/tools identities per Bend snapshot have identical
membership. Released→local changes only `src/front/declarations.bend`;
local→membership changes only `src/core/term.bend`; membership→final changes
`src/back/native/tables.bend`, `src/back/native/text.bend`,
`src/back/native/tests.mjs` and `src/driver/api.bend`. Runtime, typed driver,
compiler ABI, typed adapter, compiler manifest and upstream Base remain identical.
The reviewed declaration and membership source bytes also match the final
snapshot and present source. This retains the two independently reviewed helper
implementations; public combined-image gates remain separate evidence.

The harness validates each immutable attempt and Base cache before acquisition,
then verifies the same1138-member input union before/after each request. Each
process receives that same union, so identity-hashing work is controlled within
this screen. This review inspected those recorded identities and comparison
logic; it did not rehash every large artifact or reexecute the tests.

Order: TS/released/local/membership/final/final/membership/local/released/TS/
released/local/TS/final/membership. The processes run serially with Node24,
4MiB stack,4GiB heap and180s deadlines on CPU0; the owner reports other compiler
and archive workloads paused. Each Bend image uses its own validated Base cache;
TypeScript loads/checks the same pinned Base. OS caches are not flushed.
Request time includes adapter.probe and lazy API loading; process time additionally
includes startup, input hashing and output capture. Adapter import is recorded
separately from request time. Instrumented CPU/allocation profiles are excluded.

This measures ordinary checking/trust reporting on one large frozen source. It
does not measure emission, generated-program throughput, a complete developer
iteration, broad frontend speed or independent kernel conformance. The current
2.9854× ratio belongs to this acquisition; Phase23's3.10× ratio and other windows
must not be mixed to calculate a speedup.

## Evidence identities

- Final matrix report SHA256:
  `4a5d977b35e7f32e9f1cf018a8f10384bc43188d3597daad61146cfa01c243d5`.
- Frozen cost configuration SHA256:
  `8853e4caca4c00c447ee4a2f5f54b4248d14483337e1babdbea0e77c933384eb`.
- Consumed Phase23 matrix SHA256:
  `4a3bd6052658bfc8bcf4d7bd39acc0de453b9326844d8a51df9b2e6ba1786d1d`.
- Final declaration source SHA256:
  `9e2c8da30605c1b8ab732df5f95533da55a3ea0e6c5a0941f1340586db9d36af`.
- Final membership source SHA256:
  `e9ab994bc3ba4fd5a281e25836911bbc29cafcf2ab0c0284dc9bc097e891fa46`.
