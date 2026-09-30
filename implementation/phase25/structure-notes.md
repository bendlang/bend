# Phase25 static generated-JavaScript analysis

Status: complete for the acquired 23 paired sources /46 generated modules. This
is an AST/source census, not a runtime benchmark, compiler optimization or new
conformance claim. Execution validation and timing belong to the campaign report.
The [compact summary](structure-summary.json) includes every case, module identity,
section count, priority owner, exact source range and short source excerpt.

## Parser, API and evidence

The [tool](../../selfhost/tools/performance/phase25/structure.mjs) loads Node24.18.0's
embedded **Acorn8.16.0**, parses complete ECMAScript2025 modules, and never imports
or executes an analyzed module. It records parser source SHA256
`2261c5f0e4abe860e889dfc67081683a4ba4d27deb7f4cbc8ad06a1b7fdd510c`.
There is no regex-tokenizer fallback. Missing parser, unreviewed parser version,
invalid JavaScript, unknown emitter family, split/ambiguous boundaries, mismatched
module/runtime hashes and changed manifest/input bytes fail closed.

```sh
taskset -c 6 /home/ai/.nvm/versions/node/v24.18.0/bin/node --stack-size=4096 \
  selfhost/tools/performance/phase25/structure.mjs \
  --manifest selfhost/build/phase25/corpus-01/manifest.json \
  --out selfhost/build/phase25/NEW-structure.json
```

Outputs are created exclusively; a prior observation is not overwritten. The
manifest is `{entries:[{id,variant,family,path,runtimePath,sourceSha256,sha256}]}`;
paths resolve relative to the manifest. `family` is `upstream` or `selfhost`;
`runtimePath` is optional for upstream. A single module accepts `--file FILE
--variant NAME --family FAMILY --out NEW.json [--runtime FILE]`. Programmatic
exports are `analyzeFile(config)` and `analyzeCorpus({entries})`.

The complete final report is [gzip compressed](evidence/structure.json.gz), with
[raw/compressed identities and an exact round-trip receipt](evidence/structure-receipt.json).
It contains 57,357,962 raw bytes, compressed to3,173,913 bytes. The raw SHA256 is
`5e9390ab4430f37468cc23f49815ef587c52e9605f622e380944e76378204322`.
The new uncompressed duplicate was removed only after byte-for-byte recovery.
Unzip to a fresh path to inspect per-function metrics and all recurring groups.

An initial report omitted the multi-constructor `matcher` from its named-helper
vocabulary; `matcher1`, source sizes and raw AST counts were unaffected. Its
[report](evidence/structure-01.json.gz), [exact tool](evidence/structure-tool-01.mjs)
and [supersession receipt](evidence/structure-01-receipt.json) remain preserved.
The final vocabulary counts both matcher forms and recognizes their initial
runtime arity1. Historical counts must not silently mix these revisions.

Tiny synthetic controls exercised nested closures, strings/regexes containing
marker-like punctuation, exact runtime prefixes, wrapper separation, arity-site
accounting, source-hash rejection, duplicate identity rejection, mismatched source
hashes and repeated-prefix deduplication. The recorded 22 comparisons passed on
the pre-corpus tool. The final full-corpus audit independently verified every
byte partition and that common+remaining AST metrics exactly reconstruct each
program section. Temporary synthetic-control paths are not durable evidence;
these scope-limited development checks are separate from the archived corpus.

## Scope of the counts

All counts are **static syntax sites**, not allocation counts or execution
frequency. Every byte belongs to a disjoint runtime/prefix, generated program,
metadata, foreign-support, export-wrapper or entrypoint section. Leading trivia
belongs to its following statement and final trivia to the preceding section.
A section's metric tree visits each AST node once. Per-function metrics exclude
nested bodies but retain the nested function creation site. Function byte sizes
include nested definitions and therefore must not be summed as disjoint bytes.

