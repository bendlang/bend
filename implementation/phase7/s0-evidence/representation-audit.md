# S0 representation, provenance and frontend audit

Date: 2026-09-26. Scope: read-only examination of the production manifest and
existing Phase 6 evidence. No compiler, host, runtime, harness, configuration or
instrumentation was changed; no new compiler execution or prototype was run.
The only new files from this audit are this report and `parser-context.json`.

## Findings

Explicit first-order terms and retained provenance are credible simplification
experiments, but existing evidence does **not** substantiate the S2 ceiling of
13,500 lines, or the S4/S7 50%/75% milestones. The directly identifiable S2
retirement pool is approximately **675 physical lines before replacements**.
The existing numeric provenance candidate alone adds 292 Bend lines and 52
required host/workflow lines while retaining the old origin path. Changing a
representation can improve its invariants without decreasing its implementation.

The independent S1 proposal removes 548 lines, leaving 15,961. Even deleting all
675 identified S2 lines for free would leave 15,286: **1,786 lines above S2's
ceiling**, before paying for explicit variants, provenance, consumers and public
compatibility. This is a lower bound on the currently unbudgeted S2 portion,
not proof that other opportunities do not exist.

## S2 unique deletion ledger

Physical counts include associated laws, definitions, standalone `@unsafe` and
intervening blank lines. Small comment/boundary choices can shift a count by a
line; final implementation diffs and the fixed manifest remain authoritative.
These units belong to S2, not S1 retirement or S3 checker replay.

| Unit | Current gross lines | Replacement obligation | Verdict / conservative net treatment |
| --- | ---: | --- | --- |
| `core/term.bend`: `tg`, `nm`, `ix`, `qt`, `ks`, `rm`, `terms_at`, `kid` | 82 | Explicit node patterns, constructors, binder/work-frame consumers and any public adapter | Positional convention retirement supported for a bounded trial; **zero saving credited**. Net upper bound 82 for this named pool; lower bound unresolved because new traversal cases can exceed it. |
| `diagnostic/frontend.bend`: `FPSource`, the `fp_*` origin walkers and `f_load_origins*` implementation | 369 | Parser-owned occurrence metadata, source lookup and compatible public origin APIs | Full replacement unresolved; public API signatures and equivalent functionality survive. |
| `diagnostic/produce.bend`: `dg_span_same`, `dg_span_fields`, `dg_has_span`, `dg_origin_scan`, `dg_origin_trail`, `dg_origin_found`, `diagnostic_locate`, `diagnostic_result_locate` | 92 | Direct location lookup, unknown/ancestor behavior and public locate APIs | Structural matching can disappear only when coverage is complete. Checker replay functions in this file are **excluded** and belong to S3. |
| `load/graph.bend:446–574`: `fpe_graph_result`, `fpe_rejected`, `fpe_term*`, `fpe_def*`, `fpe_find*`, `fpe_selected`, `fpe_owner_path`, `fpe_unique_source`, `fpe_source_render`, and current result wrapper | 129 | Error carrier retains the selected occurrence and source owner through graph validation; first-error order stays authoritative | Bounded trial supported. This is frontend location recovery, distinct from semantic checking replay. Rendering itself remains. |
| `diagnostic/model.bend`: `DOrigin` declaration | 3 | Compatibility data or replacement for external origin consumers | Public shape prevents assuming an unconditional deletion. |
| **Total named S2 pool** | **675** | | **No validated net saving yet.** |

The four provenance rows total 593 lines. Existing ABI2 additions provide a
concrete cost anchor: 292 Bend + 52 host/workflow = 344 lines, leaving at most
249 lines if those additions could replace every old provenance function with
no further work. They currently cannot. As a planning sensitivity, reserving
another 0–350 lines for uncovered lowerings and compatibility gives approximately
**−100 to +250 net lines** for provenance. The allowance is explicitly a planning
reserve, not a measured implementation forecast or evidence that the replacement
will fit. Credit zero until the integrated retirement exists. A rewrite could
find a better representation, but this audit does not invent its savings.

### What explicit terms actually remove

`core/term.bend:18–24` overloads one six-field `KTerm` and one `KDef` across
many responsibilities. A textual scan of literal `kt("...")` / `atom("...")`
calls finds **65 tag spellings**, not 65 language concepts. The set includes
language nodes, parser transports (`Args`, `Tele`, `Patterns`, `Row`), loader
state (`Loaded`, `ParseOwner`, `ParseSource`), diagnostic payloads (`DTrace`,
`DCtx`), evaluator cells (`GCell`, `GThunk`) and native lowering nodes (`NWord`,
`NApply`). Dynamically supplied tag strings mean this is not an exhaustive schema.

