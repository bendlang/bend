# Exact cached-prefix identity correction

The installed compiler now rejects a changed equality proof when given an old
validated prefix. The old public API accepted this input even though its full
checker and pinned TypeScript rejected it. The fix changes one function by two
physical lines; it adds no definition, law, type, cache format or public ABI.

This is a separate usable release from the ongoing live-instance checker and
contextual parser experiments. Neither larger prototype is installed. The
[design](../../design/phase19/exact-prefix-identity.md) and
[machine report](prefix-identity.json) bind the precise scope and evidence.

## Cause and reproduced failure

`exact_term` compared only generic term projections. Compact literals store their
number/text payload elsewhere, so different Nat/U32/String values could compare
as an identical prefix. Lambda quantity presence was also omitted despite being
part of the source syntax and specialization key.

Independent pinned TypeScript accepts a self-contained Nat proof of
`{0n == 0n : Nat}` using `{==}` and rejects `{0n == 1n : Nat}`. On the Phase17
API, checking the changed book in full also rejects with `proof: reflexivity
endpoints differ`; passing the original validated book to
`check_from_exact_prefix` incorrectly accepts it. On the corrected compiler,
`exact_prefix` is false and the cached path performs the full check and rejects.
This witness concerns the public prefix API; it does not demonstrate a bypass
of the host's separately hashed Base cache. The parent failure remains recorded.

The correction uses the existing compact-literal equality helper and compares
lambda quantity presence. Equivalent expanded constructor syntax stays distinct;
legacy explicit KTerm lambdas remain compatible. Source intervals retain their
historical separate provenance contract. No semantic normalizer is substituted
for exact syntax identity. The [independent controls](instance-boundary.md)
record all twelve cases, including five genuine parent failures and zero
candidate failures, plus the proof witness and its complete process records.

## Validation and measured cost

The genuine checked B1, maintained 36, all twelve direct identity controls and
the proof witness pass. The complete frontend run preserves all 2,996 result
objects exactly against Phase17, with no missing observations or lost exact
matches. The same two main-corpus do-block diagnostic differences remain; broader
conformance gaps are not erased by this fix. All 42 installed and relocated CLI
checks pass. Phase17's 41 backend and other historical controls were not rerun as
new coverage for this two-line change.

| Exclusive same-source workflow | Mean process | Mean request | Maximum RSS KiB |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 3.417572 s | 2.323188 s | 479,784 |
| Phase17 baseline | 11.611920 s | 10.484785 s | 653,508 |
| Prefix correction | 11.617067 s | 10.510595 s | 647,564 |

Process time changes +0.0443%, request time+0.2462%; the result is neutral for
this screening experiment, not a speed gain. The current same-window process
gap is 3.3992× TypeScript. Peak RSS changes −0.91%; two samples do not establish
a general memory improvement.

The unchanged matrix runner executes TS/B/C/C/B/TS serially in fresh processes
on CPU0, stack 4 MiB/heap 4 GiB, with other compiler/probe/archive jobs held. Every
variant checks identical assembled candidate source. All 35 frozen host files,
Base, runtime and maintained version5 derivation agree. Bend uses separately
validated Base caches; TypeScript checks Base. OS caches are not flushed. All
six rows accept types and produce the expected unsafe-definition trust refusal,
with identical unsafe sets. Emission and generated-program performance are
outside this measurement. The prospective 5% cost-regression screen passes.

## Installed identity and size

Selected source is `selfhost/build/phase19/prefix-source-01/project`, checked as
`prefix-build-01`. API SHA256 is
`66d6ce45c0c6ea8947190ff210274f1e6f0c7bf85f7ad3f215076f8820acd7c7`; genuine
checked parent is `45ee9449c04f5296e978f77a13a184f6dea84dae5fb23539c7ae2a60f4826edd`.
The pin remains `b2111cf43244e65f76ddc278ee695e669f720cbf`. Promotion verifies
all 214 source/host members, copies only `src/check/prefix.bend`, preserves the
previous release, and rechecks all 75 unrelated Phase6 hashes/statuses.

The 59 compiled modules contain 16,355 physical /13,956 nonblank lines and 581,508 bytes,
with 1,657 definitions /775 laws /66 types. Delta versus Phase17 is +2 lines/+186 bytes
and zero new concepts represented by definitions or types. This is a small
correctness repair, not the larger simplification target. The release remains
a checked B1 derivative, without a new fixed-point or independent kernel proof.

Primary local evidence is under `selfhost/build/phase19/prefix-*` and the frozen
`instance-boundary-exact-*`/`instance-boundary-proof-*` records. Durable capture
is a separate checkpoint; ignored build paths alone do not provide preservation.
Local commits do not imply publication: an earlier automatic approval review
still blocks Git push.