Selfhost requires exact equality with the supplied copied runtime prefix.
Upstream's actual `// Program` comment supplies its boundary; without a supplied
runtime file, that prefix is explicitly labelled **runtime-and-foreign**, because
upstream can insert foreign effects before this marker. All23 upstream modules
here have the same3,546-byte prefix. All23 candidate modules share the exact
42,878-byte runtime. Prefix totals are deduplicated by hash in the summary.

Library exports are separate: upstream emits an explicit object of public
non-IO exports; the candidate wraps `Object.keys(G)`. These ordinary library
contracts are not identical sets of roots. In particular, the candidate can
retain IO-main/show support absent from the upstream library. The validated
`bench(size,seed)` calls are the execution boundary; whole-library size is a
different observation and must not be described as just the hot kernel.

An additional48 whole named candidate registrations, including their guards,
are byte-identical in **every** corpus module:14,763 statement bytes/module.
They include `Word`, `Pair`, `IO`, and IO/channel/file/network/window/audio
registrations. They are labelled **corpus-common generated definitions**, not
inferred source ownership. The comparison excludes them explicitly when reporting
remaining units. Remaining units can still contain Base helpers or unused public
roots; they are not automatically source-owned kernel code.

The host-boundary control makes the distinction concrete:

| Byte category | Upstream | Candidate |
|---|---:|---:|
| Complete module |3,729|63,162|
| Copied runtime/prefix |3,546|42,878|
| Constructor/show metadata |0|5,271|
| Corpus-common named registrations |0|14,763|
| Remaining program statements |56|78|
| Program trivia |1|49|
| Export wrapper |126|123|

The large cold/static footprint is mostly support code. It does not establish
that an individual `bench` call executes those registrations or allocates their
closures; many are guarded by `Object.hasOwn` and can be skipped.

## Priority generated owners

The following are actual top-level definition/registration units. Candidate
`pop`/`key` units include their lifted `F` helpers. Lines refer to restored
`selfhost/build/phase25/corpus-01/CASE/SIDE.mjs`; full module SHA256 and byte ranges
are in the summary. Counts include all syntax in that unit, including nested
closures; they do not report executed events.

| Case | Emitted owner | Bytes | matcher /matcher1 | fn | call /jump | for loops | Start line |
|---|---|---:|---:|---:|---:|---:|---:|
| scalar-arithmetic | upstream `$spin$` | 495 | 0 / 0 | 0 | 0 / 0 | 1 | 178 |
| scalar-arithmetic | selfhost `spin` | 371 | 1 / 1 | 2 | 6 / 1 | 0 | 597 |
| boolean-worker | upstream `$step$` | 646 | 0 / 0 | 0 | 0 / 0 | 1 | 178 |
| boolean-worker | upstream `$spin$` | 646 | 0 / 0 | 0 | 0 / 0 | 1 | 211 |
| boolean-worker | selfhost `spin` | 244 | 1 / 1 | 2 | 2 / 1 | 0 | 596 |
| boolean-worker | selfhost `step` | 257 | 1 / 1 | 1 | 6 / 0 | 0 | 597 |
| match-remaining-args | upstream `$digest$` | 381 | 0 / 0 | 0 | 0 / 0 | 1 | 188 |
| match-remaining-args | selfhost `digest` | 288 | 1 / 1 | 2 | 3 / 1 | 0 | 596 |
| pinned-u32-table | upstream `$pop$` | 60 | 0 / 0 | 0 | 0 / 0 | 0 | 162 |
| pinned-u32-table | selfhost `pop` | 65,562 | 463 / 495 | 464 | 0 / 0 | 0 | 599 |
| pinned-u32-wide | upstream `$key$` | 235 | 0 / 0 | 0 | 0 / 0 | 0 | 162 |
| pinned-u32-wide | selfhost `key` | 12,019 | 85 / 91 | 86 | 0 / 0 | 0 | 601 |

**Dense U32 cases become a table upstream and a word-matcher tree in the candidate.**
Upstream `pinned-u32-table/upstream.mjs:162` is exactly:

```js
function $pop$(_n_0) {
  return TAB_0[Math.min(_n_0, 16)];
}
```

