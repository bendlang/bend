# Phase16: compact compiler release

The installed compiler checks the same final compiler source **2.48× faster**
than Phase15: **30.58→12.36 seconds**, with **62.70% less peak RSS**. Pinned
TypeScript takes **3.61 seconds**, leaving a **3.42×** process-time gap. Exact
frontend differences fall **459→2** with no lost matches. All **42 installed and
relocated CLI checks pass**. This is a usable release with known gaps, not full
language conformance.

The [frozen consolidation plan](../../design/phase16/compact-final-gates.md)
sets the integration boundary. The [chronological report](full_conformance.md)
retains intermediate results and failures. Raw paths below are relative to
`selfhost/build/phase16/`; the [preservation plan](compact-evidence/PLAN.md)
describes the bounded topic capsules and their recovery procedure.

## Selected artifact and use

| Identity | Value |
|---|---|
| Target upstream | `b2111cf43244e65f76ddc278ee695e669f720cbf` |
| Checked attempt | `compact-final-build-01` |
| Final assembled source SHA256 | `a2b63a62684822f57731f7d09de96bf2d78ea62dcb58b08a020d3e88a20adf1c` |
| Genuine checked parent SHA256 | `83113283980375efc9cbb3911c4b3df03d18f4cb8066133ea14597df20b98458` |
| Installed API SHA256 | `35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315` |
| Previous Phase15 API SHA256 | `b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d` |

The API is the maintained guarded version5 derivative of a genuine checked B1.
The transformation, embedded runtime and pinned Base bytes are unchanged. This
does not establish another self-emitted fixed point. Ordinary compilation uses
the Bend implementation without a TypeScript fallback.

From `selfhost/`, with Node 24 or newer:

```sh
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
```

The [compiler guide](../../docs/BEND-IN-BEND.md) covers checking, interpretation,
JavaScript/native emission and rebuilding. [Architecture](../../selfhost/docs/ARCHITECTURE.md)
documents the source/host contracts. The [release manifest](../../selfhost/dist/release.json)
binds source, host, runtime, checked lineage and installed bytes. The previous
release and original lineage remain in `selfhost/dist/release-history/`.

## Why the compiler became faster

Literal expansion was creating large trees that later phases copied, freshened,
validated and encoded. `KLiteral` keeps Nat, U32, F32 bits and string payloads
compact and supplies a one-step constructor view when needed. The earlier
same-source structural census falls from **2,171,045 to 152,620 freshened terms**
(**92.97% fewer**), while retaining all **150,871 located terms**. Its complete
constructor/list JSON falls from **337,202,666 to 25,324,867 bytes**. Those counts
belong to the earlier source identities in the
[literal experiment](checker-compact-literals.md), not the final timing source.

Correctness required retaining distinctions hidden by the old expanded form:

- `KLambda` explicitly records whether quantity was supplied. Absent and explicit
  `Many` cannot be conflated in checking or specialization keys. Structural
  operations preserve presence; normalization/backend paths match the pin's
  intentional removal. No presence flag was added to every ordinary term.
- Specialization uses the pinned canonical JSON identity, including lexical
  binder depth/names, optional quantity, reference offload marking, UTF-16 size,
  escaping and signed-zero F32 bits. The existing 32,768 size and 64-depth guards
  remain. Source positions and binder IDs cannot stand in for semantic identity.
- Literal-vs-constructor distinctions survive until the operation that needs
  their semantic view. Ordinary and marked empty-call patterns use authoritative
  scope rules, including datatype precedence and lexical bindings.

See [lambda presence](lambda-quantity-presence.md),
[canonical keys](checker-canonical-memo-json.md) and
[pattern integration](pattern_integration_validation.md). Compiler concepts grew
to represent missing semantics; the gain comes from removing repeated runtime
work, not compressing source text.

## Controlled final comparison

`compact-final-matrix-01/report.json` records six fresh processes in
**TS/B/C/C/B/TS** order on CPU0, stack 4 MiB / heap 4 GiB, Node 24.18.0. All intentional
compiler and archive jobs were closed. All six accept types and produce matching
expected proof-trust refusals with identical unsafe-definition sets. The table reports two-sample means and the
maximum child RSS observed for each image.

| Image | Process wall | Request wall | Maximum RSS |
|---|---:|---:|---:|
| Pinned TypeScript | 3.6108 s | 2.3597 s | 479,176 KiB |
| Phase15 | 30.5837 s | 29.4155 s | 1,745,756 KiB |
| Final Phase16 | 12.3570 s | 11.2655 s | 651,156 KiB |

Process time falls **59.60%**, request time **61.70%**; the same-window TS gap
falls **8.47×→3.42×**. Each image checks the identical final assembled source.
The entire two-file host delta is reviewed and hashed in
`compact-final-host-review-01/phase15-review.json`: `typed-driver.mjs` carries
the contextual loading/term/cache capabilities and `workflow.mjs` validates
the new cache contract. This measures the complete selected workflow, not an
identical-host compiler-only ablation. Bend uses separately validated Base
caches; TypeScript checks Base. OS caches are not flushed.

Request time wraps `adapter.probe`, including lazy API loading; adapter import
is outside that interval. Process wall also includes startup, hashing and output
capture. Emission is excluded. Two samples on one workload/machine do not predict
all programs, developer builds or generated-program execution speed. The earlier
prototype **2.87× /3.58× TS** result used a different source/window/baseline and
must not replace this final release measurement.

## Conformance and release gates

