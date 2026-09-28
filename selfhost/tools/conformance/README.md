# Full-suite conformance harness

This directory is testing infrastructure, not a compiler. The upstream checkout
is read only, and must match the active manifest pin,
`b2111cf43244e65f76ddc278ee695e669f720cbf`.
Every `.bend` file under upstream `tests/` is discovered recursively, including
imports, foreign effects, proofs, malformed syntax and declaration-only tests.
`#|` lines are the oracle. Namespace names do not determine error phases.

```sh
node --test tests/conformance/judge.test.mjs
BEND_UPSTREAM=/path/to/upstream node tools/conformance/run.mjs
node tools/conformance/run.mjs --adapter /path/to/port-adapter.mjs --output tests/conformance/full-port.json
```

The command returns nonzero unless **every applicable lane** passes on the full
suite. Unsupported capabilities, hardware gates, timeouts, crashes and filters
cannot make an incomplete compiler look complete. The default is the explicitly
unchecked prototype adapter. Its successful JS executions are output evidence,
never evidence of dependent, affine, termination or proof checking.

`--jobs 8` controls concurrency, `--timeout 5000` bounds each entire probe,
`--filter REGEX` selects test IDs, and `--lanes parse,check,interpreter,js,native`
selects lanes. Filters are useful for development but never establish completeness.
Each probe executes in a new process group and temporary working directory;
timeouts kill the group, including subprocesses. Output is bounded to 1 MiB.
Input source remains at its original location so module and foreign paths resolve
normally. Generated artifacts and effect-created relative files belong in the
temporary working directory. GPU probes require explicit `--gpu metal` or
`--gpu cuda`, compatible host hardware, and adapter evidence of GPU execution;
CPU fallback cannot pass a GPU probe.

## Adapter protocol

An adapter ES module exports `name`, `capabilities`, and `async probe(request)`.
Importing it should only inspect configuration, not run the compiler. The request
contains `test`, `lane`, absolute `project`, `upstream`, and `workdir` paths, and
`timeoutMs`. The test includes `id`, absolute `file`, `expected`, `negative`,
`main`, `base`, module imports, foreign imports and backend eligibility.

```js
export const name = 'full-port';
export const capabilities = {
  parse: true, check: true, interpreter: true, js: true, native: true,
  metal: false, cuda: false,
  modules: true, foreign: true, dependentTypes: true,
  affine: true, termination: true, proofs: true,
};
export async function probe(request) {
  // Invoke the implementation under test. Do not return expected fixture text.
  return {status: 'ok', phase: 'runtime', stdout: '42\n', stderr: '',
    exitCode: 0, checked: true};
}
```

Result statuses are `ok`, `error`, `unsupported`, `timeout`, and `crash`. Phases
are `load`, `parse`, `check`, `compile`, and `runtime`. `checked: true` means the
real checker reached this program, including on checker rejection. It must never
be set merely because a parser accepted source or an emitter erased annotations.
`diagnostic` holds rendered language diagnostics; `stdout` holds execution output.
The typed adapter also returns `output`, captured by sharing one file descriptor
between runtime stdout/stderr so their original write order is preserved.
The judge normalizes trailing whitespace just as upstream does and appends
`exit N` on nonzero exit, unless already present. Do not merge unrelated compiler
warnings into program stdout. Nonzero exits never disappear from comparison.

The upstream gate's “check” probe also interprets `main`, so its `Error:` fixtures
can fail during loading, parsing, checking, compilation or runtime. An adapter
should report the actual stage. Every negative requires the exact expected
diagnostic and exit behavior. Matching frontend errors are labeled
`frontend-rejection`, and matching compile/runtime errors have their own labels.
Only `checker-rejection` contributes to the checker rejection count. Successful
checking of declaration-only tests must return upstream's declaration report.

Every fixture with main, including expected failures, receives an interpreter lane.
Expected failures are also compiled when eligible, so runtime-negative programs
are not silently omitted. A check-only acceptance on a runtime-negative fixture
requires phase-specific triage; it is not by itself a checker soundness failure.
Positive fixtures require separate checking and interpreter lanes. Compiled lanes
use the upstream eligibility rules: `import Base`, a `main` declaration and a
matching foreign-language twin where foreign imports exist. The upstream's exact
checked `Error: main's type ... cannot be printed` refusal exempts a compiled
lane; arbitrary unsupported-type errors do not. No whole namespace is excluded.

For separate frontend/core/backend adapters, use `adapters/pipeline.mjs`:

```sh
BEND_CONFORMANCE_FRONT=/path/front.mjs \
BEND_CONFORMANCE_CORE=/path/core.mjs \
BEND_CONFORMANCE_BACKEND=/path/backend.mjs \
node tools/conformance/run.mjs --adapter tools/conformance/adapters/pipeline.mjs
```

