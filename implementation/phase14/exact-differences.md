# Phase14 exact differences: checker caret rendering

The bounded renderer correction is ready for root integration. It makes **71 of
78 selected checker observations exactly match pinned TypeScript**. All 78 retain
their original validation refusal and non-diagnostic result axes. The remaining
seven expose existing source-origin errors; they remain strict failures. This
workstream changes only `selfhost/src/diagnostic/render.bend` in an isolated
snapshot. It does not change the installed compiler or claim a full-corpus result.
Root's combined integration report supplies those decisions and gates.

The frozen [family plan](../../experiments/phase14/P14-002-family.md) follows
[P14-002](../../experiments/phase14/P14-002-exact-differences.md). The current
candidate is `selfhost/build/phase14/differences-build-02`; its checked B1 and
version 5 equality derivative remain distinct:

| Artifact | SHA-256 |
| --- | --- |
| Checked B1 | `d9d7db7b44be8adacdefd876b90ac290703281c0374ad0f01269f831511797fd` |
| Selected derivative | `5245be73765e04b85ee1a897cf6330e256159d687692ab60f8881ec69e123233` |

The patch is retained at
`selfhost/build/phase14/differences-prepare-03/render.patch`; root can apply the
single final snapshot module. It adds **30 physical lines, 1,202 bytes and 3 definitions**:
184 → 214 lines and 5,198 → 6,400 bytes. No maintained JS/helper/runtime change is needed.
Experimental census/control scripts are additional research tooling, not counted
as compiler-source reduction.

## Census and ranked causes

The retained Phase12 comparison contains 730 differing observations over 532 unique
fixtures: 198 parse observations and 532 check observations. It compares the unchanged
pinned reference `selfhost/build/phase8/reference-frontend-01/reference.json` with
`selfhost/build/phase12/frontend-03/candidate.json`, using the original strict-path
comparison. The census preserves every original string, verdict, evidence and
result axis. Its normalization is only a classification aid; no comparison or
pass/fail oracle is weakened.

`selfhost/build/phase14/differences-census-01/report.json` records these disjoint
observation-shape clusters. Fixture counts within different clusters can overlap
because a fixture has two observations; do not add that column.

| Descriptive cluster | Observations | Unique fixtures in cluster |
| --- | ---: | ---: |
| Caret line only, apart from verdict/evidence consequences |210|144|
| Source snippet only |153|153|
| Legacy unstructured error |164|93|
| Non-diagnostic result-axis difference |78|63|
| Same expectation, another observation/detail difference |47|27|
| Computed-match legacy error |26|13|
| Location/span/note difference |9|9|
| Other diagnostic shape |43|30|

652 of 730 observations retain all compared result axes other than diagnostic and
its verdict/evidence consequences. This does **not** mean 652 proved formatting
bugs: different diagnostic bodies may reflect error selection or term rendering.
The 78 non-diagnostic observations include 44 with unsafe-definition/output changes,
18 load-versus-parse phase labels, 6 parse-status/exit differences, 4 unsafe-definition
list differences, 4 imported-law trust/phase differences and 2 parse-versus-check
phase/checked differences. A rejected program reaching a different phase is not
an exact conformance pass.

Ranked concrete families before implementation were:

1. **Checker caret rendering**, selected: 78 checker-phase observations whose
   existing excerpt matches except for the absent marker line. Examples are
   `base/bytes_ops.bend`, `base/heap_queue_deque.bend`, `base/json.bend` and
   `base/parser.bend`. Shared cause is `dg_snippet`/`dg_snippet_lines`, which did
   not consume the already-recorded DSpan end offset. This offers a small change
   independent of validation and error selection.
2. **Parser caret rendering**, deferred: 66 fixtures repeated in parse/check lanes,
   132 observations. `check/array_boxed_default.bend` and
   `parse/duplicate_field_name.bend` illustrate the missing row. The independent
   `fpe_message`/`fpe_snippet` path uses token line/column coordinates rather than
   checker DSpan offsets. Mixing it into this patch would broaden both source
   scope and coordinate contracts.
3. **Missing checker origins**, deferred: 153 snippet-only observations, including
   `check/beta_ann_lambda.bend`, `check/binder_name_capture.bend` and
   `check/cons_tail_mismatch.bend`. Existing structured expected/observed/context
   text matches after removing source rows, but no source span reaches rendering.
   This requires origin propagation; rendering cannot safely invent it.
4. **Computed-match diagnostic construction**, deferred: 26 observations over 13
   fixtures, such as `check/computed_match_split.bend` and
   `flatten/consumed_column_error_001.bend`. The current legacy message lacks
   upstream structured wording and location. This is smaller than repairing all
   legacy errors, but requires evidence about the same first failing condition.
