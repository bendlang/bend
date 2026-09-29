# Phase24 two-core sanitizer rerun

Keep the six CPU7 observations unchanged. Rerun only the already built reference
and candidate `array_atomic_fadd` sanitizer executables with `--threads 2` and
affinity CPUs2,3, which must have distinct recorded physical core IDs. Preserve
the executable/source lineage, exact command, complete outputs and the same
30-second deadline. No source edit, recompilation, additional fixture or timing
comparison is required. This supplies a two-core execution configuration in
addition to the earlier two-worker single-core control; it is not a general
race-freedom proof or a trace proving every possible interleaving occurred.
