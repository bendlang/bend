# Program completion is correct and performance-neutral on this comparison

The frozen TS/B/C/C/B/TS matrix checks the identical wave7 compiler source with
wave7 and isolated program-completion01. Both use unchanged v5, runtime and Base;
the complete one-file host delta was reviewed and hashed before execution. All
intentional compiler/archive jobs were closed, with agent acknowledgments;
samples ran serially on CPU0, fresh processes, 4MiB stack and4GiB heap.

| Image | Mean process time | Mean request time | Maximum RSS |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 2.9708s | 1.8992s | 443,940KiB |
| Wave7 | 29.2656s | 28.0946s | 1,646,692KiB |
| Program completion01 | 29.3768s | 28.1696s | 1,646,800KiB |

Process time changes by **+0.38%**, request time by+0.27%; memory is effectively
unchanged. The bounded experiment establishes no speedup or meaningful extra
cost. The candidate takes9.89 times the reference process time on this source.
Individual process samples are TS3.0289/2.9127s, baseline29.3699/29.1613s and
candidate29.3043/29.4493s. Two samples per image do not establish high precision.

All six observations pass checking/trust gates and have equal unsafe-definition
sets. These are complete checking workflows, excluding emission. Bend reuses
validated disk Base caches; TypeScript checks Base. OS caches are not flushed.
Request timing includes lazy API loading but excludes adapter import; process
timing also includes startup, input hashing and output capture. Do not compare
this ratio with a different historical source as a time-series speed claim.

The improvement is semantic: live-instance errors precede final incompleteness,
and source holes plus open laws receive one final count. The change removes a
duplicate host orchestration responsibility but does not establish faster
generated programs, final wave8 performance, or complete instance chronology.
Compact literal representation remains the larger measured structural lead.

Evidence: `selfhost/build/phase16/program-completion-cost-01/{matrix.json,host-review.json,host.patch}`
and `program-completion-matrix-01/report.json`, with every sample and exact input
identity retained. The [prospective plan](../../design/phase16/program-completion-cost.md)
and [semantic report](program_completion.md) describe separate gates.
