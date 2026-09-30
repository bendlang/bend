# Renew exact frontend evidence on the selected Phase30 image

Prepare this optional final-image gate prospectively; do not run it during the
exclusive generated-program or ordinary-compiler timing windows. Bind candidate
attempt12 now, and rebind to a new immutable directory if a later image wins.
Never relabel old frontend observations as a fresh acquisition.

Use unchanged `phase23/frontend-gate-v2.mjs`, which accepts an explicitly
attested existing reference gate. The references are
`selfhost/build/phase23/frontend-main-01` and `frontend-broader-01`, acquired on
upstream `018751270e800bc222a93dad7f257083ee53a5f7`. The broader selection remains
exactly `selfhost/build/phase22/context-group196-05/selection.json`.

The main gate acquires all1513 fixture paths in parse/check lanes:3026 fresh
candidate observations. The broader gate acquires196 observations from the
retained additional selection. Before and after acquisition the runner verifies
the reference gate, pin, fixture paths, oracles, source hashes, compiler/runtime/
Base identities and reference artifacts. It records reference reuse explicitly;
only candidate execution is new. Unknown result fields fail closed. Behavioral
fields compare exactly, while candidate-only file/host provenance is separately
verified. No result normalization or diagnostic exception is added.

Use four persistent workers, recycling after64 requests,30s per request,
4MiB stacks,4GiB heaps and the maintained30-minute outer limit per gate. Freeze
affinity as4,5,6,7 through `PHASE23_FRONTEND_CPU`, with unrelated CPU acquisitions
paused during the run. This is functional validation, not a throughput claim.
Run main then broader serially. The Phase24 candidate renewal took287.98s and
8.96s respectively on its recorded four-CPU affinity0,1,2,7; budget6–10 minutes
here, with no promise that that historical duration predicts this run exactly.

Require all expected observations, stable input/host identities and zero worker
timeouts/failures/errors. Require3026/3026 and196/196 exact agreement for success.
Preserve raw status totals. In particular the four known main check fixtures
`io/cid_unknown.bend`, `io/effect_ctr_name.bend`, `io/main_foreign.bend`, and
`reg/array_open_element.bend` are accepted in the frontend before the later
emission error expected by their complete-program oracle. If unchanged, record
the shared four failures and `selectedComplete:false`, together with the
separate passing exact-agreement gate. Do not hide or reclassify those rows.

This is why the attested exact-comparison runner is used instead of treating
generic workflow `--fullFrontend`'s strict raw-status exit as the complete
conformance decision. If any actual behavior differs, retain full failed
evidence and inspect it before any release claim. The sweep remains frontend
agreement with the pinned implementation; it does not certify all execution
backends, independent kernel correctness, universal equivalence or a new
selfhost fixed point.
