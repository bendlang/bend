# P13-006 — Selector fusion with unchanged local constants

Prospective followup, 2026-09-28. Root owns the expansion decision and timings;
the rewriter owner implements the isolated variant, the independent reviewer
owns controls, and the measurement owner owns fresh/matched histories.
No constant-scope variant has been implemented or probed at this cutoff.

## Evidence and hypothesis

The first selector image passes its semantic and 4MiB resource gates and reduces
complete-source process time by 6.63% in an exclusive ABBA pilot. An exact-rule
inventory admits seven owners and 31 selector removals. Several sampled owners
(`check_node`, `core_subst_stable`, `norm_match`, `norm_args`) are refused because
the first pilot disallowed every declaration anywhere in a selected owner.

That restriction also excludes constant declarations in bodies that remain in
their original arrows, including Unit constants introduced by existing v5 leaf
lowering. Permitting those unchanged declarations may admit useful selector
chains without moving initialization or adding capture analysis.

## Narrow domain extension

Keep every existing selector rule. Permit only a single declaration of the form
`const identifier = expression;`. Its identifier must not match any owner
parameter, even in a nested or sibling block. Exempt only that declaration's own
initializer `=` from the write check. Continue scanning the entire initializer,
including nested arrows, for prohibited writes, declarations, shadowing and
control forms. Refuse destructuring, multiple declarators, `let`, `var`, bare
arrows, and all compound assignments. Do not move or capture any const value.

The removable false branch must still contain exactly one returned literal Unit
choice; its Unit binding must be unused. The nested condition must still compare
the tag of an initialized, unshadowed owner parameter with a literal tag using
the unchanged guarded helpers. Every initializer, effect and possible TDZ read
stays in its original block and demand position. No tag caching, native-equality
substitution, arbitrary condition fusion, normalizer seed change or runtime
change is admitted.

Keep the old helper, image and all observations immutable. This extension uses
new helper/manifest/tool files. A surviving arrow can contain another declared
rewrite site: check unchanged bytes outside those sites and exact terminal body
arrows, rather than claiming all enclosing arrow text remains identical.

## Bounded sequence and decision

1. Independent controls add selected/unselected throwing initializers, nested
   and sibling parameter shadowing, later-const TDZ, writes inside initializer
   callbacks, multiple declarators/destructuring and unchanged const/body ranges.
   Existing semantic and refusal controls must continue to pass.
2. Inventory the extended rule without timing. Initially select only checking
   owners supported by the profile: `norm_eval_node`, `check_node`,
   `core_subst_stable`, `norm_match`, `norm_args`, `ffw_walk`, and `infer_node`,
   retaining only those the actual transform accepts. No speculative backend
   expansion or additional grammar relaxation in this experiment.
3. Freeze one combined API derived from the same genuine checked parent. Check
   complete normalizer/checker observations and operation counts on the small
   valid graphs; then fresh string and exact 53/60 histories before timing.
4. Root runs the same exclusive CPU0 whole-source ABBA pilot with unchanged
   hosts, exact inputs, separately validated caches, Node24.18.0, 4MiB stack and
   4GiB heap. Any accepted-history regression rejects the combined image.
5. Judge the measured gain and whole maintained implementation cost against the
   master design's roughly20% or compelling speed-plus-simplicity criterion.
   Do not expand indefinitely to meet a desired number. A justified survivor
   still needs the master design's checked integration, complete frontend,
   backend, current TypeScript comparison and release gates before installation.

Record outcomes in `implementation/phase13/constant-scope-selectors.md`; retain
every failure and superseded tool. No evidence capture while producers run.
