# A bounded current-compiler self-emission

Static feasibility review only: no compiler or generated program was executed
for this note. A single current B1→H emission is practical to attempt after the
final comparison and release gates, using the existing checked-library adapter.
Its completion time is unknown. It should remain a separately bounded milestone,
with no automatic second self-reproduction stage or release installation.

## Existing path and exact boundary

[`phase26/emit.mjs`](../../selfhost/tools/performance/phase26/emit.mjs) already
verifies an immutable development attempt, loads its own frozen driver, and calls
`inspect(source, {mode:'library'})`. That runs the Bend source loader, checker,
specializer, reachability, annotation, layout checks and JavaScript emitter. It
writes the complete emitted module plus a provenance receipt and re-verifies
inputs. It does not invoke TypeScript as a fallback. Its request omits a proof
verdict, which avoids unrelated declaration reporting for the compiler's unsafe
implementation functions.

Use the assembled source named by the final attempt's `bootstrapReport.source`,
verified against `sourceSha256`. Do not substitute the small historical
`selfhost/src/compiler.bend` or invoke `tools/bootstrap.mjs`: that script targets
the original pin and an older compiler architecture. The maintained
[`conformance/selfhost.mjs`](../../selfhost/tools/conformance/selfhost.mjs) is
also broader than this task: its default policy automatically runs stages2 and3
and requires equal output. Do not launch it merely to acquire stage2.

For concrete candidate14, the source is
`attempt-14/snapshot/build/typed/snapshots/2e5684356985aaec9148f64c692918335c6753cde091444a24943693fab64dc1/compiler.bend`,
SHA256 `223331981f58cc412f5c4bbc120dd3e8322bac1cfa2b3047536317ad15e43f55`.
Its selected compiler API is `ade96ba48b05ba116430f57e433d8fbdbd76646b61f5e9d53cf34a4c4a9da76d`.
A later final attempt must rebind both identities; these are not aliases for
whatever source happens to be current.

After freezing a fresh output directory and launcher manifest, the minimal child
command from the repository root is:

```sh
env BEND_TYPED_TRACE=1 taskset -c 2 \
  /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  --stack-size=4096 --max-old-space-size=8192 \
  selfhost/tools/performance/phase26/emit.mjs \
  selfhost/build/phase30/attempt-14 \
  selfhost/build/phase30/attempt-14/snapshot/build/typed/snapshots/2e5684356985aaec9148f64c692918335c6753cde091444a24943693fab64dc1/compiler.bend \
  selfhost/build/phase30/self-emission-14-01/stage2.mjs
```

The parent directory must exist; the adapter deliberately does not create it.
The parent selected a **1,200-second process-tree deadline**, CPU2, 8GiB heap and
verified OS stack of at least8MiB for this first bounded attempt. The earlier
static suggestion was600s/4GiB; no execution used it. These are investigation
limits, not a claim that compilation will finish within them. Preserve outer
exit/signal/resource and complete stdout/stderr even on timeout: a killed child
cannot finish its own receipt. Do not extend the deadline or heap automatically.
Keep the trace for phase localization, and classify elapsed time as one acquisition
observation, not a controlled comparison or an emission-only measurement.

## Invoking the resulting compiler

The emitted library exposes `G`, `call`, `list`, `ctor` and a default object of
export wrappers. Library reachability retains the non-Base definitions, including
the compiler loader, checker and emission APIs. The existing frozen
`typed-driver.mjs` recognizes `module.G` and applies
[`compiler-abi.mjs`](../../selfhost/tools/compiler-abi.mjs) to bridge the emitted
positional ADTs to the host's named-field views. No new adapter or handwritten
compiler phase is needed.

Bind `BEND_TYPED_API` to the new stage2 module while keeping `BEND_TYPED_RUNTIME`,
`BEND_BASE` and the driver at the same final attempt's exact frozen paths. In a
fresh process, import that driver and call `inspect` directly. Avoid the CLI
`--check-only` route for this milestone because its separate mathematical trust
verdict can reject unsafe compiler implementation declarations despite successful
type checking. No provenance should describe H as another verified development
attempt: its actual parent is the retained B1→H emission receipt.

A small independent invocation oracle can use:

```bend
import Base

@unsafe
def count(+n: Nat, +value: U32) -> U32:
  match n:
    case 0n: value
    case 1n+p: count(p, U32.add(value, 3))

def main() -> U32:
  U32.add(count(3n, 4294967294), 1)
```

The frozen follow-up design checks this exact fixture through the final B1,
with unchanged bytes. An earlier static suggestion also included a TypeScript
preflight; that extra acquisition is not required by the final bounded plan.
The independent arithmetic result is **8**, from unsigned
32-bit addition. Through H, require `inspect(...,{mode:'library'})` to report
`status:'ok'` and `checked:true`, write the emitted library, import it, and require
`default.main()` to equal8. Also require H's expected load/term/span/check ABI
versions to agree with B1 and a tiny checked Bool/U32 mismatch to reject in the
same check phase. This traverses the real H frontend, ADT bridge, checker and
emitter before executing H's output; a successful module import alone does not.

Freeze separate **90-second child budgets** for Base preparation and the small
positive/negative oracle batch, retaining every failure. A cache created by H is
keyed by H's own hash and must be genuinely validated; copying the B1 cache under
a new identity would invalidate the test. Record whether cache preparation is
included. This oracle deliberately does not compile the compiler a second time.

## Cost evidence and limits

Phase23 and Phase24 explicitly release checked upstream-built Bend APIs plus
guarded derivatives; they provide **no new complete H emission or H runtime cost**.
Phase24's roughly11-second bootstrap and11-second ordinary compiler-source
checking observations therefore do not predict full B1→H time. Its source/pin
also differ from today's source.

Older completed milestones give scale, not a current estimate:

| Historical source | Checked B1→H | H→identical H | Resource / scope |
| --- | ---: | ---: | --- |
| [Phase3](../phase3/report.md) | 704.229s | 1,980.406s | Older complete compiler and pin; separate proof observations |
| [Phase4](../phase4/final-source.md) | 670.766s | 1,591.343s | Node24.18.0, 4MiB V8 stack, 12GiB heap ceiling, one-hour per-stage deadline |

Historical heap ceilings are not measured required memory. Current scalar-region
and Mandelbrot gains cannot be transferred to compiler workloads dominated by
KTerm/record traversal, checking and output construction. A current timeout is
still useful if its trace locates the phase; it is not an optimization regression
unless compared under a separately controlled same-source protocol.

If stage2 and the oracle pass, the defensible claim is: **the final compiler
checked and emitted its own complete source, and that emitted compiler compiled
and ran a small independently checked program**. This does not establish a byte
fixed point, full H conformance, independent kernel validation, faster H execution,
or eligibility to replace the installed compiler. Final release and representative
performance evidence remain the higher-priority gates.

Independent static review found no source/ABI/provenance blocker in the plan.
It specifically requires H's Base-cache receipt to use H's actual API hash and
distinguish newly created from validated-existing cache state. This is a review
of the proposed invocation, not execution evidence.
