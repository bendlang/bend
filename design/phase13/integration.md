# Conditional integration of the structured selector rewrite

Prospective integration detail, 2026-09-28. This does not promote a prototype.
The master design's speed/complexity decision still applies after the bounded
constant-scope experiment. Plain named-worker lifting has already been rejected.

The prototypes deliberately import the complete frozen historical helper. Their
626-plus-line support totals are honest experimental dependencies, not the
intended production layout. Integration must replace duplicated recognition;
putting those imports behind a new entry point does not satisfy the design.

## One replayable maintained helper

Keep `selfhost/tools/development/equality.mjs` self-contained apart from Node
builtins. The checked workflow and installed release currently bind/copy one
helper; introducing a hidden imported parser would weaken that provenance.

Use one tokenizer and one source-range module/function view for scalar equality,
literal choices, existing leaf blocks and the accepted selector rule. Reuse
call/argument splitting, arrow/returned-choice recognition and range rendering.
The module view accepts the already-selected runtime profile so authentic legacy
version 1 remains valid. Current and historical dependency/export contracts stay
distinct where their admitted calling conventions differ.

Retain all historical profile hashes and exact version 1–5 API bytes and JSON
statistics, including offsets, skipped sites and report ordering. No old version
may silently acquire selector rewriting. The new default is a separate version
6 only if it earns promotion. Its report binds the selected owners, skipped
shapes, protected helper bodies and exact pre/post image hashes. Its calling
convention, runtime and public exports remain unchanged.

Reproduce the accepted experimental output bytes from the same genuine checked
parent before a fresh build. Count the entire maintained file, historical data,
guards and tests; distinguish fewer duplicated recognizers from physical-line
or byte reductions. Reformatting is not simplification evidence. The Bend source
remains unchanged unless a separately authorized, validated source edit occurs.

## Integration gates

1. Independent guard controls and authentic historical replay pass against the
   actual maintained entry point; compare output bytes and exact statistics.
2. Run a fresh checked workflow and the maintained 22-case focused selection,
   including the long string first. Preserve the old installed release.
3. Apply fresh and exact 53/60-history resource controls to the final image. A
   new build/derivation may reuse byte-identical observations only with explicit
   identity accounting; do not relabel an experimental manifest as a checked one.
4. Compare the complete 2,996 frontend vector with Phase12, and run the 37 paired
   backend controls plus actual native build/execution. Preserve every failure;
   no baseline-accepted observation may regress.
5. Run the unchanged same-source TypeScript/baseline/candidate/candidate/baseline/
   TypeScript matrix, then relevant JS/C emission matrices with output-byte and
   execution oracles. Keep compiler-host gains separate from user-code speed.
6. Install only after those gates, verify ordinary and relocated CLI behavior,
   update the compiler guide/architecture/README and reports, then freeze all
   producers before evidence capture, recovery verification, commit and push.

If the measured survivor does not justify this integration, retain the current
usable compiler and publish the bounded experiment and its limitations. No full
suite or production refactor is owed to an artifact that fails the stated gate.