| Final-image gate | Result | Raw evidence |
|---|---|---|
| Full frontend | 2,996 observations; 459→2 differences; 457 new/0 lost | `compact-final-frontend-01` |
| Maintained build selection | 36 controls;two inherited exact gaps | `compact-final-build-01` |
| Expanded integration | 197/198 exact;one known instance chronology gap | `compact-final-checks-01` |
| Selected backend | 41/41 exact, pinned Clang16 | `checker-compact-final-backend-01` |
| Literal semantics /execution | 176/176 and 20/20 exact | `checker-compact-final-literals-01`, `checker-compact-final-execution-01` |
| Instance /growth boundaries | 29/29 and 2/2 exact | `checker-compact-final-instances-01`, `checker-compact-final-growth-01` |
| Canonical key probe | 61/61, including 20 UTF-16 size boundaries | `checker-compact-final-key-direct-01` |
| Pattern preservation | 114 unchanged results;6 direct demand controls pass | `marked-pattern-integration-audit-01.json`, `marked-pattern-integrated-demand-01` |
| Supplied-source /host lifecycle | 39/43 controls;one known wording gap in each | `compact-final-context-supplied-01`, `compact-final-context-host-01` |
| Namespace /term-cache /program-host | 8/39/10 controls pass | `compact-final-context-namespace-01`, `compact-final-term-host-01`, `compact-final-program-host-01` |
| Historical request order | 226 paired complete results identical | `compact-final-history-01` |
| Maintained derivation | 16 unchanged groups; five authentic v1–v5 replays | `compact-final-helper-01` |
| Standalone loader | 25 modules; unchanged raw/traced/seeded controls pass | `compact-final-standalone-01` |
| Installed /relocated CLI | 42/42 pass | `compact-final-smoke-01` |

The full inventory has 1,498 fixtures: 1,001 positive accepts, 482 validation
refusals, 11 trust refusals and four later-emission expectations. All measured
primitive outcome axes agree. Strict checks are 1,493 pass / 5 fail: four
later-emission expectations and `check/monad_do_destructure.bend`. The latter
accounts for both remaining exact frontend differences (parse/check).

The raw marked-pattern selection remains **`pass:false`**, with 71/114 exact and
43 known differences. Its sole strict failing check is that same monad fixture.
The separate 114-row integration audit establishes unchanged outcomes and no
regression; it does not turn those differences into full conformance. Supplied
source/host gates retain one `@unsafe` followed by import wording difference.
These selections overlap and must not be summed into a unique test count.

The canonical-key probe appends four named wrappers to the **unchanged full
915,713-byte production API prefix**, with a distinct recorded probe hash. It
tests compiled helper bodies without changing production exports; it is not
itself the installed API. [Probe provenance](checker-compact-final-key-probe.md)
and [checker gate report](checker-compact-final-gates.md) bind the exact evidence.

Histories preserve the original 53/60 requests, resources, predecessor order and
complete result objects. Both wave9 and final APIs use the same reviewed final
compatible host with separately prepared Base caches; historical host changes
are explicit. No provenance fields are stripped. There is no new crash or
timeout. The old 21-case prefix can overflow earlier releases; the maintained
selection keeps the long string first. These finite histories do not establish
universal stack safety.

## Size, boundaries and installation

`compact-final-source-counts-01.json` counts the ordered 59 compiler modules:

| Metric | Phase15 | Phase16 | Change |
|---|---:|---:|---:|
| Physical Bend lines | 15,288 | 16,345 | +1,057 (+6.91%) |
| Nonblank lines | 13,059 | 13,947 | +888 |
| Bytes | 503,048 | 581,177 | +78,129 |
| Definitions | 1,499 | 1,656 | +157 |
| Laws | 790 | 775 | −15 |
| Type declarations | 63 | 66 | +3 |

Declarations are proxies for complexity, not a formal count of concepts. The
main added contracts are explicit spans, module parsing context, compact
literal/lambda representation and whole-program checking completion. The source
remains larger; the historical 50%/75% reduction targets are unmet.

Capabilities are termABI1, spanABI3, loadABI1 and check-resultABI2. Base cache
version 6 binds these to compiler/Base/path/book identities and validates ranges.
Unknown advertised capabilities are refused; old no-capability fallback paths
retain explicit controls. Contextual loading discovers headers/dependencies in
order, parses each uncached body once and runs one graph finalizer. CheckerABI2
returns the already materialized book and checks live instances before final
TODO/open-law completeness; same-body instance error order remains a gap.

`promotion-01` stops before copying source because it applies a canonical-path
required verifier to valid file/SHA-only gate identities. `promotion-02` corrects
that schema issue, then stops on the raw marked-pattern partial result. Neither
copies source. `promotion-03` retains that raw failure and explicitly verifies
its known scope plus the separate unchanged-outcome audit, all other final
gates, complete source membership and release identities. It copies 39 changed
source/host files and preserves the previous release. All 75 unrelated Phase6
files retain their original hashes. All three tools/reports remain immutable.

Independent BendTT validation, hub/package fetching, GPU/interactive-device
coverage and general backend equivalence remain outside the demonstrated scope.
Source Nat payloads remain U32-sized; wider runtime values use a separate
representation. Native Process is blocked by a missing host libc symbol for
both this compiler and upstream. No proof-soundness claim follows from the
passing fixtures. See [CONFORMANCE.md](../../selfhost/CONFORMANCE.md).

## Next experiments

Keep the installed release stable while isolating parser checkpoint semantics
and profiling its remaining costs. A raw-body group marker can preserve the
flattening boundary needed by general error chronology; it does not directly
fix the monad tuple or same-body instance cases. The latter requires a separate
checker/specializer ordering investigation. Use cheap exact witnesses before
another whole-corpus gate, and the current compact image before estimating
further speed gains. Do not reuse allocation percentages from the old expanded
representation as the current profile.

Publication remains blocked by the earlier automatic approval review of the
push. Local installation and validation do not imply a successful remote push.
