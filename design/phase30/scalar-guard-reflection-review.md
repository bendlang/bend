# Independent guard reflection-sequence diagnostic

Before executing the fixed-list candidate, compare its complete reflection
sequence with the unchanged core. Append only private test exports to fresh
diagnostic copies of the frozen baseline/candidate cores. Capture ordinary
two-descriptor closures before instrumentation, then install supported public
metadata/prototype mutations or accessors.

Temporarily wrap Object.getOwnPropertyDescriptor, Object.getPrototypeOf and
Object.hasOwn to log their target/key sequence and delegate without changing
results. Label returned descriptor records by the target/key that produced
them. These wrappers are diagnostic instrumentation under otherwise unchanged
behavior, not an expansion of the standard-intrinsic production contract.
Restore every intrinsic synchronously in finally before serializing evidence.

Compare exact acceptance values and complete ordered traces for successful,
empty, missing and repeated closures; live G accessors/replacements/Proxy;
each metadata getter/deletion/change; code.call hooks; descriptor/code
prototype changes; captured bound length changes; primitive/Object marker
hooks and wrong primitive prototype chains. Require that guards never invoke
the deliberately installed accessors. Existing owner-run semantic suites cover
generic fallback behavior separately.

No benchmark or compiler edit is part of this diagnostic. Any sequence or
acceptance difference blocks this candidate pending explanation.
