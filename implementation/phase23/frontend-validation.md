# Phase23 frontend validation

The final installed compiler (`combined-build-03`, derived API
`5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`)
agrees exactly with upstream
`018751270e800bc222a93dad7f257083ee53a5f7` on **3026/3026** main frontend
observations and **196/196** retained broader parser observations. Both final
identity/health/exact-agreement gates pass, with zero changed behavioral fields.
The [final summary](frontend-final.json) binds all four reports, images and worker
statistics, including the preserved first combined compiler checkpoints.

## Fresh reference and first candidate checkpoint

[frontend-gate.mjs](../../selfhost/tools/performance/phase23/frontend-gate.mjs)
uses the immutable checked attempt's harness to acquire both sides freshly.
The main selection contains all1513 direct upstream Bend fixtures in parse and
check lanes. The broader selection preserves the exact Phase22
`context-group196-05/selection.json` cases and their oracles.

Both gates completed with unchanged fixture, compiler, runtime, Base, host,
harness and target-manifest identities. Every worker recorded zero timeouts,
failures and errors. The comparison checks exact paths/oracles, verdict/evidence,
status, phase, checked/acceptance/trust/kernel flags, unsafe definitions, exit,
diagnostic, stdout, stderr, output, error, signal and reason. Unknown result keys
fail closed. Candidate-only `files`, `sourceFile` and `hostProvenance` are retained
and independently checked against the hashed source/artifact registry; they are
not falsely presented as metadata also exposed by the TypeScript adapter.

| Gate | Exact agreement | Raw reference and candidate statuses |
| --- | ---: | --- |
| `frontend-main-01` |3026/3026|2525 pass,497 observed,4 fail|
| `frontend-broader-01` |196/196|195 pass,1 observed|

The main lanes remain parse1016 pass/497 observed and check1509 pass/4 fail.
The four check fixture verdicts are `io/cid_unknown.bend`,
`io/effect_ctr_name.bend`, `io/main_foreign.bend` and
`reg/array_open_element.bend`. Both frontends accept these before the later
emission error expected by their complete-program fixture oracle. Accordingly,
main reference, candidate and paired `selectedComplete` remain false. The
separate identity/health/exact-agreement gate passes; no raw report is rewritten.
The broader acquisition has `selectedComplete:true` on both sides.

All15 added upstream fixtures, including both depth32 conversion regressions,
are included in the3026 observations. This gate establishes tested frontend
agreement, not execution-backend agreement, independent kernel validity,
universal language equivalence or a self-hosted fixed point.

Acquisition used four persistent workers per side, recycling after64 requests,
CPU affinity4–7,4MiB stack,4GiB heap and30seconds per probe. The full fresh pair
completed in294.4seconds while other authorized work ran on other cores; this is
an observed validation-loop duration, not a controlled compiler speed comparison.
All requests, worker histories, file-backed launch output and raw results remain
under `selfhost/build/phase23/frontend-{main,broader}-01` for the central Phase23
preservation bundle.

## Final-source gate policy

[frontend-gate-v2.mjs](../../selfhost/tools/performance/phase23/frontend-gate-v2.mjs)
accepts an explicit previous reference gate. It verifies that gate passed with
stable identities, that pin/selection/path/oracle inputs match exactly, and that
all reference inputs/artifacts still hash identically. It then runs a fresh
candidate using the final immutable attempt and rechecks both sides' identities.
The report labels reference reuse and links its original acquisition; it does
not synthesize a new reference run or replace original histories. Final gates
`frontend-main-02` and `frontend-broader-02` both completed and passed using
`combined-build-03`. They independently rehash the original reference inputs,
artifacts and result report before and after the new candidate run. Main is
3026/3026 exact and broader196/196, with zero worker timeouts/failures/errors or
identity changes. All extra behavioral fields and candidate metadata audits pass.

The main candidate rerun inherited CPU2 for four workers, completing in670.4s;
the broader rerun inherited CPU2–5. These functional runs used different resource
allocation from checkpoint01 and establish no speed comparison. The original
reference/candidate histories are preserved; only the new candidate was run for
these final gates. Raw main statuses still retain all four later-emission fixture
failures, while broader remains195 pass/1 observed. The artifact hashes and
resource boundaries are recorded in `frontend-final.json`.
