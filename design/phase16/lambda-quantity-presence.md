# Explicit Lambda quantity presence

Freeze before compiler changes. Root's combined literal/context source is the
authoritative parent after its checked build closes. Ordinary KTerm8, source
interval ABI3 and contextual-load ABI1 remain separate from this representation.
The earlier literal05 candidate and its experimental host remain immutable.

The read-only `spans-lam-review-01` probe establishes a concrete collision:
`&x:Type -> Type` and `Exists(Type, x => Type)` produce identical Bend Lambda
nodes. Pinned TypeScript's lowered JSON keys contain 184 and 201 UTF16 code units:
the second has the explicit `q` property, which costs 17 units. Source location,
names, semantic quantity and binder identity cannot reconstruct this distinction.

## Representation and ownership

Use one production Lambda variant:
`KLambda{name,id,quant,kids,removed,originBegin,originEnd,quantityPresent:Bool}`.
The eight fields replace the generic tag slot with explicit presence. Other
terms gain no field. Keep the existing children list and removed metadata so
`ks` does not allocate and backend sharing marks remain representable. Checked
JavaScript represents Bool natively. Projection `tg` returns Lam; ordinary
quantity remains `quant`; `k_quantity_present` reads the explicit field.
Legacy caller-supplied KTerm/Lam inputs mean a present quantity, consistent with
their prior explicit numeric field. Production constructors migrate explicitly;
`kt` and `kt_span` do not gain a branch on every ordinary allocation.

The source-spans owner owns the variant, projections, producers, common rebuild
preservation and coordinated host/cache capability transport. The checker owner
owns only exact memo-key serialization/counting and its controls, including
term_key/sp_keys/sp_key_string/sp_template_key and new JSON helpers. Both work
from the same frozen root-provided combined source and exchange bounded patches.

## Preservation policy

Explicit lambda syntax, definition parameter lambdas, do-bind lambdas and
pattern-flattening parameter lambdas carry a present quantity. Existential and
refinement sugar, rewrite motive lambdas and lhs extension lambdas carry absent
quantity, matching their exact pinned constructors. Structural rebuilding,
alpha-renaming, substitutions, specialization shifts, scope/alias/path rewriting
and source-range replacement preserve presence. A shared field-rebuild helper
preserves the variant where current code reconstructs a generic KTerm directly.

Pinned term_higher/term_lower preserve presence. Pinned strong normalization
deliberately drops it, so the corresponding g_snf result producer clears it;
norm_rebind merely renames binders and preserves it. Checked/backend Lambda
output clears presence. The current checker returns its original input term,
so it must not silently clear metadata on that source term. Whether existing
operational Many checks need to distinguish absent presence is a separate
semantic control and review, not an inferred rewrite of checker rules.

Initial audit found 15 direct Lambda producer sites containing 16 constructions
across 11 files, 17 generic KTerm pattern rows across 3 files, and 20 direct generic
construction rows across 12 files. These are audit counts, not all required
changes: several direct constructions are explicitly ADT-only. Generic native
erasure/compaction builders also require inspection. Estimated addition is
100–170 physical lines before the separately owned serializer; report the actual
delta and measured costs instead of claiming savings from the representation.

## Capability, cache and gates

Expose consolidated `compiler_term_abi1` for KTerm/KLiteral/KLambda, replacing
the uninstalled literal-only capability in this new candidate. Host field
transport understands the three variants and rejects an unknown present term
ABI. Cache version 6 binds termAbi1 and existing span ABI3. The installed compiler
without term capability retains its previous host path; experimental literal05
continues to use its own frozen host. Do not rewrite historical evidence.

First establish genuine checked construction and exact metadata controls:
explicit/implicit Lambda keys; same numeric quantity with different presence;
range transfer; child rebuild; substitution/alpha-renaming; strong normalization;
specialization shifting; alias/path/module rewriting; complete Base and program
projection after erasing only the new presence representation. Test unknown ABI,
corrupt presence/payload and stale cache rejection, plus the existing36 cases and
literal controls adapted explicitly to the new capability. A failing current v5
helper guard is retained and reviewed; never silently relax its recognizers.

The memo owner then implements one canonical logical JSON contract for identity
and 32768 UTF16 size. It must preserve optional fields, field order, JSON escapes,
literal payloads and canonical binder lowering. JavaScript string quoting is
not JSON quoting. Retain earlier rejected key/length experiments. Final corpus,
history, backend and serial performance gates remain root's responsibility.

## Reviewed operational followup

The initial representation-only candidate passed 110 metadata and 39 host/cache
controls. A separate `spans-lambda-demand-01` control demonstrates a real
operational distinction: with an affine Kind(&0) parameter, an absent quantity
on a Lambda whose preserved numeric quantity is2 must follow the expected
function type. Pinned TypeScript accepts it; the initial candidate incorrectly
applies the explicit-Many upgrade and rejects it. Explicit Many is rejected by
both. The raw API witness changes only presence and retains the original error.

Root reviewed and approved source04 adding `k_quantity_present(t)` to the three
existing Many-upgrade predicates in check_lam, check_lam_q and ka_lam. This
changes no other quantity rule, representation or host protocol. Legacy
KTerm/Lam inputs retain present=true. Before integration, test absent/present
annotations across affine-only and Data domains, zero/one/two uses and expected
affine/Many quantities, checked output quantities, and the maintained 36 cases.
