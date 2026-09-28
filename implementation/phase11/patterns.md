# Phase11 pattern reconstruction and native code expansion

The checked candidate reduces canonical Nat300 native output from the inherited
20,589,858-byte backend output to 269,358 bytes (98.69% smaller), and the actual
Clang16 build now completes with output exactly `306n`. This is a native backend
result, not a claim about checking speed, JS output, GPU execution, or the overall
gap to TypeScript. Root owns integration and controlled release measurements.

The [prospective experiment](../../experiments/phase11/P11-002-patterns.md) was
written before probes. No production source, installed artifact or pinned
upstream file was edited by this owner. The isolated candidate adds 17 physical
lines to `back/native/bridge.bend` (437 to 454), one helper and two private lowering
tags. The [patch](../../selfhost/tools/performance/phase11/pattern-candidate.patch)
is against the immutable Phase10 integrated snapshot.

## What upstream taught us

The pinned upstream compiler explicitly combines nested native Nat increments in
`tpl_nat` (comp.ts around660) and calls it from `emit_ctr` (around2375). Its parser
flattener also reconstructs consumed scrutinees, so reconstruction itself is not
an accidental semantic difference. The critical backend difference is that Bend's
`nc_compact` only recognizes closed constants, and `nc_lower_ctor` sequences each
remaining Succ child through a new continuation. A native-only offset term may
remove this multiplication without changing frontend/checker representations.

The relevant upstream revision is `b2111cf43244e65f76ddc278ee695e669f720cbf`.
Its `bend.ts` `match_flatten` / `body_sub` and our `front/elaborate.bend`
`f_hit_row` both rebuild scrutinees when substituting the remaining default
pattern. The fresh size series confirms quadratic continuation growth in our
native backend, beyond that frontend obligation. The separate unpromoted
Phase6 P6-005 closed-word prototype was reviewed and deliberately excluded:
keeping words inline in generic records is a different optimization.

## Candidate and semantic boundaries

After typed erasure, native constructor names remain literal `Succ`/`Zero`;
user-owned constructors are encoded by `nc_ctor_identity`. Only a unary `Succ`
whose ordinary closed-literal recognizer failed enters the new run collector.
Closed constants retain the old `NWord` path. The collector preserves a single
increment as a constructor and represents a longer run with `NNatAdd`, storing
the residual offset as a decimal string. Its dynamic tail remains one child.
Generic reference discovery and environment collection continue traversing it.
`nc_sequence` evaluates that child once in its original position, then emits a
single `NNatSum` arithmetic result; it does not duplicate or reorder tail effects.

An offset of `n` emits `nat_chk(e, nat_chk(e, tail + 1) + (n-1)ull)`.
Keeping the first check matters even for malformed foreign U64 tails: an initial
U64 wrap or first error must match the original sequence. Once that first check
passes, its value is at most the runtime's `NAT_IMM = 2^48-1`. The collector caps
the whole run count at U32 max, so the remaining addition cannot overflow U64.
Positive increments cross the same Nat bound and produce the same error. GPU
runtime first-error recording follows the same argument, but GPU execution was
not tested and is not claimed.

The collector stops before its U32 count wraps, then independently compacts the
remaining tail. An explicit zero-count guard preserves the unchanged tail. Zero
is not the public entry seed, but a direct guard falsifier found a real private
helper underflow in candidate01; candidate02 fixes it. Source constructors
spelled `NNatAdd`/`NNatSum` remain `Ctr` nodes with encoded names and cannot become
the private tag. Wrong-arity raw `Succ` nodes retain the original fallback.

## Reproduced mechanism

Fresh baseline and candidate counts use separately copied, instrumented checked
images, CPU1, Node24.18.0, 4MiB stack, 4GiB heap and bounded subprocesses. All rows
check and emit actual native C. Instrumented development times overlap root's
work and are not used as speed ratios.

| Nat pattern depth | Baseline `nc_let` entries | Candidate entries | Baseline `nc_nat_literal` entries | Candidate entries | Baseline C bytes | Candidate C bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 8 | 44 | 16 | 312 | 46 | 108,528 | 96,257 |
| 16 | 144 | 24 | 1,904 | 154 | 153,899 | 100,975 |
| 32 | 536 | 40 | 13,024 | 562 | 329,979 | 110,415 |
| 64 | 2,088 | 72 | 95,680 | 2,146 | 1,024,230 | 129,295 |
| 300 | — | 308 | — | 45,452 | 20,589,858¹ | 269,358 |

¹ The 300-depth baseline size is the preserved Phase10
`layout-native-combined-01/program.c`, with the same unchanged native bridge.
It is inherited evidence, not a new controlled baseline measurement. The fresh
8–64 series independently reproduces the mechanism. Root controls any final
installed baseline/candidate comparison.

The candidate continuation count and emitted C grow linearly on this series.
The remaining literal recognizer count is still quadratic because frontend
reconstruction still presents repeated prefixes. This focused change removes a
large downstream cost without claiming to solve all pattern representation costs.
The first probe's `nativeContinuationNames` regex accidentally looked for
lowercase names while emitted names are uppercase; its retained zero values are
not used. The actual function-entry `nc_let` counters above are independent.

## Correctness and actual native result

- Candidate02 is a genuine checked B1 build and guarded equality derivative.
  The default 21-row paired gate passes, retaining the same 12 known exact
  diagnostic differences.
- Sixteen private run-count controls cover 0, 1, 2, 256, 257, 300, U32max−1 and
  U32max, each with zero or one additional constructor. Five closed constants
  retain `NWord` output. All pass in `pattern-raw-02`.
