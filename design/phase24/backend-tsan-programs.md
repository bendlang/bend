# Phase24 preserved Bend ThreadSanitizer controls

The matching Clang16 runtime successfully executes a clean atomic pthread
control and reports the intentional non-atomic race. This establishes enough
environment capability for a bounded generated-program investigation.

Compile the unchanged saved Phase23 reference and candidate C for
`atomic_operations_v3` and `shared_array_ownership_v2` from
`backend-final-controls-01`. Use the same Clang16 compiler, library/include
environment and verified matching sanitizer runtime, with `-O1 -g -pthread
-fsanitize=thread -fPIE -pie`. Preserve complete compiler and runtime output,
flags, source/executable hashes, original requests and fixed fixture oracles.
Use a new evidence directory and CPU7 only; do not edit emitted C, suppress
instrumentation, or alter the installed compiler/runtime.

Run at most one bounded execution per side/fixture initially, with an explicit
worker setting if supported by the saved program. A 30-second execution deadline
and approximately five-minute investigation bound apply. Report observed data
races, crashes and runtime setup failures verbatim. A passing selected control
does not establish general race freedom, arbitrary concurrent structural-read
safety, or hardware/GPU coverage. Missing symbolization remains visible.