The frontend exports `load(request)` returning `{status, program, ...}`. The core
exports `validate({...request, program})` and `interpret({...request, program})`;
validation may return a replacement `program`. The backend exports
`execute({...request, program})`, using `request.lane` to select JS/native/GPU.
Each exports its own `capabilities`. These calls all run inside one isolated
worker, so rich in-memory ASTs need not be JSON-serializable. For upstream's
negative fixtures requiring interpreter/backend diagnostics after checking,
implement the single-module adapter protocol directly.

## Reports and provenance

The JSON report records every discovered source hash, source implementation
inventory, support/effect files, every probe result, timestamps, Node/platform,
adapter capabilities, and prototype compiler/runtime hashes. `complete` is a
strict all-suite verdict. Summaries retain unsupported and gated counts rather
than dropping them from denominators.

`tests/conformance/prototype-baseline.json` is the captured baseline. It used
immutable temporary copies of the dist compiler and runtime, avoiding concurrent
compiler changes during the run. The full report contains exact hashes; those
temporary paths need not exist when reading the report. To reproduce against
specific artifacts set `BEND_CONFORMANCE_COMPILER` and
`BEND_CONFORMANCE_RUNTIME`. To regenerate the human-readable matrix:

```sh
node tools/conformance/report.mjs tests/conformance/prototype-baseline.json
```

## Typed compiler adapter

```sh
node tools/typed-driver.mjs --bootstrap
node tools/typed-driver.mjs --prepare-base
node tools/conformance/run.mjs --adapter tools/conformance/adapters/typed.mjs --timeout 300000 --output tests/conformance/typed-full.json
```

Bootstrap alone invokes the pinned upstream compiler. Normal checks, interpretation,
and both emitters call the generated Bend implementation. `BEND_TYPED_API` and
`BEND_TYPED_RUNTIME` select immutable artifacts for independent runs. Bootstrap
reports preserve the exact module bytes and assembled source in a hashed snapshot.
The Base cache is produced by the new checker and bound to compiler and Base source
hashes. Seeded loading additionally checks canonical Base path and exact source text
in Bend; checking reuses the prefix only after structural equality of every core
field. No names or native flags alone authorize skipping a check.

Each current run writes a `.progress.jsonl` next to its report. A partial progress
file is evidence only for its completed rows and never a complete-suite result.
Historical baseline reports retain their original probe inventory; newer runs also
include interpreter/backend lanes for expected-error fixtures.

Before a long run, `node tools/conformance/freeze-adapter.mjs` snapshots the IO
shell and prints an adapter path for `--adapter`. Use absolute API/runtime paths
and that frozen adapter so concurrent development cannot change a running suite.

## Checked self-hosting fixed point

For an existing successfully emitted compiler seed, the direct gate avoids
repeating its original generation. It runs every ordinary checking and emission
phase, then requires the result to be byte-identical to the seed:

```sh
BEND_TYPED_RUNTIME=/absolute/path/to/frozen-runtime.mjs \
BEND_SELFHOST_DRIVER=/absolute/path/to/frozen-host/typed-driver.mjs \
BEND_SELFHOST_SEED_REPORT=/absolute/path/to/seed-emission-report.json \
node tools/conformance/verify-seed.mjs compiler.bend seed.mjs build/typed/seed-proof
```

The report records both the seed's original host and the verification host,
including the ABI adapter dependency. The condition is `B = H(B, S)` for frozen
compiler `B`, source `S`, and host `H`. The host that originally produced the seed
may differ. Failed earlier attempts remain separate evidence.
Foreign-function metadata embeds canonical source paths. Moving a checkout can
therefore change emitted bytes while preserving behavior; generate a local seed
with the successive-stage runner below before checking a relocated environment.

