# Keep ordinary exact calls inside apply

Prospective response to the final14 original-program matrix: the root observed
roughly20–25% regressions on several generic workloads despite the large scalar
Mandelbrot gain. Release14 is held while independent runtime interventions test
that result. This ablation changes emitted JavaScript only, not compiler source.

Every exact application currently enters `invokeExact`, which then reads
`f.code` and tests the private `exactCodes` WeakSet. Most ordinary callbacks are
unregistered and immediately execute `code.call(f.env,all)`. The hypothesis is
that moving this ordinary branch back inside the already hot `apply` function
avoids a newly introduced call/optimization boundary. It does not eliminate the
WeakSet test, weaken any metadata predicate or predict a particular gain.

Replace only the exact branch and the registered helper's entry:

```js
if(all.length===f.arity){
  const code=f.code;
  if(!exactCodes.has(code))return code.call(f.env,all);
  return invokeExact(f,all,code);
}
```

`invokeExact(f,all,code)` receives the already captured value and starts at the
existing `Object.getPrototypeOf(code)` predicate. Its remaining checks, actual
`.call`/environment reads, token installation and `finally` restoration remain
byte-identical. The only removed condition is the WeakSet test already performed
at exactly the preceding invocation boundary.

The first `f.code` validity read in apply remains unchanged. The second read
still occurs **after** the exact length/arity decision, once. The unregistered
path retains the exact `code.call(f.env,all)` expression, including method receiver,
`.call`-before-`env` order, raw error text and exceptions. An arity getter may
change the selected code; a code getter may reenter; an environment getter may
mutate the method after its lookup. All must retain their original observations.
Registered callbacks remain privileged only through the existing unchanged entry
checks, and partial/oversaturated calls retain their exact old bytes.

Independent static review finds this read order coherent under the existing
stable-intrinsic scope. Function source text and diagnostic stack locations are
not preserved, as in the earlier runtime experiments. No registration removal,
token representation change, generic matcher rewrite or scalar-guard allocation
change belongs in this first variant.

`inspect-inline-exact.py CONFIG FRESH_OUT` accepts a frozen actual14 module map.
Each module must have an adjacent checked emission receipt bound to the selected
attempt; its runtime prefix must equal the attested runtime. Freeze unchanged
and changed bytes, the two exact substitutions, reversible reconstruction and
every input identity before controls. The derivation executes no generated code.
New checked14 and Phase29 owned-row emissions will come from the measurement
owner; do not relabel the old checked13 row emission. Whole original modules and
the scalar helper are already available through actual14.

Controls precede timing: same-runtime146 ABI/prototype +72 arithmetic observations,
nine exact-entry/reentry cases; the91 actual-method getter/error controls adapted
to require unchanged permission decisions on both sides; independent121 helper
points; focused ordinary-call descriptor/arity/code/method/env traces; complete
28-state owned-row/alias and public-boundary observations. Check original editdist
and Mandelbrot results without changing their workload. Retain every failed
control and stop promotion on a semantic difference.

The first cheap comparison is the complete owned row32/seed17, with Phase29,
actual14 and this isolated actual14 variant. Use the existing short screen, then
maintained confirmation if useful. Include the helper and original Mandelbrot
as a regression boundary; use the previously frozen15-second whole-program warmup
when needed. No100-call-floor confirmation on original editdist. If the cheap
fixture supports the hypothesis, independently renew the affected original points
with the existing transfer protocol. Never multiply this result by another
runtime ablation's gain. Root grants every execution/timing window separately.
