# Worker lifetime and registered callback fusion

Both isolated generated-output ablations pass the focused semantic controls,
but neither shows a material warm-execution gain in the long confirmation.
Defer both implementation changes. No production compiler or runtime source was changed.
The plan is [registered-worker-entry.md](../../design/phase30/registered-worker-entry.md).

The baseline is checked attempt07's helper fixture. The hoisted variant moves
the private worker implementation into the existing definition IIFE, retaining
a fresh exactCode wrapper whenever the successor arm is selected. The fused
variant instead creates a fresh anonymous one-argument ordinary callback,
registers it with the existing exact-entry runtime, consumes its permission
before reading arguments, and executes the original worker body directly.
The interventions are separate; neither removes guards, changes helper spelling,
outlines fallback, or changes arithmetic.

| Module in review-entry-lifetime-01 | Bytes | SHA-256 |
| --- | ---: | --- |
| baseline.mjs | 76,612 | 8e9317debb126b7296b67795e3bca8aba871895b1b8ed15e93458f3c03e271a8 |
| hoisted.mjs | 76,654 | a4bfe2c607f2b403cb638e3307f239192a94e4dfa690210dcfa8c95ae1c0d6c7 |
| fused.mjs | 76,968 | 25146d7d99e4f0d5421c0de8c77d54c5c7d3b22307c2eab257909ffb19833418 |

The exact 2,985-byte worker body occurs once in each derivative. The fused
variant adds only private registration and permission-consumption helpers;
invokeExact, apply, token installation after environment reads, and finally
cleanup retain their baseline bytes. Permission still matches callback and
argument-vector identity, and is single-use before any slot getter can reenter.
The current worker admission starts at a top-level native Nat matcher with no
captured preceding lambda, so moving its private implementation introduces no
new caller-dependent environment. A derivation assertion rejects this, arguments
or eval dependence in the copied body.

Fresh CPU6 controls are retained under `selfhost/build/phase30/`:

- `review-entry-lifetime-controls-01`: 121 scalar points across all three
  modules, plus five differential callable/identity boundaries.
- `review-entry-lifetime-hoisted-abi-01` and `review-entry-lifetime-fused-abi-01`:
  each passes 146 ordinary ABI/effect/prototype observations and 72 independent
  arithmetic/long-loop observations.
- `review-entry-lifetime-hoisted-entry-01` and `review-entry-lifetime-fused-entry-01`:
  each passes nine entry, reentrancy, hook-order and exception-cleanup cases.

The added identity controls create two saved partials, require distinct public
code functions, and mutate their call methods/getters independently. They also
compare name, length, own property descriptors, function prototype and
constructibility. Raw callers cannot gain permission with an extra true argument,
and construction invokes the same unprivileged generic callback behavior. Existing
entry tests cover same-vector reentry while slot getters run.

A second investigator independently reviewed both derivations and found no
blocker in the frozen fixture. The private body captures only the definition's
existing helper table, guards and module references, with no per-match lexical
binder. Any production generalization must retain this proof and exclude
dependence on this, arguments, eval or new.target; the pinned body uses none.

The lead's measurement agent ran the frozen protocols in the exclusive CPU3
slot. The selected point remains bench(128,524800), expected result 128.

| Five-process long confirmation | Median | Range | First-call median |
| --- | ---: | ---: | ---: |
| Unchanged | 0.037771 ms | 0.037256–0.040419 ms | 2.293 ms |
| Hoisted private implementation | 0.037546 ms | 0.037423–0.038007 ms | 2.064 ms |
| Fused registered callback | 0.037950 ms | 0.037402–0.038576 ms | 2.336 ms |

All warm ranges overlap and timed-half changes stay within 2.83%. Hoisting's
lower first-call median is retained as a separate lifecycle observation; it does
not establish a warm-throughput improvement. The earlier short screen measured
0.044198, 0.042426 and 0.042829 ms, respectively, with all variants improving
about 18–22% between timed halves. The later settled window does not confirm
those small apparent gains. No sample or window was discarded.

Raw results are `entry-lifetime-screen-01/report.json` and
`entry-lifetime-confirm-01/report.json` under the Phase30 build directory, with
launcher receipts and individual processes. The long confirmation records
62.80 seconds within the maintained harness. Public Function source text and
engine stack traces remain outside the equivalence claim.

The earlier CPU profile attributes many samples to enterExact's call site. That
can include inlined or imperfectly attributed worker execution; it does not
measure token-check or dispatch cost directly. These negative isolated ablations,
together with the positive unchanged-entry lexical-helper experiment, make that
distinction concrete. Keep the established exact-entry implementation and pursue
the separately demonstrated helper-binding improvement.
