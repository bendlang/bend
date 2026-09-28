# Upstream migration and conformance

Date: 2026-09-28. Status: **validated migration checkpoint installed**.
Design: [upstream and conformance](../../design/phase8/upstream_and_conformance.md).

The default compiler now targets upstream **b2111cf43244e65f76ddc278ee695e669f720cbf**,
after Bend2 2.0.32. It accepts 997/1,001 positive fixtures and fixes all seven
incorrect validation acceptances found during migration. The validated S4
simplifications remain; rejected generic binder/evaluator prototypes remain out.
Full equivalence and a new self-hosted fixed point are not claimed.

One usable checked release is installed, committed and verified after relocation.
Use the [compiler guide](../../docs/BEND-IN-BEND.md), or from `selfhost/`:

```sh
npm run verify:release
node cli.mjs tests/conformance/typed-smoke/base-u32.bend --run
npm run build
```

Full self-checking remains expensive: 205.26s versus 2.80s for pinned TypeScript,
**73.20× by process wall** on the controlled checking workload. This excludes
emission and is not the historical 6.03× full-compilation comparison. The short
checked-build/21-case development attempt takes about 27s. See
[checking cost and controls](checking-cost.md) before interpreting these numbers.

## Installed artifact and provenance

| Artifact | SHA-256 |
| --- | --- |
| Checked API | `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4` |
| Assembled source | `0f5425ac8a2298f444b0907632088b406da61420407331e80708d9fea6a47822` |
| Final JS runtime | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Canonical new Base | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

Release07 has its own whole-book upstream bootstrap and maintained focused gate.
Its API, all 59 Bend modules, driver and frontend adapter are byte-identical to
candidate06, which produced the full frontend vector. Only the JS runtime changes
between those artifacts; the final combination is explicitly retested on 44
foreign execution observations. The [transfer identities](frontend-conformance-evidence/frontend-transfer-identities.json)
make this connection explicit without relabeling old runtime evidence.

The stage0 helper checks the complete source book, rejects holes and validates
selected export eligibility before emission. Private dependencies retain full
book context. Public named-field data, nested BigInt Nat and callbacks pass 33
actual bootstrap/ABI controls; upstream internal Number Nat does not justify
changing the public ABI. Historical equality-derived release verification remains,
but the new body-sensitive transform has not been validated and is not applied.

The [release manifest](../../selfhost/dist/release.json) binds installed source,
API, Base, runtime and host. Original bootstrap reports remain byte-for-byte;
relocation verification checks local identities without inventing bootstrap
provenance. The preserved S4 release and old 6018e28 checkout remain historical
controls. Ordinary compilation runs Bend-generated code without TypeScript
fallback. `--verdict` is explicitly unsupported; no result claims Lean validation.

## Final conformance

All 2,996 observations paired against the new live pinned reference, with no
missing rows or changed inputs. [Detailed classification](frontend-conformance.md)
separates type acceptance, proof trust, error phase, exact text and execution.

| Result | Candidate03 migration baseline | Final API |
| --- | ---: | ---: |
| Positive parses | 999 / 1,001 | 1,001 / 1,001 |
| Positive type acceptances | 991 / 1,001 | 997 / 1,001 |
| Invalid acceptances among 482 validation negatives | 7 | 0 observed |
| Determinate validation refusals | 474 / 482 | 481 / 482 |
| Validation-negative timeouts | 1 | 1 |
| Exact paired parse/check differences | 743 | 734 |
| Strict check passes | 995 | 1,002 |
| Strict check failures / timeouts | 501 / 2 | 494 / 2 |

The fixture gate contains 1,498 direct namespace fixtures, plus 11 nested support
files without independent oracles. It adds 121 paths, removes 1 and shares 1,377
with the old pin; 510 common files changed and 867 are byte-identical. All 913
current positive fixtures on common paths accept; 84/88 added positives accept.
This is new-target testing, not old-language compatibility inferred from names.

Among 11 declaration-only proof-trust refusals, seven reach the proper refusal
phase and three agree exactly. Four imported-law fills fail prematurely during
parsing. All four deferred-emission error fixtures accept types in both compilers;
separate reference execution controls establish their later errors. Exact check
differences (536) plus parse differences (198) total 734; diagnostics are not normalized away.

The seven fixed incorrect acceptances are typed and quantity-padded do headers,
live use of a later definition through template specialization, duplicate import
aliases, aliases shadowing Base names, imported declarations shadowing Base, and
first-angle-argument precedence. Six previously rejected positive fixtures now
accept: forward datatypes, eta conversions, unreachable fallback handling and
canonical respelled imports. The obsolete user-name ban on Clo.apply is removed.

## Relevant validation

- Genuine checked build and 21 maintained paired development controls pass.
- All 192 focused frontend/semantic/soundness observations pass their declared
  acceptance/phase oracles; exact diagnostics remain separately reported.
- All 18 semantic interpreter/JS outputs and 35 eligible import/JS outputs pass.
- The final API/runtime combination passes 44 foreign execution observations,
  including the generic Nat marshalling falsifier demonstrated on old runtime02.
- Native/scanner capsule passes 13 controls, including actual C execution,
  thread count/channel closures, namespaced CID/FID, binary offsets, Window
  compilation, user Clo.apply and reachable foreign-source ownership.