5. **Declaration/trust ordering**, separate work: unsafe-definition order and
   generated helpers affect structured output, while imported-law early failures
   are handled by P14-001. `check/unsafe_field.bend` has reversed unsafe-name order;
   `comptime/unsafe.bend` additionally reports a generated `loop~0`. These should
   not be classified as harmless whitespace or silently normalized away.

The shape clusters establish useful search targets, not independent causal
proofs. Only the selected checker-renderer cause was implemented here.

## Implementation and controls

The inspected reference is pinned `bend2/bend.ts` `err_show`, lines 1466–1495.
It slices the source at a UTF-16 offset, preserves tabs in the left padding,
replaces other code units with spaces and clips the caret count to the current
line. A zero-width/end-of-line span still gets one caret. The Bend DSpan already
explicitly uses UTF-16 units, so the change uses its source/begin/end directly.

The renderer computes the left padding, handles a position inside a supplementary
character as one UTF-16 space, and prints the marker between the current and next
source rows. End-before-begin saturates to zero before the minimum-one rule, so
unsigned subtraction cannot wrap. It reuses existing `U32.min`; no new shared
span or parser protocol is introduced. Missing spans remain missing. Error
construction, term rendering, checker order and proof-trust decisions are unchanged.

Final evidence is consolidated in
`selfhost/build/phase14/differences-final-gates-01/report.json`:

- The genuine checked build and maintained 22-case focused selection pass. That
  selection retains 12 known exact differences under its explicit acceptance/phase
  oracles; passing it is not an exact-diagnostic claim.
- 24 public `diagnostic_render` controls match pinned `err_show` exactly, including
  ASCII, tabs, supplementary Unicode, split-surrogate positions, lone surrogates,
  empty/no spans, EOF, blank lines, CRLF, multiline clipping, reversed spans,
  multi-digit line numbers, notes and message-only errors. Public API suffices;
  the planned private-export view was unnecessary. These synthetic spans test
  rendering, not parser-origin coverage.
- The paired 78-case target completes with 71 exact matches and 7 strict failures.
  Every candidate diagnostic equals its baseline after deleting only the newly
  inserted caret row. All other observed result axes are identical.
- Six paired boundary fixtures preserve declaration-order error priority,
  undefined-name-before-type-error priority, parse-error precedence over an
  earlier invalid type, and two positive accepts. Their candidate observations
  equal the frozen release apart from inserted checker caret rows. One boundary
  diagnostic also becomes exact upstream; that fixture is additional to the
  original 78, not another corpus improvement count. Three other boundary exact
  differences remain visible under acceptance/phase oracles.
- Snapshot comparison finds exactly one changed source file,
  `diagnostic/render.bend`. Execution reports record no spawn error, signal,
  timeout or overflow. Target strict failures remain exit 1, not successful exits.

The remaining seven target mismatches are upstream-origin differences exposed by
the now-visible marker, not failures of marker formatting for the supplied span:

| Fixture | Existing span limitation |
| --- | --- |
| `check/ctor_arity.bend` | Constructor name instead of complete constructor term |
| `check/do_missing_bind.bend` | One-character origin instead of complete bind line |
| `flatten/match_as_term.bend` | One-character origin instead of constructor term |
| `io/channel_send_recv.bend` | Datatype name instead of applied datatype |
| `page/ctor_list_mismatch_000.bend` | Constructor name instead of full term |
| `page/usage_plain_words.bend` | Enclosing constructor origin instead of consumed binder |
| `parse/qualified_constructor.bend` | Qualified name instead of full constructor term |

No origin guessing or wider propagation repair was attempted. Source-span
production is the next separate correctness investigation if root chooses it.

## Attempts, resource scope and preservation

Preparation 01 statically revealed an erroneous proposed use of term-level
`norm_min` for U32 values; no compiler executed that preparation. Its exact tool
and source are retained. Preparation 02 supplied a U32 helper and produced checked
build 01. The 22 focused and 24 direct controls pass; the 78-family gate remains failed
71/78. Preparation 03 removes that redundant helper in favor of Base `U32.min`,
produces checked build 02, and repeats the relevant controls. Both family strict
failures remain intact; neither is relabeled after the partial improvement.

Most builds/probes run on assigned CPU 1 with Node 24.18.0, 4 MiB stack and 4 GiB heap.
The six-case frozen-release boundary validation inherited Phase12's CPU 3 setting;
root was informed immediately. This is a correctness-only observation, and no
performance conclusion is made from these concurrent workstreams. Root owns final
exclusive paired checking performance and full frontend integration deltas.

Owned evidence includes `differences-census-*`, `differences-prepare-*`,
`differences-build-*`, `differences-render-controls-*`, `differences-family-*`,
`differences-boundary-*` and `differences-final-gates-*` under the Phase14 build
root; all consumed preparation tools are copied into their attempt. The final
report references stable absolute input identities in addition to these readable
paths. Root's evidence capture must preserve failed attempts, tools, source
snapshots, reports and referenced prerequisite artifacts together.
