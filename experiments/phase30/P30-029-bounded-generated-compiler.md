# P30-029 — One bounded self-emission and a small generated-compiler request

Owner: phase30_analysis; independent reviewer: phase30_review. The root authorized
one B1→H acquisition with a1200-second child cap, then bounded ABI/cache/small
functional gates. The [original design](../../design/phase30/bounded-self-emission.md)
and [schedule amendment](../../design/phase30/self-emission-schedule-amendment.md)
preceded execution. The later [warmed-request design](../../design/phase30/warmed-generated-compiler-cost.md)
is a separate controlled comparison, now completed with its own clean grant.

**Claim and invariant.** Final16 can emit its exact attested assembled source and
the resulting H can use the existing frozen driver/positional ABI, genuinely
check Base under H's own hash, and reproduce an independent positive8/negative
checking oracle. No H→H, fixed-point, installation or full H-conformance claim.
Stop on any failed phase or resource deadline; retain it without retry/budget
increase. The generated compiler remains a derived artifact, not a fake attempt.

**Observed gate.** All phases passed: B1 preflight3.606s, B1→H emission30.841s,
syntax0.202s, H Base/ABI20.427s, H oracle17.624s; complete supervisor78.530s.
Emission peak child RSS was927172KiB. H is2,446,321bytes and has SHA
`21b53c697c7dce78bb2d7ee2977dc77659fc9f9c66878f54106a8509987001ab`.
H's actual-hash Base cache was created, then validated unchanged in the oracle.
Full positive/negative observation fields and the small emitted JavaScript bytes
match B1. ABI load2/term1/span3/check2 passes through the maintained adapter.

**Measurement scope.** This acquisition ran onCPU2 with an8GiB V8 heap allowance
and4MiB V8 stack; the heap allowance is not a total-RSS limit. It overlapped
correctness work and therefore supports no controlled performance ratio, including
against historical self-emission times. Request/child/verification boundaries and
resource receipts are in the [implementation report](../../implementation/phase30/bounded-self-emission.md).

**Frozen discriminator.** The independently reviewed small cost experiment compares
H with the genuine TypeScript-produced JavaScript parent of the same Bend source,
not with the upstream TypeScript compiler. Separate preparation binds actual API-
specific caches, byte-identical output and result8. Three alternating fresh-process
trials each use one warm request plus two timed library requests; the real
H ABI conversion remains inside the normal request boundary. Only a separately
granted clean window establishes the scoped result below. No steady-state inference.

The first preparation reached successful genuine-parent cache creation and exact
emission, then failed because Node pipe capture returned EPERM. Its report and
consumed worker are retained. Preparation16b uses the already successful H-oracle
file-descriptor capture in a new immutable plan; this repairs the host launcher,
not compiler behavior. Both16b preparations pass with actual-API-specific caches,
the independent expected JavaScript hash and result8. No measurement was obtained
from the failed preparation, and these overlapping preparation durations are not
a performance comparison.

**Separate controlled result.** Three fresh-process trials per side pass all18
warm/timed output hashes. Median two-call means are1460.836ms for the genuine
parent and7609.354ms for H, a5.2089× ratio. Parent trial means span1460.465–
1463.649ms; H spans7563.196–7658.775ms. Parent's second timed request is still
11.11–11.51% faster; H's is4.39–5.92% slower. This is the fixed warmed-once small
request through the real driver/ABI, not converged throughput or a comparison
against the upstream TypeScript compiler. The [cost report](../../implementation/phase30/warmed-generated-compiler-cost.md)
retains all six trials and boundaries; raw measurement is
`generated-compiler-cost-measure16b/report.json`. No speed ratio is inferred from
the earlier overlapping self-emission or preparation durations.

**Preservation and decision.** Keep H as a functional experiment artifact only.
Raw plan, emitted compiler, checked receipt, every child stdout/stderr and cache/
oracle result are under `selfhost/build/phase30/self-emission-plan-16/`; small-cost
metadata is under `generated-compiler-cost-plan16b/`. The14 self-emission plan remains
unexecuted. Tools/designs/reports are tracked; the parent-owned final campaign
capsule must preserve the ignored raw evidence before this becomes a durable
checkpoint. No additional selfcompile or H promotion is selected.
