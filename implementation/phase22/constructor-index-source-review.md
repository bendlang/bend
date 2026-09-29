# Constructor index: independent source review

No source blocker found in frozen source17. The five-file change adds17lines/1,033bytes, three wrappers and one internal scope field; it reuses the existing exact-name index. All215source members are retained, and the original raw constructor lookup is byte-identical after removing the added helper block.

Index insertion runs tail, children, then constructor head, so the first depth-first constructor wins even with duplicate names and nonconstructor containers. Ordinary definitions cannot overwrite constructor entries. Initial constructor indexing uses prior's original order, independent of the general declaration index's reversed order. The miss adapter preserves the historical named Missing result.

Incremental updates receive the already qualified header. A Def or partialADT with empty children retains the old constructor tree; constructor fields still accumulate locally and become visible only at final ADT publication. Only the five planned scoped lookups change. No resolver, grammar, term-body traversal or raw/local lookup change was found.

The new eager boundary visits immutable completed metadata once. It cannot claim the old raw lookup's early exit on arbitrary poisoned tails during construction. The retained34 raw controls remain useful but do not test this index: new factory/lookup/publication, duplicate/collision, missing-name, namespace and persistence controls are required, followed by checked build, affected public gates and cost. This approval concerns source scope only; it is not promotion or a measured speed claim.
