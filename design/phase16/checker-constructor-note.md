# Phase16: constructor goal notes need absence of a declared constructor

Pinned `bend.ts` checks both constructor-family absence and a datatype with the
same name before suggesting angle arguments. The current `dg_trace` predicate
checks only the latter. Base F32 has both a datatype and its declared constructor,
so its mismatch incorrectly acquires this suggestion.

Change only that predicate in an isolated wave7 copy. Preserve `ctr_of_datatype`
(the positive note case), `switch_miss_guard` (the false F32 note), and ordinary
numeric/constructor inference and mismatch controls. Run genuine checked B1,
maintained36 and a strict paired subset before independent integration. Literal
representation changes are not required for this correction.
