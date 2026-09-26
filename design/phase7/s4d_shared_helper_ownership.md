# S4 D: put shared list helpers with their datatypes

Status: pre-implementation bounded proposal. B01 is checked and preserves all
2,756 frontend observations. Its controlled host cost is within the existing
5% runtime / 10% memory and size gates; graph-cost validation is still running.
No implementation or heavy build starts during controlled timing.

## Problem and scope

B01 removes duplicate list concatenation by using `norm_join` and
`norm_defs_join`. They are generic operations over `KTerm`/`KDef` lists, but live
in `core/normalize.bend`. That makes parser review pull in the entire normalizer
under the frozen whole-file context metric. The role-preserving parser context
grows from the original 5,716 lines to 5,928 despite less total compiler source.

Move exactly these two existing implementations and their existing declaration
blocks into `core/term.bend`, after their datatypes. Preserve every body byte,
binder, quantity, unsafe marker, public name and call. Do not introduce a new
module, visitor, representation, helper, rename or host rule. `core/term.bend`
already owns the relevant datatypes and list operations and belongs to all
original parser review sets. The normalizer already depends on it.

The intended architectural benefit is removal of the parser-to-normalizer
ownership dependency. Charge the moved helper bytes in the destination; total
compiler physical/nonblank/byte counts must not increase. Moving code earns
**zero production-size reduction**. The remaining dependency on the shared
seeded loader remains visible. Recount the original S0 context with every new
owner included, using the same whole-file rules; do not silently change its
baseline membership or infer cognitive effort from the file count.

## Cheap gate and rejection conditions

1. Review exact blocks, datatypes, declaration order and forward references.
   Preserve B01 unchanged and create B02 only after timing has finished.
2. Move the blocks mechanically without packing/removing unrelated lines.
   Keep the existing forward law even if relocation would make it redundant;
   this unit concerns ownership, not another declaration migration.
3. Run one fresh maintained checked build and its 21 focused controls. Require
   checked API, optimized API, runtime, host and all 55 ordered exports to be
   byte-identical to B01. Definition order *can* affect generation, so identity
   is an observed gate, not an assumption. If identity fails, retain the attempt
   and defer this bounded unit instead of silently inheriting B01's evidence.
4. If identity passes, B01's exact-output, full frontend, native-smoke and serial
   cost evidence applies to the same compiler bytes. Install only the new
   genuinely built attempt with its own source/bootstrap manifest. Verify the
   release and ordinary relocated operation. A02's full H proof remains A02's.
5. Recount production and original context sets, review ownership independently,
   and record the outcome and auxiliary costs in the S4 report before committing
   the usable release. This still cannot close the 50% milestone at 14,667 lines.
