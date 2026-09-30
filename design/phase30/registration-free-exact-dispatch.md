# P30-030: discriminate exact-dispatch cost before any registration

This prospective generated-JavaScript experiment addresses the retained
checked16 RLE regression. It does not change production source, install a new
compiler or reinterpret the completed final16 matrix. The
[static diagnosis](../../implementation/phase30/rle-runtime-regression.md)
records10.30% more time than Phase29 and identifies the unregistered exact-call
path as one plausible mechanism, separate from selected-arm retirement.

Freeze the exact original RLE checked16 emission, its receipt, original source,
Phase29/pinned TypeScript comparison bytes and this design before derivation.
Use the same `main.out()` point returning11 and unchanged original List input.
An AST audit must establish zero registration call sites in the complete module:
the only `exactCode` binding is its runtime declaration, all references resolve
to that binding, and none is a call or escapes as a value. Likewise `exactCodes`
is the private original WeakSet, used only by its declaration, registration
helper and exact-dispatch helper. Reject eval/with or unexpected registry uses.
An empty-registry claim must be proved from the module, not inferred from a
counter on one input.

## Independent variants from one checked16 origin

1. **Unchanged16.** Exact original module and public output adapters.
2. **Registration-free diagnostic.** Replace only `invokeExact` with
   `function invokeExact(f,all){const code=f.code;return code.call(f.env,all);}`.
   The helper boundary and the original selected-arm behavior stay intact.
   This variant is scoped to the statically proved registration-free module.
3. **General monotone-registration flag.** Keep the complete original helper
   and registered path. Add a private Boolean initially false; set it true
   immediately after the original successful `exactCodes.add(code)` and before
   returning the new callback. Change only the first predicate to
   `!hasExactCodes || !exactCodes.has(code) || ...`. No other check, code shape,
   permission token, callback or WeakSet operation changes.

The general variant is valid even for a module whose workers register lazily.
Before any successful registration, the private WeakSet is empty. A code getter
that registers a worker runs before reading the flag, because `const code=f.code`
stays first. If registration occurs later during `.call` or `env` lookup, both
original and changed dispatch have already selected the generic branch, so that
invocation receives no new permission. Once true, the flag never returns false,
even if registered functions become unreachable. Synchronous JavaScript gives no
interleaving between the native add and flag assignment. Normal callback identity,
name/length/constructibility, the code read count, method-before-env order, token
consumption and finally restoration remain unchanged.

The scope retains the existing standard intrinsics contract, including native
WeakSet methods. Skipping a replaced `WeakSet.prototype.has` hook is not promised
equivalent. Do not silently broaden that contract into arbitrary mutated host
intrinsics. Public function-descriptor/code.call/environment mutations and raw
callbacks remain covered; they are not excluded by this scope.

The general flag derivative also needs actual16 scalar-helper and original
Mandelbrot copies. These register private workers and act as negative controls
for the additional branch after registration. Do not apply the registration-free
diagnostic to them. A source compiler/runtime patch remains unselected until
correctness and isolated measurement justify it.

## Correctness before timing

Derivation must use exact matched original runtime text, parse complete modules,
record original/generated hashes and byte edits, and invert each edit to recover
the original module. Except for the declared runtime edits, every emitted byte
must remain unchanged. Save generated candidates and any failed attempt.

For the general flag variant, run the existing146 public ABI observations and
nine entry observations on the registered helper against unchanged16, plus
focused ordered controls for these state transitions:

- ordinary exact call before any registration;
- first registration, direct raw call and exact entered call afterward;
- registration inside the second `f.code` getter, returning that new code;
- registration inside `.call` and `env` getters, which must not retroactively
  authorize the already selected generic invocation;
- nested entry, same-vector reentry, thrown inner code and restored permission;
- custom callable/noncallable `.call`, descriptor getters and their raw error
  strings, preserving the accepted current-runtime selector text;
- fresh callback identity/name/length/constructibility before and after the flag;
- saved registered callbacks interleaved with ordinary calls and another module's
  callbacks, which are absent from this module's private registry.

Any diagnostic export used to create/inspect private registered callbacks belongs
only to separate general-flag control copies. The registration-free direct
diagnostic cannot expose such a registration capability without invalidating its
proof; its host controls use only ordinary, unregistered public descriptors.
Timed modules expose exactly their original exports. Compare the fixed RLE
result11 and additional empty/single-run/mixed-run
List cases against an independent ordinary-JavaScript oracle, retaining full
lists or pair lists rather than only a checksum. Reuse scalar numeric/public
controls for the registered negative-control modules. A known scheduling witness
must still reject the retired eager prebinding; this experiment does not restore it.

## Small clean measurement

After root grants correctness acquisition, freeze a cheap RLE screen comparing
Phase29, unchanged16, registration-free diagnostic, monotone flag and pinned TS.
Use the established maintained sampling protocol; confirm any apparent benefit
with three-second minimum warmup and retained half drift/sample ranges. A
comparison of unchanged16 versus the general flag on helper128 and original
Mandelbrot guards against simply moving cost into registered workloads. Use the
existing longer warmup for Mandelbrot if that point is timed.

Accept no performance conclusion from source size, static calls or the empty
registry proof. The clean result must show which intervention changes the RLE
point, and any registered-workload regression must remain visible. Do not combine
this with vector-copy, matcher or ABI changes. The minimum first decision is
whether the residual RLE loss comes from this exact-dispatch predicate at all.

Prospective selection criterion, set before any P30-030 timing: the **general
flag** must reduce the unchanged16 RLE median by at least5%, with disjoint five-
sample confirmation ranges. Registered helper and original Mandelbrot negative
controls must not show more than3% slowdown beyond sample variation. Preserve
warmup drift and all outcomes; the registration-free direct diagnostic winning
alone is insufficient to promote the general rule. Root retains the final
selection decision after these correctness and measurement gates.

## Bounded generated-compiler functional transfer

If the complete AST audit also proves original H registration-free, derive its
general-flag copy using the same tool. It remains a manually modified diagnostic
of H, never a checked development attempt or a newly self-emitted compiler.
Before any optional H-flag performance comparison, run separate90-second Base
and small-oracle gates with the original8GiB heap/4MiB stack limits. Use its actual
file hash to create or validate a genuinely checked Base cache. Compare the same
positive/negative observations, emitted positive JavaScript and result8 to the
retained original-H oracle. No H→H or compiler self-emission is needed.

Derive a narrowly changed copy of the existing small oracle: replace only its
checked-emission admission block with exact source-H/derivation/flag identities,
and name the report as a manually derived runtime diagnostic. All ABI, Base,
driver, fixture, execution and observation checks remain. Preserve the original
worker and consumed derivation; do not fabricate a checked-emission receipt for
the flag module. This functional acquisition is separately granted after clean
timing and is not a performance measurement.