The self-host runner gives child Node processes a 4 MiB V8 stack and verifies
that the operating-system stack limit is at least 8 MiB. Ordinary CLI commands
retain Node's default stack. The report records the exact resource configuration.
Set `BEND_SELFHOST_STACK_KB` to change this limit (zero uses Node's default).
Set `BEND_SELFHOST_HEAP_MB` to configure Node's old-generation heap limit;
this also appears in the recorded launch arguments. Full compiler annotation can
exceed Node's default 4 GiB heap, so use a host with sufficient physical memory.
`BEND_SELFHOST_RESUME=3` or `4` resumes from existing verified stage outputs;
it verifies canonical source and Base identities, runtime, driver, consumed host
helpers and compiler hashes, and preserves the earlier attempt and log before
restarting. Legacy reports without that provenance cannot resume. A new proof
refuses an existing report directory; a stage with detected input drift cannot
be resumed as a verified predecessor. No checking or emission gate is skipped.

```sh
BEND_TYPED_API=/absolute/path/to/bootstrap-api.mjs \
BEND_TYPED_RUNTIME=/absolute/path/to/frozen-runtime.mjs \
BEND_SELFHOST_DRIVER=/absolute/path/to/frozen-host/typed-driver.mjs \
BEND_SELFHOST_HEAP_MB=12288 BEND_SELFHOST_TIMEOUT=10800000 \
node tools/conformance/selfhost.mjs /absolute/path/to/compiler.bend build/typed/fixedpoint
```

This compiles the same source twice, using the generated stage2 library as the
compiler for stage3. Every stage performs actual checking through the ordinary driver.
The report includes source/runtime/driver/API/output hashes and per-stage logs, and only
reports completion only if both emitted libraries are byte-identical. This is the
fixed-point gate: the resulting compiler reproduces its own bytes from the same
source. `BEND_SELFHOST_REPEAT=1` adds an optional third emission (stage4).
The report distinguishes requested, completed and interrupted attempts. Each stage
has a 30-minute process-group deadline (`BEND_SELFHOST_TIMEOUT` in milliseconds).
An upstream-generated API or successful self-typecheck alone is not this proof.

For an isolated compiler experiment, `bootstrap-variant.mjs REPORT OUTPUT_DIR
MODULE REPLACEMENT` copies and verifies every module in an existing bootstrap
snapshot, replaces only the specified module, assembles the source, and checks it
with the pinned bootstrap compiler. Its resulting API and source can be passed to
the fixed-point runner without changing production source files.

Compare two complete recorded runs with:

```sh
node tools/conformance/compare-artifacts.mjs BEFORE.json AFTER.json COMPARISON.json
```

The tool requires the same pinned revision and fixture hashes. It compares
verdict, rejection phase, checked flag, exit code, diagnostic and output, ignoring
timing and compiler/toolchain identity. Only the exact upstream checkout prefix
is normalized. Every changed or missing probe is retained; negative check rows
are listed separately. Matching observations do not establish intended-rule
coverage for previously unproven negative cases, or turn GPU hardware gates into
execution evidence. Keep both source reports alongside the comparison.

For long runs, fixtures may be partitioned into disjoint `--filter` groups and
run with the same artifact, host, pin and timeout. Retain every raw group report,
then combine them with:

```sh
node tools/conformance/merge-reports.mjs MERGED.json SHARD_1.json SHARD_2.json ...
```

The merger requires every inventory probe exactly once. It rejects missing or
duplicate probes, changed artifacts, differing inventories, hosts or timeout/GPU
policies, and unfinished reports. It preserves every verdict and records input
report hashes. `coverageComplete` means that every probe was observed;
`complete` retains the runner's stricter conformance condition. Merging cannot
turn timeouts, diagnostic mismatches, or hardware gates into passes. Do not mix
initial attempts with retries to select favorable results.

Self-emitted compiler libraries can require a larger JavaScript stack on large
books. `--stack-kb 4096 --heap-mb 4096` passes those limits to each isolated
compiler worker; zero (the default) preserves Node's defaults. Setting flags on
the runner alone does not propagate them to workers. Reports record the exact
worker flags, and the merger refuses groups with different limits. The OS stack
must be larger than the requested JavaScript stack (8 MiB in the phase 1 run).
These settings do not change per-probe deadlines. The explicit stack and
old-space settings propagate to generated Node programs; other Node flags do not.

## Fast selected differential loop

Use a previously **checked** Bend API instead of rebuilding or self-emitting the
compiler for each test. `target.mjs` runs live pinned TypeScript and the selected
Bend artifact through the same worker, deadline, inventory, and judge protocol.
It freezes the harness and typed host for the attempt. Supply a fresh output
directory; existing evidence is never replaced.

A configuration file uses paths relative to itself:

```json
{
  "upstream": "/absolute/pinned/upstream",
  "api": "/absolute/checked/api.mjs",
  "bootstrapReport": "/absolute/checked/api.mjs.bootstrap.json",
  "runtime": "/absolute/runtime.mjs",
  "cpu": 2,
  "timeoutMs": 30000,
  "stackKb": 4096,
  "heapMb": 4096,
  "cases": [
    {"id": "base/list_sort.bend", "lanes": ["check", "js"]}
  ]
}
```

```sh
node tools/conformance/target.mjs config.json build/selected/attempt-1
```

The API, bootstrap report, assembled source, source modules, and Base must match
the recorded checked build. The runtime is an explicit, separately hashed input.
The command does not bootstrap. After changing compiler source, create a fresh
checked API with the existing bootstrap workflow and point the next attempt at
its report. The report records total selected-run wall time; it excludes a build
that happened beforehand, which must be added when measuring edit-loop latency.

The reference adapter calls unmodified pinned TypeScript APIs for loading,
checking, ownership/TODO gates, pure interpretation, and emission. It implements
the CLI's declaration report and `PROOF.bend` import policy as host orchestration.
Node executes emitted JS with the same explicit resource flags as the Bend host.
An effect that actually requires unavailable Bun is unsupported; GPU execution is
unsupported. The native output lane uses the configured CPU C toolchain. No
candidate compiler is substituted into the reference. Dirty tracked upstream
source or fixtures fail the pinned-inventory check.

`paired.json` reports both oracle verdicts and compiler agreement. Its
`selectedComplete` requires every selected probe to pass its oracle on both
implementations and agree semantically. `complete` remains false: selected probes
never establish full language conformance. Exact diagnostics are also compared
and listed separately. Timeouts, crashes, unsupported lanes, hardware gates,
missing probes, and changed inputs or artifacts prevent a selected pass.

For small local witnesses, provide `file`, a distinct `id`, and either `#|` lines
in the source, an explicit `expected` string, or an explicit acceptance oracle:

```json
{"id":"local/late-template", "file":"late-template.bend",
 "accept":false, "rejectPhase":"parse", "lanes":["check"]}
```

Acceptance-only witnesses support parse/check probes and do not claim diagnostic
identity. Rejected witnesses require the declared phase, exit code, and checker
flag where appropriate. A runtime or parser error cannot satisfy a checker
rejection oracle. Positive check witnesses require actual check-phase acceptance.
Exact diagnostic differences can coexist with `selectedComplete` for these
explicit acceptance oracles; they remain visible in `discrepancies`. Built-in
upstream fixture oracles cannot be replaced by custom acceptance metadata.
A `selection` filename can replace the inline `cases` array.

To rerun failures, set `rerun` to the previous **candidate conformance report**.
Without a selection, only prior failures are selected. With a selection, previous
failures run before the requested controls. Every attempt records the preceding
report hash. Fixture identity changes, unknown/duplicate/ineligible pairs, and
empty selections fail. Reruns are distinct attempts, never a merge of favorable
observations into a full-suite pass.

The underlying runner also accepts these features directly:

```sh
node tools/conformance/run.mjs --adapter tools/conformance/adapters/typed.mjs \
  --selection cases.json --retain failed --selected-exit 1 \
  --output build/selected/candidate.json --jobs 1 --timeout 30000
```

`--retain none|failed|all` preserves selected worker requests, responses, bounded
streams, generated artifacts, and replay commands. The paired runner defaults to
`all`; the ordinary full-suite runner retains its historical `none` default.
`--selected-exit 1` controls the exit status only; it never changes full-suite
`complete`. Exact replay requires unchanged recorded inputs/tools, the same Node
executable/version, and the recorded allowlisted compiler configuration:

```sh
node tools/conformance/replay.mjs RETAINED_WORKDIR/request.json
```

Replay creates a new sibling work directory and preserves the original failure.
Its metadata is an exact-path replay, not a portable copied reproducer. Foreign
host toolchains and external runtime services still require the corresponding
recorded environment; their complete installation is not bundled with a replay.

### Explicit native compiler adapter

`adapters/native-graph.mjs` executes the Bend compiler natively and tests its
emitted **JavaScript lane**. It advertises no parse/check-only, interpreter,
native-output, or GPU lane; there is no implicit JS compiler fallback. Configure
`candidateAdapter` plus `candidateEnvironment` with `BEND_NATIVE_BINARY`,
`BEND_NATIVE_RUNTIME`, and `BEND_NATIVE_MANIFEST_DIRECTORY`. Each selected fixture
requires a versioned graph manifest at `DIRECTORY/FIXTURE_ID.json`, for example
`DIRECTORY/base/list_sort.bend.json`. Its main file must match the selected fixture, and its canonical Base path must
match the pinned reference `bend2/base.bend` (a relocated copy is not silently
substituted into this paired comparison). Each dependency and asset logical path
must also resolve to the supplied physical file. Legitimate filesystem symlinks
are allowed; explicit remapping to a different dependency is rejected even when
the bytes happen to match. Standalone graph compilation supports such remaps,
but a paired comparison must use the reference filesystem identities.
Missing manifests are unsupported. The manifest lists all available modules and
foreign assets explicitly; the adapter never discovers imports in JavaScript.
See [the native graph host guide](../performance/rapid/native-graph.md) for the
manifest/build boundary. The adapter records native compilation provenance and
Node execution separately.
