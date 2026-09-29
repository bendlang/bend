# Quiet TODO checking, with the final count still explicit

The [design](../../design/phase16/quiet-todo.md) adds one conditional expression
to the existing Hol branch. Only TODO checks at its supplied type with empty
uses; other holes and inference without a goal keep their existing errors.
No lines, definitions, laws or types are added. `quiet-todo-build-01` passes its
genuine checked/v5 build and focused36, then makes **13 of14 paired controls
exact**, compared with six exact on the unchanged parent.

The original hole_todo fixture now agrees exactly with TypeScript. One/two source
holes, repeated references to one hole, affine/erased surrounding binders, named
and case-different holes, missing inference goals, and earlier/later ordinary
errors preserve the intended behavior. Every primitive result agrees with TS.
The remaining mixed unfilled-law plus quiet-hole case expects two TODOs but
receives one: check_open refuses before the driver's complete source-hole count.
The broader first-error/TODO chronology remains open and is not claimed fixed.

The first selection omitted the external fixtures' required acceptance contract
and failed before a reference report. The next duplicated-reference witness used
an unannotated operator and was refused during parsing. Both are retained. The
corrected frozen selection uses `(a + a : U32)` and reaches the intended checker.
Evidence: `quiet-todo-baseline-01`, `-02`, `-03`, `quiet-todo-controls-03`, and
`quiet-todo-checks-01`, under `selfhost/build/phase16/`.

The one-expression correction is integrated into the healthy wave4-build02
checkpoint; no incomplete program is newly accepted, and the full Phase16 gate
remains separate from the eventual release gates.
