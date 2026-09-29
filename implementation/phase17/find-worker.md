# Phase17: direct frontend lookup

The installed compiler checks identical source in **6.55% less process time** than Phase16:
**12.44→11.63 seconds**, with all **2,996 frontend results unchanged** and all
**42 installed/relocated CLI checks passing**. The change adds **eight Bend
lines and one helper**, with no runtime, host, cache or transformation changes.
Pinned TypeScript takes **3.40 seconds** in this window; the remaining gap is
**3.42×**. No full-conformance or generated-program runtime speedup is claimed.

## Mechanism and selected artifact

The [fresh compact-image profile](compact-profile.md) found repeated frontend
declaration scans. Each missed name in generated `f_find` created a `$JMP` record
and an argument array for `run_loop`. A Boolean-parameter worker expresses the
same branch as a mutual tail call, which the original emitter lowers to a direct
two-state loop. This repeats the successful source-worker pattern used by the
ordinary lookup helper without extending the maintained JavaScript rewrite.

The [prospective design](../../design/phase17/frontend_find_worker.md) preserves
first-definition precedence, the named `Missing` result, string equality, input
access order and lazy tail/payload demand. Lookup remains a linear scan; no hash
table or alternate parser name-resolution authority was introduced.

| Identity | Value |
|---|---|
| Source | `find-worker-source-01/project` |
| Checked attempt | `find-worker-build-01` |
| Installed API SHA256 | `9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6` |
| Genuine checked parent SHA256 | `59317ea5f8ec47b98e55a5e4d72718ffa9e59fec780cae0819a45e4eafe3f451` |
| Assembled source SHA256 | `9b4f927229a0ae941679e6598d74d0d3dbe91963a0a0a323b6116af0c44578d9` |
| Parent release API | `35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315` |
| Upstream pin | `b2111cf43244e65f76ddc278ee695e669f720cbf` |

The installed API remains a guarded version5 derivative of a genuine checked B1.
Exactly `src/front/declarations.bend` differs in the complete 214-file checked
project membership. The compiler guide and release verification commands remain
unchanged. The old API and original lineage are retained in release history.

## Controlled measurement

All compiler/archive jobs closed before the six fresh processes ran serially on
CPU0 in **TS/B/C/C/B/TS** order, with Node 24.18.0, stack 4 MiB and heap 4 GiB. Every
one of the 35 frozen host files has identical membership and bytes between the
two Bend attempts; Base and runtime are also identical. Each image checks the
same final candidate source. Bend uses validated per-image Base caches while TS
checks Base. OS caches are not flushed and emission is excluded.

| Image | Mean process | Mean request | Maximum RSS |
|---|---:|---:|---:|
| Pinned TypeScript | 3.3998 s | 2.3313 s | 476,456 KiB |
| Phase16 compact release | 12.4407 s | 11.3439 s | 651,144 KiB |
| Lookup worker | 11.6255 s | 10.5307 s | 648,316 KiB |

Both order pairs improve: baseline 12.4580/12.4233 s, candidate 11.6412/11.6099 s.
Process time falls 6.55%, request time 7.17%, peak RSS 0.43%. The same-window TS gap
falls **3.66×→3.42×**. The older Phase16 window also rounded to 3.42× because its
TS baseline took 3.61 s; that coincidence must not erase the current paired gain
or be presented as another cross-window ratio. These are two samples per image
on one workload and host, not a universal speed forecast.

All six observations accept types and return the same expected unsafe-definition
proof-trust refusal. Request wall wraps `adapter.probe`, including lazy API load;
process wall also includes startup, input hashing and output capture. Raw matrix,
complete host review and both exact sample pairs are under
`selfhost/build/phase17/find-worker-matrix-01` and `find-worker-matrix-inputs-01`.

## Correctness and installation

| Final-image gate | Result |
|---|---|
| Maintained checked workflow | 36 cases; two inherited exact gaps |
| Actual generated helper demand | 23/23 paired;46/46 independent expected outcomes |
| Full frontend | 2,996 complete results identical to installed Phase16 |
| Selected interpreter/JS/native backend | 41/41 exact, pinned Clang16 |
| Supplied-source and host lifecycle | 39/43 controls; unchanged known wording gap in each |
| Original histories | 226 paired complete results identical;fresh long strings pass |
| Maintained transformation | 16 unchanged groups; five authentic v1–v5 replays |
| Standalone loader | 25 modules; unchanged raw/traced/seeded controls pass |
| Installed and relocated CLI | 42/42 pass |

The [demand controls](find-demand.md) include duplicate object identity, exact
getter events, demanded raw throws, unforced poison sentinels, Unicode/prefix
names and a 100,000-definition miss at the original 4 MiB stack limit. The probe
appends a named wrapper to each full unchanged production API prefix and records
distinct hashes; it tests the actual internal helper, not the public forcing ABI.
[Additional gate details](find-demand-gates.md) include a strict comparison of
the full frontend vectors, confirming even the two known diagnostics are unchanged.

The main inventory still accepts all 1,001 positives, refuses all 482 validation
negatives and matches all 11 trust refusals. It retains two exact differences
for one monad do-block, and strict check results 1,493 pass / 5 fail include four
later-emission expectations. Wider known Phase16 gaps are not claimed fixed or
revalidated solely because this smaller full inventory is unchanged.

The original 53/60-request histories preserve order, complete result objects,
provenance and 4 MiB stack / 4 GiB heap limits. Both APIs use the same byte-identical
compatible host and separate Base caches. Finite controls do not prove universal
stack safety. No new self-emitted fixed point, kernel or GPU result is asserted.

`find-worker-promotion-01` fails before copying source because its verifier
expects a flat identity where the demand report records paired original/consumed
identities. `find-worker-promotion-02` verifies both members explicitly, retains
the failed report and installs the single source change after all gates pass.
The raw gate results and oracles are unchanged. All 75 unrelated Phase6 files
retain their original hashes. `find-worker-smoke-01` verifies the installed and
relocated release with the unchanged 42-step runner.

## Complexity and separate semantic investigations

The ordered 59 compiler modules contain **16,353 physical /13,954 nonblank lines**,
**581,322 bytes**, **1,657 definitions /775 laws /66 types**. Relative to Phase16:
**+8 physical /+7 nonblank lines, +145 bytes, +1 definition, no new type**. The
single helper improves emitted control flow; it does not reduce source size or
achieve the older 50%/75% line-reduction targets.

Two independent experiments remain outside the installed release:

- The [group-boundary ablation](group-boundary.md) preserves information needed
  by a future parser failure resolver. Its 92 structural controls pass and 196
  paired outcomes remain unchanged, with zero conformance gain. Its whole-tree
  counts include 61 Bend files, including off-manifest files; those totals must
  not be compared directly with the 59-module production counts above.
- The [instance chronology investigation](instance-chronology.md) confirms two
  distinct order gaps in 22 observations, with 20 exact results and 8 exact memo/name
  controls. Moving the existing specializer earlier does not fix the nested
  counterexample. A shared checker/state proposal has a representation-cost
  checkpoint before semantic migration; its speed and source-size effects are
  unproven.

These experiments expose further gaps outside the main corpus. Full conformance
therefore remains work in progress. The earlier automatic approval review still
blocks remote publication; successful local installation is not a successful push.
