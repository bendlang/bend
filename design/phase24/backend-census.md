# Phase 24: current-image backend census

This is a prospective, bounded measurement of existing behavior. It changes no
compiler module, runtime, release artifact, pinned fixture or oracle. The claim to
test is that the installed Phase 23 compiler's interpreter and CPU backends agree
with the pinned TypeScript implementation on ordinary executable fixtures, beyond
the previously selected backend witnesses. Any new output, phase, diagnostic,
rejection or process failure disproves that claim for its observed row.

The installed API must remain
`5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`,
with upstream `018751270e800bc222a93dad7f257083ee53a5f7`. These are an installed
guarded derivative and its exact reference, not a new compiler build or fixed point.

## Inventory before execution

`selfhost/tools/performance/phase24/backend-inventory.mjs` verifies release-file
hashes and the clean pinned checkout, then uses the maintained inventory rules.
The first inventory contains 1,513 fixtures, 11 supporting Bend modules, 1,016
positive expectations and 497 negative expectations. There are 999 positive mains:

| Lane | Eligible positive observations |
| --- | ---: |
| Interpreter | 999 |
| JavaScript | 833 |
| Native CPU | 812 |
| Total | 2,644 |

These are eligibility counts, not passing tests. The upstream gate exempts
unprintable main types from compiled execution; such a result stays separately
classified. Interpreter IO uses each compiler's JS execution route. Its observation
therefore does not establish pure-normalizer behavior for IO programs.

The four existing frontend fixture failures must also be observed at their actual
later boundary: `io/cid_unknown.bend`, `io/effect_ctr_name.bend`,
`io/main_foreign.bend`, and `reg/array_open_element.bend`. Together they provide four
check observations and ten eligible interpreter/JS/native observations. The earlier
check-stage acceptances must remain visible beside any correct later rejection.

## Acquisition plan

1. Run those boundary rows and a small deterministic cross-namespace pilot. Keep
   every pilot artifact and inspect disagreement before escalating volume.
2. Acquire affordable remaining positive rows in deterministic batches of at most
   64. Keep each batch in one lane to avoid running two copies of the same fixture
   simultaneously against shared temporary filenames. Inspect fixed-path conflicts
   and serialize affected fixtures if the source inventory reveals them.
3. Use the unchanged maintained selected harness and adapters. Run isolated Node 24
   workers with a 4 MiB stack, 4 GiB heap, four jobs, a 30-second per-probe deadline
   and inherited CPU affinity 3–6. Use the already identified Clang 16 toolchain
   for both native sides. This is correctness acquisition under concurrent work;
   its elapsed times are not comparative compiler or generated-program timings.
4. Preserve complete response objects, fixture oracles, command/environment/input
   identities, original raw verdicts, failed outputs and emitted failure artifacts.
   Broad batches may discard successful emitted artifacts only under the maintained
   `retain:failed` policy: their complete observations and exact regeneration inputs
   remain. Independently hash-verify any compressed archive before removing its
   newly produced duplicate tree. Never touch the 103 preexisting unrelated paths.
5. Stop launching broad work at 25 minutes or 300 MiB of new retained evidence,
   with an initial campaign bound of 30 minutes and 350 MiB. Report all unexecuted
   eligible rows; completion of a selected batch is not full backend conformance.

Freeze the actual selection, tools and resource policy before each batch. Root
coordinates the launch against profiling; all backend execution stays on cores
3–6. No deadline is increased to turn a failure into a pass. A failed probe may
receive a separate, retained causal control if it can distinguish a harness or
environment problem cheaply.

## Classification and decision

Report reference and candidate fixture verdicts independently from exact paired
agreement. Distinguish correct execution, expected rejection, unprintable-main
exemption, unknown capability, unavailable Bun foreign runtime, missing host
libraries/devices, timeout, crash, and unexplained compiler differences. The four
check-stage failures keep their original labels. Hardware-gated GPU lanes,
independent proof-kernel validation and external package/hub loading are outside
this census. The inventory has 23 potential GPU fixtures per GPU lane; no device
execution is inferred from CPU results.

If the environment investigation supplies verified Bun, run saved reference JS
under that exact binary as a separately identified environment ablation. Do not
rewrite the original Node result or claim its failure disappeared. A candidate
failure receives source/phase investigation before being called unsupported.

Outcomes, failed attempts, remaining coverage and the most useful next semantic
work belong in `implementation/phase24/backend-census.md`. This plan remains an
immutable prospective input once acquisition starts.
