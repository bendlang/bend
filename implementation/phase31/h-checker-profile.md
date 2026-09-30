# Inside one H17 checker invocation

The new profile supports removing generic call and constructor-matching layers
around structured compiler data. It does **not** identify garbage collection or
ABI conversion as the main sampled cost, and it does not establish that a
particular token check or allocation is responsible for a runtime frame's time.

The [prospective design](../../design/phase31/h-checker-profile.md) follows the
successful [outer attribution](h-attribution.md). One fresh H17 process runs the
same three ordinary small library requests, profiling only the second after one
warm request. All three outputs and full observations match the existing oracle;
all frozen inputs and the actual-hash Base cache remain unchanged. The child
exits successfully within its 90-second deadline. Acquisition runs on CPU 2
and may overlap correctness work; no clean timing claim follows.

## Samples and their boundaries

The V8 profiler uses a 1,000-microsecond interval and records 6,636 samples for
the whole second request. Monotonic trace timestamps select **5,230 samples**
within the exact `check_program_diagnostic` invoke→decode interval. The selected
interval is 6,331.177 ms of instrumented wall time, not a new benchmark result.
The analyzer verifies that V8 start/end timestamps fall between the corresponding
`process.hrtime` anchors and that the selected checker boundaries lie inside
that profile. No guessed clock offset is applied.

| Sampled self frame/category | Samples | Share of selected samples |
| --- | ---: | ---: |
| `apply` | 1,343 | 25.68% |
| `invokeExact` | 587 | 11.22% |
| General constructor matcher callback | 309 | 5.91% |
| Single-constructor matcher callback | 225 | 4.30% |
| `force` | 428 | 8.18% |
| `callOwned` | 174 | 3.33% |
| `project` | 155 | 2.96% |
| `get` | 147 | 2.81% |
| Garbage collector | 145 | 2.77% |
| `stringEq` | 119 | 2.28% |
| `fields` | 95 | 1.82% |

These are single-run self-sample observations. `apply`/`invokeExact` are call
sites and include work the profiler assigns there; their shares do not isolate
individual guard expressions. `force` performs both constructor scheduling and
trampoline execution. Allocations can cost time outside the garbage collector.
The two matcher categories are identified by exact H17 source lines and
callbacks, not guessed from anonymous function names.

Inclusive sampled stacks provide useful source leads: `check` appears in 70.7%,
`ki_match_arm` in 39.2%, `check_node` in 34.2%, `infer` in 29.8%, and
`lookup_cached` in 22.3% of selected samples. These percentages overlap and
must not be summed. Trampolines remove some logical callers and JIT attribution
can obscure others. The raw report retains every frame's function, URL, line,
column and source excerpt, together with separate self and inclusive tables.

## A smaller next experiment

Use the existing H17 graph and a bounded generated-code derivative to test a
**private record/lookup worker**, preserving the original record fields and
force points. The first ablation should replace known internal helper calls
without changing record layout. The second should remove one repeated match or
projection/copy chain after proving its inputs cannot expose getters, proxies,
shared mutable field vectors or descriptor changes. Replay existing lookup
results and complete graph observations, not only a checksum. Confirm any
surviving change on a second structural helper before changing the emitter.

This target is supported by both shared runtime frames and the sampled lookup
chains. It is more specific than adding an interner merely because Zig has one,
and tests whether the current local-region strategy can extend beyond scalar
and local-array kernels. The current profile alone gives no defensible speedup
estimate for that extension.

Source inspection also finds that `check_program_diagnostic` currently ignores
its `validated` argument and calls `dg_check_world(book)`, which constructs a
checking world and iterates definition events. That fact motivates a separate
semantic-reuse investigation, but does not authorize skipping Base definitions:
world dependencies, specialization, fresh identifiers, event order and errors
must be accounted for. No cache or checker shortcut was implemented here.

## Preservation and resource deviation

V8 produced a **53,551,733-byte** call-tree profile, exceeding the prospective
40 MB artifact cap. This resource bound failed even though functional checks
passed. No samples were discarded and no substitute run was selected. The
original was compressed, independently decompressed, compared byte-for-byte,
and reread unchanged before its redundant uncompressed copy was removed.

- Original profile SHA: `d224aef34880334dd667c887484eaba261d25b3953000126e8dc1dfab349d81c`.
- Gzip: 1,875,086 bytes, SHA `3589a4d36fb8dcb0874e7d5599cb622641d71eb859a453e47705267d917ed035`.
- Restore: `gzip -dk profile.cpuprofile.gz` in the run directory.

All artifacts are in `selfhost/build/phase31/h-checker-profile-plan-01/` and
`h-checker-profile-run-01/`: original/derived worker, exact four-replacement
patch, plan, full trace, process receipts, complete profile in gzip,
`profile-summary.json`, and `profile-storage.json`. The original analyzer is
retained as `consumed-profile-summarize.py`; restore the raw profile before
replaying it. No compiler or runtime edits were made by this profiling task.
