# Resuming with bounded resources

The interrupted session's cause is unknown. The resumed environment has about
31 GiB RAM and 27 GiB available; its current session cgroup reports zero OOM
events. Those counters do not establish what happened in the prior environment.
The exact observation is in `implementation/phase32/resume-resources.json`.

Root executes compiler builds, imports, correctness campaigns and benchmarks
serially. Agents prepare and review files without launching these jobs. A shared
exclusive lock enforces this for the new launcher. Every process has a deadline;
Node heaps are normally 512–1024 MiB. The outer launcher samples the aggregate
resident memory of the process tree, stops it at an explicit limit, and requires
at least 2 GiB host memory available. Aggregate RSS can count shared pages twice,
which is conservative. This is a containment measure, not proof against OOM.

The launcher records the command, exact launcher hash, captured output, memory
peak, minimum available memory, time and stop reason. It kills tracked children
on exit, checking process start identity before signaling. No background build
or benchmark should survive its campaign. Failed or capped runs remain evidence;
do not silently increase limits to obtain a favorable result.

New attempt02 uses one workflow job and a 1024 MiB Node heap. Acquisition and
correctness precede uninstrumented timing. Preserve the installed Phase31
compiler until the chosen candidate passes integration and release verification.
The starting103 unrelated worktree files remain protected by their hash inventory.
