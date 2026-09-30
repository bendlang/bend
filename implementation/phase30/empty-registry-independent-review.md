# Independent review of the monotone exact-code registry guard

Static review finds the proposed guard sound under the runtime's existing
standard-intrinsic scope. The initial static reasoning is retained below; the
subsequent independent control results are recorded at the end. The [prospective design](../../design/phase30/registration-free-exact-dispatch.md)
keeps the registered callback path intact and only omits a WeakSet membership
lookup before the first successful private registration.

The ordering requirement is precise: invokeExact must first perform its original
`const code=f.code`, then read the private Boolean. Every earlier apply read,
including code truthiness, bound-vector operations and arity getters, can register
or reenter code. The selected code getter can itself return a newly registered
callback. Reading the flag before that getter would misclassify this legitimate
exact entry. Setting the flag after native exactCodes.add succeeds and before
returning the new callback preserves the empty-registry invariant.

A later code.call or environment getter can register another callback, but it
cannot retroactively change the membership decision for the current invocation.
The old path already selected generic invocation before these reads. Leaving the
original fallback expression and registered metadata checks/token installation
unchanged preserves method-before-environment ordering, callback shape and finally
restoration. WeakSet entries can disappear after garbage collection; a monotone
true flag only retains an unnecessary check in that case, never a false negative.

The registry is private per runtime module. A registered callback obtained from a
separate module is not registered locally and receives no local permission.
Saved partials keep the same callback identity; raw and oversaturated entries
remain unprivileged. The flag adds no public descriptor field. Skipping a patched
WeakSet.prototype.has hook is outside the declared standard-intrinsic contract;
public descriptor and code.call mutations remain within the reviewed scope.

The independently authored review-empty-registry-controls.mjs was prepared
before acquisition. It imports a fresh diagnostic runtime per case so early tests truly
start with an empty registry. It covers registration during first/second code
reads, bound/arity/copy reads, reentrant registration and throws, late call/env
registration, token consumption/restoration, raw/partial/oversaturated/owned
entry, own call hooks, regular/arrow callable shape and separate-module registries.
Baseline and candidate values and ordered events must agree, and the controls
also assert the intended entered flags. Generated-program numeric/ABI controls
and exclusive performance measurements remain separately required.

The subsequent static read of inspect-registration-dispatch.mjs and its RLE
controls is also favorable. The full Acorn identifier/use audit conservatively
rejects private registration/registry escapes or shadowing; quoted compiler
strings are excluded as data. The direct diagnostic is emitted only for a
zero-registration-call module, while the general flag keeps its existing
registered path. Exact inverse edits, unchanged generated suffixes and complete
module parsing bind the intervention. RLE controls check full runs/expanded
lists and ordered method/environment/metadata observations. No derivative or
control execution is implied by this static approval.

## Independent acquisition on checked16 derivatives

Under the parent's correctness-only grant, CPU6 ran the unchanged prepared tools
against the exact P30-030 generated-JavaScript derivatives. All four receipts
completed successfully:

| Receipt under selfhost/build/phase30 | Scope | Result |
| --- | --- | --- |
| review-registration-transition-16/report.json | Fresh runtime per case; registration, ordering, token, shape and cross-module boundaries |22 exact cases |
| review-registration-abi-16/report.json | Registered Mandelbrot helper; public descriptors, getters, coercion, prototype hooks and values |146 observations +72 scalar points |
| review-registration-entry-16/report.json | Raw/exact reentry, call/env ordering and finally restoration |9 observations |
| review-additional-js-policy-01/report.json | Separate backend policy-only negative controls; no fixture execution |22 cases |

The runtime transition receipt binds registration-dispatch16-rle's baseline and
flag runtime prefixes. The ABI and entry receipts bind the baseline/flag modules
in registration-dispatch16-helper. Complete source/tool hashes are in each
receipt, and review-registration-helper-plan-16/config.json preserves the shared
configuration. No observation was skipped or normalized; all16 prototype-hook
observations were enabled in the ABI suite. These are disposable derived runtime
controls, not a new checked compiler artifact or a performance result. CPU6 was
released immediately after these bounded controls. The optional811 fixture
campaign remains unexecuted.
