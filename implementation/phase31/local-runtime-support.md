# Runtime support for private local data

The runtime now snapshots the original `Array.new`, `Array.get` and `Array.set`
descriptors when those canonical native registrations are constructed. Their
actual runtime arities remain 3, 3 and 4; erased type arguments have not been
removed from the public ABI. Compiler-side native provenance checks remain a
separate admission obligation. A matching name alone does not authorize the
compiler to specialize an arbitrary user definition.

`localGuard(names)` first rejects changes to the saved Array prototype's parent
or own `request`, `bounce`, `build` and `code` markers. It then uses the existing
`scalarGuard` descriptor, function, bound-argument, environment and primitive
prototype checks. This is the same Array marker condition used by the retained
Phase 30 private/native diagnostic, now available to generated local regions.
It assumes the existing standard-intrinsics contract. It does not replace an
escape or demand-order argument.

Only `selfhost/src/runtime/js/core.mjs` was edited for this subtask. `apply`,
`force`, the native array helpers and ordinary native calling conventions are
unchanged. The generated `src/runtime.mjs` bundle is left to the parent build.
The validated core fragment is SHA
`61c20228aaab7a68d77a3119cacd0afacf70d60cb1fd79b262e303995b874bac`,
13,492 bytes.

The owner-written focused controls pass **55 observations** against the exact
current core and base fragments: original arities, public native storage/alias
behavior, replaced globals, saved native arity/code/environment/bound changes,
nonempty bound arrays, descriptor prototypes, own `code.call`, global and
field accessors, all four Array markers, changed Array prototype ancestry,
existing primitive marker refusal, and restored successful admission. Accessor
refusal checks assert that the getter was never invoked. This is focused owner
validation, not an independent review or full compiler-conformance claim.

The CPU 2 correctness acquisition completes in 0.216 seconds with exit 0;
that duration is not timing evidence. Raw input identities, the exact
concatenated test module, consumed controls and all case results are in
`selfhost/build/phase31/review-local-runtime-01/`; bounded outer output and
receipt are in `review-local-runtime-launch-01/`. The maintained command is:

```text
python3 selfhost/tools/performance/phase30/run.py --timeout 30 --cpu 2 OUTER \
  NODE selfhost/tools/performance/phase31/review-local-runtime.mjs \
  selfhost/src/runtime/js/core.mjs selfhost/src/runtime/js/base.mjs OUT
```

Use fresh output directories and the pinned Node executable. Actual generated
local-region emission, its guards and its semantic boundaries still require
the parent's integration and independent controls.