Explicit variants remove the rule that every caller must remember which of
`name/id/quant/kids/removed` has meaning for its tag, the silent `Absent` return
for missing positional children, and administrative nodes pretending to be
language terms. They do not remove binding, substitution, sharing, work frames,
or each stage's distinct semantics. The current generic `ks` traversal lets
substitution, qualification and several walks share an implicit child structure.
Explicit variants must pay for the equivalent child processing somewhere.

The compiler contains 41 textual `KTerm{` occurrences, 215 `ks(`, 595 `kid(`,
612 `tg(` and 280 `kt(` occurrences, including definitions. These are migration
surface estimates, not dynamic costs or cyclomatic metrics. No first-order
explicit-term prototype currently demonstrates a net decrease. Preserve
globally unique binder IDs initially; adopting TypeScript's closure binders
would add a different experiment and is outside S2's controlled comparison.

Cheapest falsifier: implement the bounded S2 vertical slice in isolation, charge
all constructors/visitors/converters and generated or host logic, and reject the
schema if it adds more independent invariants or retained source than it removes.
No such prototype was made in S0.

## Existing provenance counterevidence

Sources: [parser-owned provenance](phase6-source-provenance.txt),
[numeric ranges](phase6-source-origin-ranges.txt),
[range proposal](phase6-source-provenance-range-proposal.txt), and their
retained candidate patches. These are unpromoted historical candidates.

- ABI1 versions 2 and 3 repaired 112 of 150 missing-excerpt targets, preserved
  141 prior exact negatives and matched 16 custom controls. The selected total
  was 307 observations; 38 diagnostic differences remained. The evidence supports
  actual occurrence retention over guessing by structural similarity.
- Version 1 regressed `check/do_missing_bind.bend` by preferring an enclosing
  origin to a deeper failure. Version 2 fixed this. A location representation
  does not by itself establish the correct error-selection order.
- ABI1 grew Base JSON **54.2%**. Version 2 failed the prospective 5% accepted-cost
  guard: paired request overhead **5.57%/5.40%**. Version 3 also failed:
  **11.04%/6.61%**. These failures remain failures; no new timing was run here.
- Version 3 reduced extra KTerm allocation to 0.95%, yet retained origin-object
  allocation and failed the timing guard. Allocation count alone is insufficient.
- ABI2 uses a U32 occurrence coordinate with a request-local source-range table.
  Base JSON grew **9.70%**, loaded-book JSON **9.32%**, and KTerm allocations
  remained 0.95% above control. Its controlled accepted-cost gate is **pending**.
  Existing correctness observations agree with ABI1; this is not release proof.
- The ABI2 patch adds **292 Bend lines and 52 host/workflow lines** relative to
  its lexer-only control. It also depends on the separate lexer repair. Old
  origin fallback is still present; no origin retirement has been demonstrated.
- A real alias-race control initially reused a parse with changed source bytes.
  The repair validates the exact original bytes on later visits. Other required
  contracts include disjoint nonoverflowing source ranges, codepoint-to-UTF-16
  conversion, Base-cache identity/range binding, validation of external parsed
  origins, alias ownership and unknown-origin behavior.

Therefore **object-per-term ABI1 is contradicted under its tested cost guard**;
**ABI2 is unresolved**, not a proven simplification. A new S2 choice must compare
the retired structural-matching/position-packing contracts against the added
origin-lifetime, range/cache and propagation rules. Do not count old machinery
as gone while keeping it as fallback, or ignore required host additions.

## S4 unique frontend/state ledger

These units are explicitly reserved to S4. They exclude the 548-line S1
retirement, S2 provenance recovery, S3 semantic replay/annotation, and S5 binder
freshening. Every row still needs exact compatibility and correctness validation.

