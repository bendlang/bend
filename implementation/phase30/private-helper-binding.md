# Private helper binding form: no promotion evidence

The compiler keeps ordinary private function declarations. Replacing them with
constant function-expression or arrow-function bindings showed no useful gain
in the prospectively frozen screen. This result does not prove equal steady
performance: the timed halves drifted, particularly on the complete program.
It does mean this experiment supplies no reason to change production emission.

The [design](../../design/phase30/private-helper-binding.md) isolates binding
form. `private-binding-derive.py` starts from checked attempt12 outputs, changes
14 helper declarations in the scalar fixture and 31 in original Mandelbrot,
retains parameter/body bytes and checks exact reverse reconstruction. Public
callbacks, guards, runtime, direct call sites and numeric representation remain
unchanged. These are disposable JavaScript variants, not compiler versions.

Correctness gates pass:

- 121 scalar oracle points across all three variants, six raw host cases and
  three retained-partial observations. The existing 10,006 representability
  checks are retained but do not validate a representation change here.
- 92 original pixel/recolor/program points and 225 paired ordered public
  observations, plus 85 supplemental tree boundaries.
- An [independent lexical audit](private-helper-binding-independent-review.md)
  verifies no escaping private values, constructor/property uses or calls during
  initialization. Separate copies exercise 129 forward-reference edges across
  six exact-result runs.

`private-binding-plan-02` binds those first three gate reports before timing.
The independent audit is retained separately in `review-private-binding-01`.
The earlier plan01 created the exact adapted control tools; plan02 is the
maintained generator's gate-bound timing configuration.

| Same-window screen, ms/call | Declarations | Const function | Const arrow |
| --- | ---: | ---: | ---: |
| Scalar helper, 128 iterations | 0.00746289 | 0.00750067 | 0.00753169 |
| Original Mandelbrot, bench(2,0) | 0.404752 | 0.407498 | 0.408086 |

All output ranges overlap. Helper halves improve approximately 10% during the
sample; whole-program halves vary approximately −28% to +11%. The whole
baseline range is 0.373442–0.484070 ms, much wider than the median differences.
The clean screen took 12.54 seconds including checks, calibration and fresh
processes. Raw samples and hashes are in `private-binding-screen-01`; no
instrumented module was timed. No confirmation or compiler edit is justified
by this screen alone.
