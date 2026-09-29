# Phase16 checker wave2: specialization error transport ablation

Prospective addendum before edits/execution. Wave1 source02 remains immutable.
Correct census:22 legacy checker rows split15 ADT,1 foreign,5 specialization
String-loss and1 TODO-precedence case; initial design prose undercounted ADT by
one. Selection IDs and total55 were correct.

Replace KSpecState.error:String with the existing KChecked result; preserve
sp_error's public String projection. Keep the first error. KSpecialized retains
the result, exposes the same specialized_error/book projections, and gains an
optional specialized_diagnostic export returning existing DResult. Bootstrap
feature detection must support historical modules. Source host uses one shared
locate/render helper for both chronological-check and specialization rejection.
No JavaScript formatting, duplicate checker or reference fallback.

sp_validate uses check_definition_result directly. Template key growth, depth
and active-instance cycle errors receive the actual reference head and caller
context, then construct existing DTrace via dg_trace. Existing checks, limits,
instantiation order and verdicts stay unchanged. This ablation isolates lost
content from the independent source-check-versus-instantiation ordering gap.

Expected corpus changes are diagnostic-only, chiefly template_inst_cycle,
comptime/dup_lone,err_grow,err_grow_double,later_def. Actual exactness depends on
origin preservation through instance cloning and is not presumed. First-error
controls pair earlier/later bad definitions with invalid live template instances,
TODO/live-law captures,captured variables,valid imported calls,and recursive
growth/cycle corpus fixtures. Preserve any baseline ordering mismatch as an
explicit unresolved result. No new nonexact first-error shift is inherited.

Also bind the kind term once in dg_kind_check. Restore successful ADT checking
to the existing tele_tip+check_ctors path; reconstruct the bound diagnostic
context only on a non-kind tip. This repeats normalization only on rejection,
never type checking, and avoids success-path context allocation.

Owned new files:check/specialize.bend and tools/typed-driver.mjs, plus wave1
check/kernel.bend and diagnostic/trace.bend corrections. Private source03, fresh
checked B1 equality attempt on CPU1,36 maintained gates,frozen55 content rows,
12 wave1 boundaries and new ordering controls. Root integrates separately.
Do not change captured wave1 files or timings. No performance claim until the
final same-source exclusive matrix. Report all ABI/host/source cost separately.
