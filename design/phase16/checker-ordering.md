# Phase16 checker wave3: local upstream checking order and generic binders

Prospective plan; execution follows the separate specialization-transport
ablation. This wave must use a fresh candidate and preserve every older attempt.

Pinned term_check checks a rewrite motive against its dependent function type
before comparing its applied endpoint with the final goal. Our check_rwt_goal
currently compares that endpoint first and therefore reports e instead of the
invalid proof-valued motive under its generated context. Move the existing
motive check before that comparison; preserve its KChecked failure unchanged.
Check the body only after both earlier conditions succeed. No new checker pass
or duplicated motive check. Probe a correct rewrite,an invalid motive with an
also-invalid endpoint,an invalid evidence type,and a well-typed motive whose
endpoint still mismatches the goal.

Pinned def_check creates opaque generic constants as definition~binder and
rejects reuse before opening the next binder. Ours appends the global binder ID,
which hides duplicate names and leaks those IDs in diagnostics. Drop that suffix
and guard the actual lookup before installation. The guard uses existing
DTrace; no fixture/text-specific rewriting. Probe duplicate generic names even
when the second value is unused,distinct names,same names across separate
definitions,and both existing template_dup_binder and comptime/err_generic.

TODO accounting and the placement of live instantiation remain separate: this
wave will not repair them with message substitutions. Ordered source checking
and template validation must eventually share authoritative events,with the
previously frozen first-error controls. Root reviews that larger change after
these local fixes and after source-range integration is stable.

Only check/kernel.bend should change beyond the frozen transport source03.
Require a genuine checked B1,36 maintained cases,55 strict content rows,12 prior
boundary controls,12 prior ordering controls and the new local-order controls.
No new behavior difference may be excused by unchanged rejection count; report
actual phase/acceptance/trust/output and full diagnostic against pinned TS.
