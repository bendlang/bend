# Check quiet TODO holes at their expected type

Pinned `term_check` treats only the hole named `TODO` as a quiet placeholder:
it returns that term at the supplied type with no variable uses. Other named
holes remain ordinary goal errors. The compiler still refuses an incomplete
source after checking; acceptance of a hole inside the kernel is not acceptance
of the program. The current Bend check_node instead rejects every Hol immediately.

First compare the existing hole_todo/hole_named cases and frozen nearby controls:
one/two placeholders, multiple references to one placeholder, an affine or erased
binder around a placeholder, ordinary named/case-different holes, an inferred
hole without an expected type, earlier/later ordinary errors, and a quiet hole
beside an unfilled law. Then change only the Hol branch to the existing lazy
conditional: `TODO` returns `ok(t, ty, Nil{})`; the other branch remains unchanged.
This introduces no helper, type, source pass or representation change.

Do not change inference, source-hole accounting, specialization, final TODO timing
or first-error transport in this experiment. Those boundaries require independent
controls; the known live-instance versus unfilled-law chronology gap remains.
In particular, never count elaborated copies as additional source placeholders.
The full source-hole count and final refusal are still the existing driver's job.

Use a frozen isolated source descending from the controlled range-cost composition,
a genuine checked build and its own cache4-aware validation workflow. Preserve
all baseline observations and compare primitive outcomes to pinned TypeScript.
Require focused validation and exact intended cases; retained unrelated gaps are
reported explicitly. Coordinate this single kernel hunk with the trace owner.
Full integration and whole-host performance remain release gates.
