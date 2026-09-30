# Fresh final16 frontend observations

Final16 matches the pinned reference exactly on3026 main parse/check observations
and a fresh196-observation broader selection. Both reports have zero behavioral
and additional-result-field differences, healthy workers, unchanged source/artifact
identities, exact fixture paths/oracles and the same upstream pin. These are3222
observations across two selections, not3222 distinct programs or backend tests.

| Selection | Exact observations | Raw outcomes retained |
|---|---:|---|
| Main upstream1513 tests, parse/check | 3026/3026 | 2525 pass,497 observed,4 shared fail |
| Retained broader selection | 196/196 | 195 pass,1 observed |

The four shared main check failures remain failures:
`io/cid_unknown.bend`, `io/effect_ctr_name.bend`, `io/main_foreign.bend`, and
`reg/array_open_element.bend`. Neither the historical reference nor the fresh
candidate is relabelled as passing those expectations. Exact observed agreement
also does not establish complete backend, proof-kernel or accelerator conformance.

The first main gate **failed closed after successful worker acquisition** because
the strict comparator required an identical `compiler.json` hash. Its complete
3026-row acquisition,224.070-second outer receipt and failure are preserved at
`selfhost/build/phase30/frontend-renewal-plan-16/main/` and
`frontend-main16-outer/`. The compiler was not rerun to conceal that failure.

The existing comparator explicitly supports an exact module-layout audit. The
[reviewed amendment](../../design/phase30/frontend-layout-renewal.md) binds the old
60-module manifest and new65-module manifest by exact hashes and ordered lists.
Only JS `u32`, `primitive`, `region`, `worker` and `tree` modules were added;
there were no removed modules or changes to existing relative order. Every
non-module field remains identical: upstream
`018751270e800bc222a93dad7f257083ee53a5f7`, targetVersion2.0.34. No fixture path,
oracle, diagnostic, result field or reference identity was normalized.

Independent review first rechecked all retained rows at
`review-frontend-layout-16-main/report.json`. The derived gate then independently
revalidated the original acquisition's identity, worker health, exact16 API,
all artifacts, all result fields and metadata under that narrow migration at
`frontend-layout-main16/report.json`. The original failed gate remains an input
and an unchanged artifact. Main reanalysis took5.977 seconds and performed no
compiler/fixture acquisition.

The broader196 rows were newly acquired through the same reviewed gate, rather
than reused from another candidate. Its gate is
`frontend-layout-broader16/report.json`; outer acquisition took14.798 seconds.
All paths above are relative to `selfhost/build/phase30/`. The gate derivation,
original consumed tool and explicit migration are retained in
`frontend-layout-tools16/`.

The final API is
`33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637`.
The run used four persistent workers on CPUs4–7 with unchanged30-second request
and30-minute campaign limits. These elapsed times describe conformance acquisition
and reanalysis; no controlled compiler-speed conclusion follows from them.