- Six paired raw identity controls compare erasure exactly for native and
  user-owned same-spelling constructors, open/closed tails, and malformed arity.
  User-owned constructors stay encoded and unchanged by the candidate. All pass
  in `pattern-identity-03`.
- Six actual checked-emitter expression controls and 136 compiled C U64
  arithmetic controls pass in `pattern-arithmetic-02`. Values include 0,
  U32max, the native 2^48−1 cap and U64max, with neighboring values and offsets
  0/1/2/3/255/256/257/300. The C oracle compares exact value/error results against
  iterative checked increments. It models fail-on-first-error and does not
  replace the source/backend gates or prove GPU behavior by execution.
- The source boundary selection covers dynamic offsets beyond U32 values,
  exact Nat cap and overflow, erased versus unused-live overflowing arguments,
  private-tag constructor collisions, compiler-owned Nat refusals, malformed
  literal pattern arity, ordinary/default/month patterns, existing Nat boundary
  fixtures, and imports of Base. The retained first vector plus corrected retry
  is 37/37 passing observations for each compiler; every row records its actual
  originating report in `pattern-audit-03`.
- The dynamic-tail/open-Array fixture checks successfully, then both JS/native
  compilation refuse with exact `Error: an open Array element type`, phase
  `compile`, `checked:true`, `typeAccepted:true`, exit1. The audit compares all
  these fields, guarding against skipping live tail dependencies.
- Actual canonical Nat300 emission/build/run passes in `pattern-native300-02`.
  Emission is 9.285s in this concurrent development observation, including
  layout0.511s; Clang16 `-O3` builds in 2.319s; execution exits0 with stdout
  `306n\n` and empty stderr. Emitted C is exactly the same SHA as the instrumented
  candidate probe. The inherited previous Clang attempt hit its 90s deadline;
  no ratio is inferred from that timeout.

## Failed attempts retained

Candidate01's raw zero-count call produced 4,294,967,296 increments instead of0
because `count-1` underflowed. `pattern-raw-01/report.json` and the complete first
checked candidate remain intact. Candidate02 adds the zero-count identity guard.

The first complete boundary vector `pattern-gate-02` did not pass. Its native
build rows hit the environment's known pipe-backed Clang `EPERM`; its execution
refusal had used a check-only acceptance oracle, and its malformed-pattern oracle
expected checking rather than parsing. No observation was dropped or overwritten.
`pattern-repair-selection.mjs` produces an explicit corrected 37-row selection
and a 14-row retry. With the permitted native launch, `pattern-gate-03` passes
14/14 rows in each compiler and retains one known malformed-pattern diagnostic
difference. `pattern-audit-03` combines only affected/retried rows, checks exact
open-array refusal fields, and verifies 37/37 passing rows for both compilers.

The first raw identity tool supplied Bool objects to a checked JS image whose
native Bool ABI is a primitive; both baseline and candidate therefore interpreted
the supposed false owner as truthy. `pattern-identity-02` retains that failed
vector and `tool-original.mjs`. The corrected primitive-Bool tool and fresh
`pattern-identity-03` pass all six controls. This was a raw-harness ABI error,
not evidence that checked source admitted a custom native Nat constructor.

## Identities and reproduction

All paths below are relative to `selfhost/`. Each probe stores its input hashes,
exact child commands, output/error files and deadline result. The principal
identities are:

| Input | SHA256 |
| --- | --- |
| Phase10 selected API | `ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9` |
| Candidate01 selected API | `13920a4e0a0f94edf1dc2870041a49694b50eb68a31e4b2426e88ba617824bd1` |
| Candidate02 selected API | `78601acae6066f68c16f053b9742adb3d23a9d1df5ca73343fa6927aaa032b1c` |
| Baseline bridge source | `dcad3551dec61fbd2caa966eb9e310b07b83629e34c09ef1ab5c06b507518460` |
| Candidate02 checked snapshot bridge | `5c0337ae0e94e8adff750517f5d2ad4366aef06073433121d58a713bdabf4462` |
| Native runtime | `59d293db627c735c32411a40e952e3f2958a9176048d540273486fb21d1b44e7` |
| Canonical Nat300 source | `c9fc41319135a0cd21386252b275551110dc93ea68b0ae7ceb56251c7312e193` |
| Candidate Nat300 C | `98fea0974c8168c4f38e4a90468dd5962b4400608f7b6773bd6bfe635bcec52e` |
| Inherited baseline Nat300 C | `70ec351988836f23b1182dbb7d854627ed6d5265158765a95ea4e2073f32c4d6` |

Preparation is reproducible using `pattern-prepare.mjs` followed by the maintained
workflow build, `pattern-repair-zero.mjs` and a second workflow build. Use fresh
output directories rather than overwriting retained failures. The maintained
`pattern-probe.mjs`, `pattern-raw.mjs`, `pattern-identity.mjs`,
`pattern-arithmetic.mjs`, and `pattern-native.mjs` accept explicit selected API
paths so the final integrated compiler can be verified. The corrected complete
source selection is `build/phase11/pattern-fixtures-corrected-02/full.json`.
The 90s native emission/build bounds and 10s execution bound are unchanged.

As of handoff, no agent-owned compiler jobs remain. Root's combined final build,
full frontend corpus, native boundary gate and exclusive comparison remain the
release authority. Backend microbenchmarks do not settle the checking bottleneck
or the entire conformance frontier.