| Unit | Gross opportunity | Replacement / conservative net estimate | Verdict |
| --- | ---: | --- | --- |
| `front/declarations.bend`: duplicate `f_dn`, `f_dt`, `f_dv`, `f_dk`, `f_dx`, `f_len` | **62 lines** | Reuse existing `dn/dt/dv/dk/dx/terms_len`; no new algorithm expected. Approximately 62 net lines before any externally required aliases. | Supported for a bounded caller/export audit and trial. Removes duplicate access policies, not a language concept. |
| `load/modules.bend`: `FLoaded`, `f_load`, `f_loaded_result`, `f_load_module`, `f_load_source`, `f_load_parsed`, `f_load_imports`, `f_load_import_next` | **92 lines** | Preserve `f_load` through one graph implementation if legacy behavior is expressible. A 9–40-line wrapper/adapter would give **52–83 net lines**; estimate is conditional and unproved. | Unresolved. `typed-driver.mjs` exports/uses `f_load` as fallback; `selfcheck.mjs` uses it. S1 deliberately preserves it. Canonical graph semantics and legacy name-based loading may require more than a wrapper. |
| `front/sugar.bend`: `f_error_term`, `f_error_terms`, `f_error_more`, `f_error_defs`, `f_error_def_next`, `f_error_defs_more`, `f_validate_result` | **70 lines** | Carry the selected parser/elaboration error with the result. Provisionally 40–100 replacement lines gives **−30 to +30 net**, before changes to producers. | Unresolved. Earlier/later declaration ordering and partial lowering failures must remain equivalent; early short-circuiting can change which error wins. |
| `FRawResult/FResult/FParsed`, declaration/expression state and repeated forwarding | No independent deletion established | New result/cursor/state APIs replace current plumbing. Zero credited until a complete slice removes named callers and charges adapters. | Unresolved; records alone can merely hide the same state dependencies. |
| Direct source cursor versus `front/lexer.bend` token materialization | Lexer is **340 lines**, not 340 lines of free savings | Source scanning, Unicode/newline rules, indentation, operator splitting and error positions survive. All parser consumers must migrate. No credible net range established. | Unresolved; no S0 evidence says a lexer is intrinsically more complex or slower. |

The first three named S4 pools total **224 lines gross**. The conditional
replacement estimates above sum to roughly **84–175 net lines**, with no saving
credited from the two unresolved broad rewrites. This is a bounded local budget,
not a prediction for a complete frontend redesign. It cannot substantiate the
planned 2,246-line S4 decrement. Signature reformatting, deleting comments or
moving compiler work into the host does not close the shortfall.

Source responsibilities that remain include source-order declaration visibility,
canonical-path identity distinct from aliases, import cycles, parse handoff
ownership, patterns versus values, constructor freshness, and first-error order.
Grouping them in a larger state record is not evidence that these contracts vanish.

Useful existing counterexample: the Phase 6 first-error candidate removes just
13 lines while repairing 50 exact observations in its 130-observation selection.
It demonstrates a concrete local simplification and correctness gain, not a
thousands-of-lines opportunity. It starts from an unpromoted prefix candidate;
its patch cannot be silently treated as a clean production-baseline deletion.

## Fixed parser-task context

[parser-context.json](parser-context.json) freezes the exact task, file hashes,
counts, categories, selection rationale and exclusions. The task is to repair
an earlier array-element, definition-type or match-header error overwritten by
a later body/delimiter error, retaining imported source ownership and accepted
neighbors. The actual Phase 6 A/B repairs ground the scope.

| Review material | Files | Physical lines | Bytes |
| --- | ---: | ---: | ---: |
| Local parser implementation and term contract | 6 | 2,664 | 77,480 |
| Elaboration/loading/error-selection integration | 5 | 1,802 | 50,956 |
| Architecture, conformance and workflow contracts | 3 | 405 | 25,526 |
| Maintained oracle manifests | 2 | 558 | 18,795 |
| Representative source controls and import dependencies | 10 | 41 | 534 |
| Judge and pinned-reference adapter | 2 | 129 | 11,755 |
| Existing repair report and exact candidate patch | 2 | 117 | 13,770 |
| **Union** | **30** | **5,716** | **198,816** |

This is a defensible review-context proxy using full-file units. It is not an
execution dependency closure, a claim that all these lines must be memorized,
or measured human/model effort. The JSON explicitly excludes unchanged Base and
backend/checker implementations and all historical archives. Whole oracle files
are included, but only the named representative fixture sources are counted;
this set is not a complete executable test capsule. Future comparison must keep
the same obligations and charge new abstractions/contracts instead of counting
only the lines edited after migration.

## S0 decision

Proceed with proven S1 retirement, then bounded S2 trials with stop conditions.
Preserve the 50%/75% objectives as objectives, while reporting their unsupported
budget explicitly. The current unique pools do not justify presenting a path to
either milestone as established. S2's explicit variants and direct provenance
must demonstrate both net size and conceptual reduction; S4 must identify much
larger concrete opportunities before its original line ceiling is credible.
