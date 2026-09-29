# Full-filter worker: isolated correctness and cost screen

The eight-line source change lowers measured process time by6.65% on the frozen
compiler-source check:11.21236s→10.46647s. The same-window TypeScript mean is
3.44253s, moving the gap3.257→3.040×. This is a two-sample-per-image cost screen,
not a broad throughput claim or an installed release.

The candidate changes only core/index.bend: +8physical/+7nonblank lines,
+167bytes, one ordinary Bool worker, no type/law/representation/host changes.
The original filter still removes every duplicate, preserves retained order,
and recursively demands the complete tail. It assumes no uniqueness and makes
no suffix-sharing shortcut. All214 source/host members are retained; all35 host
files, Base, runtime, pin and guarded v5 profile match the parent.

The emitted guarded API uses a two-state loop for the selector/removal branch,
with a direct recursive call for the retained Con tail. The parent's per-cell
branch closures and run_loop boundary disappear through the existing v5 guard;
no generated-JavaScript policy was added. This is consistent with the measured
gain exceeding index_remove's directly sampled2.89%, but no new profile proves
how the difference divides among dispatch, GC and JIT effects. Retained list
construction remains required by the same source algorithm.

The genuine checkedB1, maintained guarded derivative and36strict focused
observations pass. All51 appended internal-helper controls agree exactly with
the parent, including an independent valid-list filter oracle, duplicate and
empty names, hash collisions, cached and nested-sentinel callers, legacy final
selection, malformed inputs, getter/error ordering, and interleaved same-process
histories. Every long-filter probe at1000/3000/10000/20000cells returns successfully
in both images with the4MiB stack. This finite coverage is not universal stack
or arbitrary-JavaScript-object equivalence. The complete ordinary full-source
result, including host provenance and unsafe-definition reporting, is unchanged.

Timing used the unchanged Phase16 matrix and Phase8 worker, exclusive CPU0,
Node24.18,4MiB stack/4GiB heap, fresh processes in TS/B/C/C/B/TS order, validated
per-image Bend Base caches and identical Phase21 source. All other owners
acknowledged idle before the14:59:54.773–15:00:53.576UTC window. All six processes
closed normally and passed the full type/trust gate. Request means improve
10.10825→9.35737s(7.43%); peakRSS657432→647004KiB(1.59% lower). Timing excludes
code emission; it does not measure the35.17s edit/build/validation loop.

Candidate APIc6d94a67 remains isolated in index-remove-build-01. Root reviewed
the source/demand argument before timing and owns broader integration and
promotion. The profile's failed counter-injection attempt remains failed and
fully retained; the compiler candidate and its gates passed on their first
attempt. [Exact receipt](index-remove-worker.json) binds all owned files and
closed evidence roots. No further optimization, live source change or push was
performed by this owner.
