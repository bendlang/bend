# Compact literals: 2.87× faster ordinary checking

The [planned comparison](../../design/phase16/compact-literal-cost.md) is healthy:
the combined compact-literal prototype checks identical compiler source in
**10.7300 s versus 30.8339 s** for wave9, a **65.20% process-time reduction**.
Pinned TypeScript takes **2.9962 s** in the same window. The measured gap falls
from **10.29× to 3.58× TypeScript**. Request time falls 67.54%, and peak RSS falls
65.20%. This is a single-workload prototype result, not a release claim.

| Image | Process samples (s) | Mean process (s) | Mean request (s) | Peak RSS (KiB) |
| --- | --- | --- | --- | --- |
| Pinned TypeScript | 2.954, 3.038 | 2.9962 | 1.9220 | 444,804 |
| Wave9 | 30.909, 30.759 | 30.8339 | 29.6544 | 1,709,868 |
| Literal/context union | 10.713, 10.747 | 10.7300 | 9.6248 | 594,960 |

All six fresh-process rows pass ordinary checking and trust reporting with equal
unsafe-definition sets. The order is TS/B/C/C/B/TS on CPU0, with a 4 MiB stack and
4 GiB heap. All three agents confirmed their compiler/probe jobs were closed,
root's integration gates had finished, and no new jobs or archive work ran until
the matrix closed. Bend uses a separately validated checked Base cache per image;
TypeScript checks Base. Process time includes startup, hashing and capture;
request time includes lazy API loading. OS caches were not flushed.

The baseline is `wave9-build-01`; the candidate is `literal-context-build-01`,
API `b74f5bf5767e2fd9f9db0a47943afe07c3e167e6bd7e049a406dfcb387f82527`.
Both consume the exact assembled wave9 source named and hashed in the
[machine-readable summary](compact-literal-cost.json). The complete host delta
was reviewed before timing: literal transport, payload/range checking and cache5
identity in typed-driver, plus its cache verifier in the development workflow.
All other host bytes and membership, Base, runtime and reference pin agree.
The candidate also includes the small constructor-scope correction, so this
measures that combined implementation rather than a pure literal-only ablation.

The main finding is structural: expanding scalar strings and words into nested
constructors caused later whole-tree operations to repeatedly process millions
of avoidable nodes. The independent identical-source census finds 2,171,045
freshened terms before compact literals and 152,620 afterward, while retaining
all 150,871 located terms. Compact values preserve literal identity and defer
constructor expansion until an operation needs that view. The term counts and
the timing are separate measurements, with separate source identities; neither
is substituted for the other.

This integration preserves all 2,996 main-suite primitive outcomes and the same
two exact differences as wave9, with zero lost matches. Its independent controls
have 197/198 exact matches and all 176 literal observations are exact. Earlier
isolated literal gates also cover direct semantics, host/cache validation,
41 maintained backend rows and 20 additional JS/native literal executions.
Those isolated backend controls do not replace final combined-image gates.

The maintained compiler grows from 16,038 to **16,142 physical lines** (+104),
13,766 nonblank lines, 567,765 bytes, 1,633 definitions, 776 laws and 66 types in
59 modules. The combined delta adds one literal variant, eleven literal helpers
and one constructor-scope helper, not a source-size reduction. It replaces a
large runtime representation with a compact one at a modest source cost.

Promotion remains blocked on known syntax-sensitive memo identity and growth
limits. The next candidate retains explicit Lambda quantity presence and uses
one exact pinned JSON encoding for both memo identity and the 32,768 UTF16-unit
guard. That final image needs the saved growth/history counterexamples, frontend,
backend, CLI and another controlled timing gate. No generated-program runtime
speedup, new self-hosted fixed point, kernel or GPU claim follows here.

Raw evidence: `selfhost/build/phase16/compact-literal-cost-01/{matrix.json,host-review.json}`,
`compact-literal-matrix-01/report.json`, `literal-context-frontend-01/report.json`,
`literal-context-checks-01/report.json` and `literal-context-literals-01/report.json`.
The summary tool rehashes every matrix input before recording the result.
