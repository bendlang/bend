# Index constructors in the existing parser scope

Source17 starts from frozen source16. Matrix03 still measured a5.384% process
regression, so neither source16 nor any contextual candidate is promoted. The
next experiment replaces repeated constructor scans in contextual parsing with
one explicit constructor-only index. It reuses the existing exact-name persistent
index algorithm; it does not change declaration-index winner semantics.

`FParseScope` becomes `{prior, index, ctors: KDef, ns, aliases}`. The new field is
internal parser state; it is not a KTerm field, loader wire type, persistent cache
format or public result. Scope matches mechanically retain it. There are21 scope
record/pattern rows across contextual.bend, declarations.bend, sugar.bend and
load/modules.bend before the change.

Three existing-algorithm wrappers in validate.bend define the contract:

* `f_ctor_index(book: List<KDef>, tree: KDef) -> KDef` folds the list tail first.
* `f_ctor_index_def(d: KDef, tree: KDef) -> KDef` indexes `dc(d)` over that tree,
  then inserts `d` only when its kind is Ctr. Thus an earlier head constructor
  wins over its own children, which win over later definitions, exactly matching
  the existing recursive first depth-first lookup. Other definition kinds do not
  occupy constructor entries, but their constructor children are traversed.
* `f_ctor_index_find(name: String, tree: KDef) -> KDef` performs exact index lookup
  and converts its Absent miss to the historical named Missing result from
  `f_find(name, Nil)`. Chosen definitions remain complete original values.

The initial source scope uses `f_ctor_index(prior, missing())`, without reversing
prior. `f_context_declared` receives an already qualified header and updates the
existing constructor tree with `f_ctor_index_def`. A normal Def or partial ADT
header with no children returns the identical tree. Constructor fields still only
accumulate in the existing local list until final ADT publication; do not make
partial constructors visible early. Incremental prepending must equal indexing
the prepended complete prior, including ordinary-name collisions and duplicate
constructor names in direct private controls.

Replace exactly five prior-book lookup expressions: the named and constructor
pattern validators, the prior constructor check in f_decl_prior, and the two prior
checks in f_decl_ctor_taken. Preserve both local raw-book scans and the original
general f_ctor_lookup worker. No resolver, materializer, checker, grammar or
declaration-index policy changes belong in this experiment.

The index builder necessarily visits all finite prior declaration/child metadata
once. It must not traverse term types or bodies. This is a new eager metadata
boundary on actual completed parser books, not a promise to preserve the raw
lookup's early exit on arbitrary poisoned list tails. Keep raw lookup unchanged
for that general contract. Independent controls must exercise the actual new
factory/update/lookup, compare full chosen KDefs and named misses, test true hash
collisions and both duplicate orders, and check undemanded term payloads. Include
empty and partial ADT updates and actual alias/import/constructor arity controls.

Freeze parent-relative patches and count all three helpers, the scope field and
net source growth. Run genuine checked bootstrap/maintained36, independent direct
and affected public gates, then a coordinated same-source cost screen. The entire
compiler must remain shorter than Phase21, preserve established conformance, and
recover baseline cost before promotion. No new index is justified by an assumed
speed gain; retain a failed result if the experiment misses this gate.