The separate68-byte table declaration at line183 contains17 values, including
the default100. Thus the60-byte function does not include its table's cost.
The candidate's65,562-byte block starts at `selfhost.mjs:599`. It contains463
`matcher`,495 `matcher1` and464 `fn` sites, with lifted `F` functions and repeated
`False`/`True`/`WCon`/`WNil` patterns. This is a large lowering difference on the
same pinned fixture, not merely a runtime-prefix difference.

**Wide U32 cases similarly preserve primitive comparisons upstream.**
`pinned-u32-wide/upstream.mjs:162` compares the input with0,3000000000 and
4294967295 (plus a low-bit guard) and returns the corresponding constants.
The candidate's `key` block starts at `selfhost.mjs:601`, with85 `matcher`,91
`matcher1` and86 `fn` sites. Its12,019 bytes compare with235 for upstream `key`.
The [runtime](../../selfhost/src/runtime.mjs) makes the representation cost explicit:
`fields("U32",x)` and `project("U32",x)` call `word(x)`, which builds32 `WCon`
nodes plus `WNil`. Dynamic diagnostics must establish how often that path runs;
source alone does not establish its total allocation share.

**Scalar arithmetic uses direct JS operators inside the upstream loop.**
`scalar-arithmetic/upstream.mjs:178` has one loop, with `Math.imul`, `>>>`, `^`
and `+` in its body. Candidate `selfhost.mjs:597` instead contains calls to
`get(G,"U32.add")`, `get(G,"U32.xor")`, `get(G,"U32.mul")` and related helpers,
inside matcher arms and a recursive jump. Its371-byte unit is *smaller* than
the495-byte upstream loop. Size alone cannot explain or predict runtime cost.

**A match can split a logically multi-argument call into staged generic dispatch.**
Upstream `match-remaining-args/upstream.mjs:188` receives two arguments and loops.
The candidate's complete `digest` registration at `selfhost.mjs:596` is:

```js
G["digest"]=matcher("Nil",()=>fn(1,function(a){const x3432=a[0];return x3432;}),()=>matcher1("Con",()=>fn(3,function(a){const x3433=a[0];const x3434=a[1];const x3435=a[2];return jump(call(get(G,"digest"),[x3434]),[call(get(G,"U32.add"),[call(get(G,"U32.mul"),[x3435,33,]),x3433,])]);})));
```

The recursive `call(...,[rest])` returns a function consumed by the outer jump.
This is observable staged dispatch. It is not automatically an underapplication:
the initial runtime matcher has arity1. The report's apparent under/equal/over
sites use known initializer syntax and leave zero-arity thunk/dynamic cases
unresolved; they are not a proof of the actual callee's arity after evaluation.

**The Boolean worker source idiom reaches different capabilities in the two emitters.**
`boolean-worker/upstream.mjs:178` and`:211` are loop/state workers for `step` and
`spin`. Candidate `selfhost.mjs:596–597` retains matcher and generic-call chains.
The source idiom that improved the upstream-built compiler image does not
therefore establish equal lowering in the compiler's own user-code backend.
This distinction matters when moving from compiler throughput to emitted-program
performance.

## Interpreting recurring shapes and next evidence

The normalized shape hash preserves AST control structure, operators, helper
names and property names, while erasing ordinary identifier/literal spelling.
It is deliberately **not alpha-equivalence**, scope/capture analysis or permission
to fuse/reorder code. Byte-identical corpus-common definitions are separately
identified before reasoning about case-specific patterns. Repeated occurrences
across files are not necessarily independent optimization opportunities.

The next discriminating evidence is dynamic helper counts and CPU/allocation
profiles on the same preserved modules: word reconstruction versus numeric
operations, staged matcher application, closure creation and jump handling.
Any proposed native U32/literal specialization must preserve builtin provenance,
default cases, wide/wrapping values and custom constructor behavior. A direct
worker must preserve evaluation order, partial/overapplication, closure capture
and deep-stack behavior. None of those implementation changes is made here.
