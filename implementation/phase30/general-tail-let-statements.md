# General tail-Let generated-code experiment

The disposable actual13 rewrite passes its focused semantic gates. Longer
timing supports the already accepted private-helper change; it does not justify
extending statement emission into generic callbacks. No maintained
compiler or runtime source changed for this experiment;
attempt14's separate private-helper-only change belongs to a different test.

The Acorn derivative replaces complete returned generated Let-IIFEs with nested
statement blocks. All RHS values execute before source binders enter scope;
comma-expression temporary initializers preserve anonymous function/class
names. It refuses mutable parameters and dynamic eval, keeps the 47,937-byte
runtime prefix exactly, and reconstructs every original module by reversing
the recorded patches. Independent static review by the analysis agent found
no semantic blocker within the declared stack/source-observability scope.

| Checked source | Tail Lets / returned chains | Original bytes | Rewritten bytes |
| --- | ---: | ---: | ---: |
| Original Mandelbrot | 58 / 19 | 110,700 | 112,153 |
| Original editdist | 11 / 6 | 82,492 | 82,806 |
| Closed owned-row source | 15 / 7 | 83,290 | 83,733 |

These are generated-output changes, not a source-line simplification claim.
The owned-row source was freshly checked with attempt13 in
`review-tail-let-row-source-13`; it emitted exactly the earlier checked row
bytes. Derivations are `review-tail-let-{mandel,editdist,row}-01`.

Retained passing results:

- `review-tail-let-synthetic-01`: 25 independent scope, name, error-order,
  escaped-closure and lexical this/arguments/new.target cases; 15 refused forms.
- `review-tail-let-scalar-01`: 146 complete ABI/prototype observations and 72
  scalar oracle values; `review-tail-let-entry-01`: nine entry/reentry cases.
- `review-tail-let-tree-01`: 85 ordered public tree boundaries;
  `review-tail-let-ordinary-01`: 92 oracles and 225 host observations.
- `review-tail-let-owned-01`: 28 full four-array states, eight alias cases and
  257 public boundaries; `review-tail-let-deferred-01`: 27 saved-bounce,
  later-mutation and explicitly aliased-array observations.
- The complete original editdist candidate returns `2065873279` at bench(2,0),
  retained as an untimed correctness check under `review-tail-let-timing-plan-01`.
  The ordinary oracle gate includes the original Mandelbrot result `887240761`.

Only module labels and the inapplicable private-region admission-sentinel block
were adapted in the inherited owned-row controls. Both sides receive the same
JSON export adapter; full state comparisons remain inside every timed call.
The original control tools and adapted bytes are frozen by
`review-tail-let-controls-plan-01`.

Use `review-tail-let-timing-plan-02` for timing. The first unexecuted plan named
a nonexistent generic `time.py` launcher; fresh plan02 verifies all prior input
identities and binds the existing `prototype-time.py` and long-warmup runner.
The promotion criterion was frozen separately before timing in
`design/phase30/general-tail-let-promotion.md`. A whole-program gain must be
distinguished from attempt14's private Let improvement before widening the
maintained emitter.

`general-tail-let-screen-01` passes both cases (8.63 seconds outer duration):

| Case / side | Median ms | Sample minimum–maximum ms | Timed-half changes |
| --- | ---: | ---: | --- |
| Owned row32 baseline | 0.861136 | 0.857640–0.874892 | +45.7% to +47.2% |
| Owned row32 rewritten | 0.742376 | 0.740853–0.746563 | −27.7% to −26.6% |
| Mandelbrot baseline | 0.371838 | 0.369763–0.372387 | +4.6% to +8.4% |
| Mandelbrot rewritten | 0.314953 | 0.312987–0.317963 | −33.0% to −31.7% |

Opposing, substantial timed-half drift prevents interpreting the apparent
median gains as settled speedups. The already frozen longer-warmup comparison
is the appropriate next discriminator; no promotion follows from this screen.

`general-tail-let-long-confirm-01` completed both cases in 258.69 seconds:

| Case / side | Median ms | Sample minimum–maximum ms | Timed-half changes |
| --- | ---: | ---: | --- |
| Owned row32 baseline | 0.593619 | 0.582747–0.613484 | −0.613%, +0.385%, +6.377% |
| Owned row32 rewritten | 0.579921 | 0.579862–0.582336 | −0.568%, +1.167%, −1.113% |
| Mandelbrot baseline | 0.247023 | 0.246233–0.248267 | +0.226%, +0.161%, −0.780% |
| Mandelbrot rewritten | 0.215495 | 0.214308–0.219399 | +1.758%, +0.320%, −0.055% |

Row time falls only 2.31%, below the prospectively frozen 10% requirement.
The whole-program reduction is 12.76% (1.1463×), but its 0.215495-ms result
closely matches the separately measured checked attempt14 private-helper-only
result of 0.215416 ms. These different windows do not prove equality or isolate
an incremental effect. They provide no reason to widen the maintained rule
without a new direct attempt14 comparison. Recommend retaining the private
change and deferring the generic extension. The conditional minimal compiler
proposal and unexecuted checked-source control fixture remain available for
future work; their presence is not an implementation claim.