- All 19 maintained component groups ran: 18 pass. The source-diagnostic group
  fails 6/8 cases due to missing upstream caret ranges. Original fail-fast results
  and unchanged-group continuation are retained; the oracle was not weakened.
  The final component harness/host ABI group passes 52 tests.
- Release verification controls pass 17 positive/adversarial cases. Installed and
  minimal relocated CLI checks pass 30 steps: integrity before/after, version 2.0.32,
  checking, interpreter, emitted JS and actual CPU binaries. Arithmetic returns 42
  and user Clo.apply returns False{}. The relocated package has no upstream
  checkout and no BEND_* overrides.

Some selections overlap. Their counts must not be added as unique programs or
used to infer broad backend equivalence. Details:
[frontend semantics](frontend-semantics.md), [harness](conformance-harness.md),
[JS execution](selected-js-execution.md), [native compatibility](native-compatibility.md).

## Simplification and source accounting

The [per-file inventory](source-inventory.json) counts only manifest-listed Bend
compiler modules. [Supporting changes](supporting-changes.json) separately records
host/tool, runtime and test code through the installed checkpoint; generated
runtime bytes are not counted as additional handwritten implementation.

| Measure | Preserved S4 | Phase8 |
| --- | ---: | ---: |
| Modules | 59 | 59 |
| Physical Bend lines | 14,667 | 14,977 |
| Nonblank Bend lines | 12,505 | 12,779 |
| Bend source bytes | 470,062 | 489,150 |
| Definitions / forward laws / datatypes | 1,433 / 789 / 61 | 1,470 / 790 / 62 |
| Installed generated API bytes | 1,023,803 | 739,211 |

Migration adds 310 lines; it does not claim another source reduction. The original
16,509-line baseline is still 1,532 lines larger (9.28%). The generated API is
27.80% smaller. Structural counts are not subjective concept counts; historical
50% and 75% line targets remain unachieved.

Existing authoritative errors, provenance, shared loaders/lists and persistent
indexes remain. Signature/datatype visibility is separated from chronological
body installation; specialization reuses that environment. One private do marker
is consumed by existing scope/family elaboration. Canonical module namespaces
use real identity relative to the entry directory. One Bend CID/FID scanner serves
both backends, with reachable effect scope separate from full name-resolution
context; native rendering reuses the scan. The obsolete ownership worker and
duplicate scanner invocation were removed. Native closure dispatch uses
BEND_CLO_APPLY outside the user FID_ namespace, retaining collision validation.

## Failures and corrections preserved

The prior release was verified before editing: S4 API
`9826ac8f2cb2ad17ab07d7a1f3fcefc701c64cd44d3c50333b3410d761d98b7f`,
source `75a2de1e9fd7ff995d164eb51594c826091bce92430b09fcd0db9732675880cb`.
Design `bb34b5e` preceded upstream merge `cda0656` and implementation `ff3d5b2`;
installed release checkpoint is `a9f6593`. The old reference checkout was not changed.

- Unchanged S4 source builds with the new emitter, then rejects new Base at
  Word.Con. Candidate01's declaration migration reaches a nested-constructor
  capture at Map.put.go. Disposable instrumentation locates it; candidate02
  freshens binders and checks Base. Candidate03 replaces the temporary whole-
  telescope copy with direct fresh IDs, removing five lines.
- Candidate04 fails an affine-use error in the new path helper; candidate05
  corrects it. Candidate06 includes semantic/import/foreign-scope fixes, and
  release07 adds the separately validated runtime generic-parameter correction.
- Initial foreign-tag validation rejects valid native primitives: 42 probes find
  34 failures. The next runtime passes 42, then a stronger generic-type falsifier
  exposes a visitation-order bug. The final runtime passes 44, and preserved
  runtime02 demonstrably fails the new fixture under actual execution.
- Earlier bootstrap/reference fixture mistakes, an unsupported execution-worker
  configuration, a documentation-induced input-drift rejection, sandbox socket
  failure, native timeouts and the collector's changing-input refusal remain.
  Corrected attempts do not overwrite these records.

## Remaining work and evidence

Four positive literal gaps remain: string_literal_descends times out,
string_literal_long overflows the stack, and nat_pattern_deep/nat_literal_unfolds
receive false termination refusals. The negative literal_descent_linear times
out. Compact literal support should address the representation, not weaken the
termination checker. Imported law fills and exact diagnostics are separate gaps.

Full checking is dominated by the Bend checker in the retained coarse profile.
The historical equality optimization needs a fresh adaptation/validation against
new generated code; no speculative speedup is credited. Large generic evaluator
and binder rewrites remain rejected. Native flat-layout/host experiments are not
silently promoted across the changed upstream runtime boundary.

Native Process requires a libc symbol absent from this glibc 2.31 host; actual
pinned upstream compilation fails for the same reason. Full Process/file_binary
native caps remain recorded; smaller byte-offset witnesses prove only their
contracts. Foreign source symlink aliases lack full realpath normalization.
GPU, audio and interactive Window execution remain unmeasured.

The [migration evidence index](migration-evidence/README.md) retains exact source,
APIs, requests/results, logs, emitted programs, failed attempts and verification.
Separate [reference/harness](conformance-harness-evidence/README.md) and
[JS execution](selected-js-evidence/README.md) capsules are reused by identity.
P8-001/P8-002/P8-003 decisions and the ledger preserve the hypothesis history.
No bootstrap success, installed manifest or selected pass is relabeled a new
B1→H→H proof.
