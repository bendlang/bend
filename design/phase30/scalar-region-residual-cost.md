# Isolate the remaining cost in actual emitted scalar regions

Prospective follow-up after the clean six-way checked-output confirmation.
Attempt07 takes about 0.0378 ms on the selected 128-iteration helper point,
where the earlier disposable literal-shift prototype takes about 0.0072 ms.
Those outputs differ in several mechanisms and semantic protection, so the
difference alone does not identify a cause.

An independent experiment will replace the private helper dictionary with
lexical functions. Keep that spelling ablation separate. This experiment has
two additional interventions on the exact attempt07 fixture output:

1. Bypass only the one `scalarGuard($guards)` test in the worker condition.
   Preserve input validation, exact-entry permission, runtime, helper dictionary,
   loop and generic fallback. This is a diagnostic under unchanged descriptors,
   never a candidate for production. It estimates this entry check's cost at
   these inputs, without claiming that the check can simply be removed.
2. Outline the generic successor fallback into a private lexical function.
   The public callback still reads all original slots once, in the original
   order, then chooses the fast path or calls the outlined body with the saved
   values. Preserve the original body bytes, binding identities, return/bounce,
   helper lookup order, errors and public descriptor shape. The fallback function
   stays private and cannot receive or mutate the original caller's vector.
   This tests whether keeping a large cold body next to the loop obstructs host
   optimization, without weakening admission or changing the loop.

Derive exact byte-checked modules before execution, with changed-site assertions
and independent fixture results. Bypass-only controls use ordinary unmodified
host inputs and must be labelled as such. The outlined variant additionally
needs the existing pre-worker ordinary ABI, raw callback, reentrancy, descriptor
mutation, entry and ordering controls. Any mismatch blocks compiler adoption.

Measure the existing 128-iteration point first. If entry-cost versus loop-cost
remains uncertain, prospectively freeze additional counts 1, 16 and 1024 with
seed 524800 (zero complex coordinates); the independent expected result equals
the count. Report lifecycle/warmup windows and exact module identities. Do not
mix these interventions with lexical helpers until each has been isolated.

If outlining wins, use the current fallback emitter in one private function,
and pass saved scalar slots only on the cold path. It must remove duplicated
responsibility rather than introduce another generic evaluator. If guard cost
dominates, prefer a larger proven pure region that amortizes the check; preserve
the existing mutable-public-descriptor contract.
