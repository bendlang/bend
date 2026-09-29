# Template-count projection: bounded proof and exclusion

This supplements `context-template-index.md` before candidate15. The sole proposed
change is the count expression in `f_context_call_input`, from `dx(f_find(...))`
to `dx(index_find(index, canonicalName, index_hash(canonicalName, 2166136261),32))`.
Keep the Ref-only conditional and every parsing checkpoint unchanged. Candidate15
starts from source13, independently of the constructor Bool-worker experiment.

The proof is a projection invariant, not definition equality:

* Initial `f_source_body` constructs the index from reversed prior definitions.
  It may select a different repeated declaration than `f_find`. Successful
  imported fills preserve the old template count in `f_graph_fill`, and
  `f_context_module` retains it. Non-fill duplicate declarations and invalid fills
  stop graph completion before their graph can seed a subsequent source.
* `f_context_declared` prepends and indexes the identical header. This includes
  temporary self headers and final local publication. A provisional imported-fill
  header may have a different count from its old law, but both lookup routes see
  that same newest header until graph filling restores the inherited count.
* Type and constructor headers have count zero. The index contains top-level
  definitions only, matching this call consumer's existing linear lookup; nested
  constructor lookup is outside this change. Missing definitions have different
  structural sentinels but both count projections are zero.

Freeze a direct private probe of the actual compiled workers. It must retain an
adversarial initial prior containing duplicate names with different counts, where
the two lookups disagree. It must also show same-count duplicates can have unequal
whole definitions, missing sentinel inequality, identical latest-header selection,
successful imported-fill count preservation, and invalid-fill refusal. This
counterexample explicitly excludes arbitrary malformed private prior/index pairs
from a blanket substitution claim.

An appended probe extension may wrap the compiled call worker to compare both
count projections at actual production calls. Preserve the original API as an
exact byte prefix, hash the extension separately, and label it instrumentation,
not a checked compiler. Use immutable ordinary/template/imported-law source
fixtures and the same frozen Phase21 compiler workload, recording counts and all
disagreements compactly rather than serializing large books. Its extra reads are
diagnostic evidence only and cannot be used for performance measurement.

Only if the primitive/source invariants hold, freeze the one-expression source15,
run checked build14/maintained36 on CPU1, and rerun independent frozen template,
law-fill, alias, missing-call and argument-error controls. Family and marked-name
lookups remain unchanged because they observe additional fields. Reject any
production count mismatch or changed public result. Final speed and broad
conformance remain separate root-owned gates.
