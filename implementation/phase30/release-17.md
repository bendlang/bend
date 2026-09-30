# Consolidating the final Phase30 compiler

Status: checked17 is built and its actual small outputs match the selected
runtime experiment. Final measurement, installation and CLI verification remain
pending. This page distinguishes fresh observations from unchanged-input reuse.

## Selected change and identities

The [registry experiment](registration-dispatch.md) passes its prospective
thresholds: RLE takes5.57% less time and the complete-state row5.38% less, both
with disjoint five-sample ranges. Registered scalar helper and long-warmup
Mandelbrot ranges overlap the baseline. RLE still takes3.45% more time than
Phase29 in that experiment. These are exact generated-module comparisons;
they do not establish transfer to every original program.

The selected runtime changes only three fragments: a private monotone Boolean,
its assignment after successful worker registration, and a short-circuit before
the WeakSet lookup when no registration has occurred. The preceding code getter,
the original registered path and public callback representation remain intact.
This adds one runtime line and58 bytes. No new Bend analysis rule is introduced.

| Item | SHA256 |
| --- | --- |
| API | `33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637` |
| Genuine checked parent | `60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469` |
| Assembled Bend source | `678bafd61cff715c3ee2012ef3840ddfe99a2aeb1d81b5345fb3c6e6bfc1757e` |
| JS runtime | `6731308bcddc6faf68d0f2f9988b1299d4d62069fa091e94857f56bded44b3d6` |
| Runtime core source | `e627c44fe788d72fb6f665c29d081376aff1727d5e7cad04da11d61748615ca2` |
| Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

The source/API/parent/Base identities equal16. The fresh checked attempt remains
a guarded version6 derivative of a genuine TypeScript-produced checked parent.
It is not the separately generated H and makes no fixed-point claim.

## Fresh actual-image validation

Checked build plus36 strict focused observations passes in38.092 seconds.
The actual17 RLE, helper, row and original Mandelbrot modules are byte-identical
to the experimentally measured flag variants, without normalization. Independent
actual-runtime controls pass22 transition cases,146 public ABI observations,
72 scalar points and nine exact-entry controls.

All ten original library outputs pass in the fresh69.71-second acquisition.
The selected15 upstream JS observations pass in43.61 seconds, and all12 scalar
scaling points pass in2.07 seconds. These are descriptive acquisition durations
overlapping other correctness work, not controlled speed comparisons.

The maintained runtime suite passes numeric/readback, File, Chan, local TCP/UDP
and Halt behavior in the approved execution context. Its first sandboxed run
failed while using a missing listener after local socket setup; the unchanged
approved invocation passed. Both receipts remain. This does not validate
external networking, all concurrency behavior or GPU execution.

## Explicit reuse boundaries

The independent audit verifies identical API, genuine parent, assembled source,
all65 canonical modules and manifest, Base, Node, driver/adapter and native
runtime inputs against16. The only executable differences are the three exact
JS-runtime fragments. A separate backend README change is documentation only.

The driver returns parse/check and native results before its JS-runtime read.
That supports reusing the completed3026 main/196 broader frontend observations
and the pilot's four check/23 native rows under those unchanged inputs. These
are reused observations, not freshly rerun17 executions. The historical raw
outcomes, explicit module-layout migration and approved native environment keep
their original scopes.

IO interpreter requests fall through to generated JS, so interpreter evidence
is not blanket-reused. All28 interpreter and26 JS pilot rows are being renewed
with17. Additional library/component/HVM and H output correspondence results
will be recorded here when their producers close.

## Size and retained evidence

`inspect-final-complexity.py` recounts the immutable17 manifest:16,778 physical
and14,327 nonblank Bend lines,646,310 bytes,1,844 definitions,640 laws,70 types
and65 modules. These equal16 and are571 physical lines (+3.52%) above Phase29.
The maintained runtime core is234 lines,67 above Phase29; generated concatenation
is not counted again. The58-line bootstrap diagnostic wrapper and338-line guarded
derivation tool are separate support code. Experimental tools/reports are
excluded from those compiler-source totals.

Canonical fresh receipts live under `selfhost/build/phase30/`: `attempt-17`,
`build-launcher-17`, `transfer-17`, `review-registration-*-17`,
`runtime-tests-17`, `runtime-tests-approved-17`, and `metrics-17.json`.
The final capsule must preserve all producers and failed attempts before this
page can claim durable evidence. The [release design](../../design/phase30/consolidated-release.md)
and [conditional integration plan](../../design/phase30/registration-flag-integration.md)
define the remaining installation and evidence gates.
