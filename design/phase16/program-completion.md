# Defer completeness until ordinary and live-instance checking finish

The accepted compiler can report an open-law count before checking a live
template instance. The pinned `check/axiom_runtime_capture.bend` instead reports
the unfilled `magic` reference inside `tpl~0`. The host also counts source holes
before running the specializer, while the checker separately counts only open
laws. A mixed hole/open-law program therefore gets the wrong final count.

Hypothesis: retain the authoritative declaration/body checker and existing
specializer, but give their whole-program orchestration one Bend entry point.
Defer the final completeness refusal until both semantic stages succeed, then
use the existing source-book `driver_todos` accounting once. This should close
these two boundaries without inventing a second hole scan or choosing among
error messages. It does not solve interleaving instances with ordinary errors
inside one body; the larger [checker chronology design](checker-chronology.md)
remains required for that independent counterexample.

Thread one explicit `complete` Boolean through the existing six declaration
event workers. Existing `check_book` and exact-prefix diagnostic APIs pass true
and retain their historical contract. The new program entry passes false, uses
the same checked-prefix guard, then invokes the existing specializer. Preserve
the original `DResult` on ordinary failure and the specializer's original trace
on instance failure. On success return the materialized book; count TODOs from
the original source book, so repeated instances do not multiply source holes.
Use `check_open_message` for the final count and the shared diagnostic renderer.

Advertise checker-result ABI2 only when this entry exists. ABI2 means the host
receives a checked, specialized and completeness-validated book in DResult. The
host must not specialize or count holes again. Keep ABI0/1 behavior explicitly
unchanged, and refuse unknown ABI or an advertised ABI2 with a missing entry.
The Base-cache validator still uses the existing complete check_book API; no
cache schema or runtime change is needed. Future term-chronological checking can
replace the program entry implementation without another host-stage contract.

Before selecting the change, run paired controls for open laws, source holes,
mixed counts, fills, invalid ordinary terms before and after holes, valid and
invalid live instances, dead claims, repeated instances, and the measured
same-body counterexample (which must remain visible). Check legacy API results,
ABI0/1/2/unknown host routing, and a valid materialized instance directly. Build
checked B1 with unchanged v5; use the maintained focus and adjacent full gate.
Record all host and compiler deltas, source costs and failures. No performance
or complete chronology claim follows from focused tests.
