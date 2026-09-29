# Inert parser cursor ablation

Prospective freeze before source changes. Parent is the installed Phase17
find-worker-source-01/project, genuinely checked by find-worker-build-01, API
9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6.
No installed or Phase17 file will change. All source/tool/output paths are new
Phase18 cursor-* snapshots, with complete parent/delta membership and consumed
plans/tools preserved.

Introduce FInput{tokens, context} and FCursorContext{serial:U32}. Production entry
points create one inert context with serial0; this serial has no parsing meaning
and exists solely to make preservation observable in independent controls.
Cursor readers unwrap it. f_tl preserves the context on advance and returns the
same empty cursor at EOF. Prepend and empty helpers preserve it. f_skip/f_space
skip using unchanged raw-list helpers and allocate at most one final wrapper.
Raw lexer/token output stays unchanged; lexer accumulator peeks use raw helpers.
No name resolution, lexical scope, freshness, grammar, diagnostic or public
loader/checker ABI change is part of this candidate.

Change FParsed.rest from token list to FInput, keep its two-field shape and all
ordinary callbacks' argument counts. Mechanically change cursor type annotations
outside lexer.bend, adapt the five synthetic-token sites and five empty-rest
exits, and wrap the four lexer-to-parser entry boundaries. No later compiler
pass is removed. Keep context inert, and stop if behavior changes are needed to
make the representation compile.

Frozen gates: genuine checkedB1 plus unchanged maintained36; the exact saved196
Phase17 group selection on this parent and candidate, requiring identical
normalized outcomes (raw suite may remain false); unchanged raw and complete
lowered Base and assembled-parent-compiler books; direct cursor readers,
advance/prepend/empty, skip-vs-space, legacy/indexed EOF, all synthetic token split
paths (++/>>/<-/->), diagnostic endpoints and several nonzero context serials.
Error cursor propagation and lexer projections must also preserve the context.
Direct probe APIs are separate files whose prefix is byte-identical to the
production API and whose suffix only exports existing compiled functions. Their
identities may never substitute for the production artifact. Any allocation
instrumentation is a second separately identified artifact, not a timed compiler.

Count source LOC/bytes/functions/types and actual cursor-record allocations if
cheap. Do not infer one allocation per token or claim a speed change from probes.
CPU3 is reserved for correctness; root alone grants exclusive same-source timing.
Retain every failed preparation/build/control attempt and report blockers before
expanding scope. The next semantic parser-stage proposal remains unimplemented.
