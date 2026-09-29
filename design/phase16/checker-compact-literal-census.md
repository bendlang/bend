# Phase16: measure eager literal expansion before changing representation

The exact Base-prefix law holds but removes only1.3244% of actual freshening
visits. On the same frozen compiler source, alias traversal visits105,542 nodes
and freshening visits2,170,908. Investigate the intervening expansion directly.
No compiler function body or installed API/cache changes in this experiment.

Pinned TypeScript has explicit Lit(Nat/U32/F32,number) and Lit(String,string).
Chr is a constructor whose code is a U32 literal. lit_step unfolds at head-demand
boundaries; term_check accepts a literal at its exact trusted Base datatype
without checking a constructor node per unit. term_key preserves the Lit/Ctr
identity. Non-scalar string codes intentionally fall back to constructor chains.
Our frontend already keeps Nat compact but eagerly expands U32/F32 words and
String/Char codes. One U32 becomes66 KTerms; a string scalar adds68 plus one
terminal SNil for the string. These formulas are code facts, not yet workload
attribution or promised speed gains.

Bind the same wave4 compiler source, checked probe API and validated cache used
by the successful serial Base law. Run one CPU1 worker,4MiB stack/4GiB heap,
with bounded process supervision. Retain compact parsed/raw tag histograms,
constructor-name counts, and disjoint structural subtrees for String, Char,
U32, F32, Nat and other terms. Count actual entries into the existing literal
builders and word worker with an instrumentation-only generated API. Counters
are not timings or total allocations. Shape classification does not claim that
every literal-shaped subtree came from written literal syntax.

Record parse/discovery and graph-elaboration counters separately. Hash and verify
all source/API/cache/tool inputs before and after. Aggregate results only; do not
write giant AST dumps. Cross-check final raw KTerm count against the prior bound
whole-source census. Inspect all consumer/rebuild sites before selecting a
representation. Prefer an explicit compact literal sibling of KTerm if it avoids
adding a field to every ordinary term; do not overload id/quant/ranges or erase
literal-vs-constructor identity. A source candidate, semantic boundaries, backend
lowering and controlled speed comparison remain separate future work.
