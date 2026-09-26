# S0 retirement audit

This is read-only hypothesis validation against commit
`fc509f4cd5bf00b2cd600922b4e40c5d7b9a1e01`. No compiler source, host, harness,
configuration or instrumentation changed, and no compiler was executed. The only
new files are this report and [its machine-readable inventory](retirement.json).

## Result

The provisional S1 target of at most 16,000 physical compiler lines has a concrete
candidate: remove 53 private functions, their 35 separate laws, and five exclusive
datatypes. Their complete declarations occupy 548 physical lines, 460 nonblank
lines and 14,980 bytes. This would change the 59-module compiler from 16,509 to
15,961 physical lines, 13,803 to 13,343 nonblank lines, and 509,937 to 494,957 bytes.
These are proposed source savings, not a completed implementation or speed result.

The declaration boundaries include each definition's `@unsafe` marker and trailing
blank lines. The inventory records exact per-block bytes and hashes; nothing is
counted as a formatting rewrite. The separate 62 frontend lines identified by the
representation audit are outside this S1 candidate and are not counted here.

| Module under `selfhost/src/` | Complete inclusive line ranges | Physical / nonblank / bytes removed |
| --- | --- | ---: |
| `core/normalize.bend` | 152–175, 192–199, 231–285, 308–319, 423–436, 442–464, 489–496, 501–520 | 164 / 142 / 5,774 |
| `front/freshen.bend` | 5–7, 22–88, 94–119, 142–205, 210–233 | 184 / 155 / 4,132 |
| `back/native/layout.bend` | 1–12, 20–97 | 90 / 75 / 2,464 |
| `back/native/book.bend` | 29–32, 56–59, 90–115, 220–231 | 46 / 38 / 1,328 |
| `back/native/ir.bend` | 8–19 | 12 / 8 / 331 |
| `front/declarations.bend` | 36–39, 269–273, 369–374, 387–394, 582–587, 635–639 | 34 / 28 / 649 |
| `front/flatten.bend` | 14–17, 155–160 | 10 / 8 / 114 |
| `front/elaborate.bend` | 215–218, 462–465 | 8 / 6 / 188 |
| **Total** | **Eight modules; no module removal required** | **548 / 460 / 14,980** |

## What becomes easier to understand

This retirement does not remove language concepts. It removes inactive alternative
implementations that currently look like valid routes through the compiler:

- The recursive freshener and its private `FFreshTerms` result type, superseded by
  `fresh_work.bend`. Public `f_fresh_term` and `f_fresh_defs` remain unchanged.
- The older recursive strong-normalization child walker, the older non-graph
  strong-normalization worklist, and the older recursive comparison helpers.
  `strong` already uses graph normalization, and `norm_compare` already uses the
  `norm_cmp_*` worklist.
- An unused flat-layout packing subsystem and its `N_Field`, `N_Arm`, `N_Layout`
  and `N_Value` types. The active native backend uses one word per live value and
  boxed general constructors; its README already states that upstream flat-layout
  optimizations are not implemented.
- An unused native bang-reference traversal and an obsolete primitive readback
  string helper. Active scheduling metadata and descriptor generation remain.
- Several unused accessors and superseded frontend convenience functions.

The JSON names every function and declaration. For normalization, retain
`KNormFrame` and `norm_rebind`: the active graph evaluator still uses both. Also
retain `norm_compare`, `norm_removed`, `norm_subset`, `norm_max_walk` and the active
comparison worklist. Native retirement must retain `nl_c_type`, `N_WordKind` and
the active segment, parameter, frame, constructor and program types.

## Reference method and scope

The first analysis extracts all 1,526 top-level function definitions from the 59
manifest modules. A quote-aware scan blanks double-quoted strings, single-quoted
character literals, backslash escapes and `#` comments before collecting known
function identifiers. It collects function values as well as direct calls. This
is a conservative lexical dependency graph, not a full Bend name resolver.

External roots are every known function name appearing as a complete identifier
anywhere in 1,034 text files under `selfhost/` and `docs/`, including comments and
strings. This includes maintained hosts/tests, source-directory native tests,
documentation and historical performance tools. The scan excludes the manifest
modules themselves from external roots, and excludes directories named `build`,
`dist`, `.bootstrap`, `node_modules` and `.git`. The exact file list and suffixes
are in the JSON. There are 285 external function roots; following their dependency
closure reaches 1,473 definitions. All 53 proposed function removals are outside
that closure.

A second, independent check masks only the proposed complete declarations in
memory and searches *all remaining production text*, including laws, datatypes,
strings and comments, for any of the 58 removed function/type names. It finds zero
references. Searching external text without stripping strings or comments also
finds zero references. No candidate source tree or generated compiler was created.

Historical implementation and experiment reports are evidence, not maintained
compiler entry points. Generated distributions and build/bootstrap images are
artifacts that must be rebuilt or verified at the appropriate integration gate.
Their references do not make an otherwise obsolete source helper part of the
maintained public interface. An arbitrary custom stage0 export of a removed
undocumented helper would, however, change; this scope limit remains explicit.

## Earlier evidence and retained APIs

The 184-line freshening unit is the unchanged, independently reviewed Phase 6
candidate. Its isolated checked/equality build passed the 21 maintained controls,
preserved all 54 selected roots, and produced byte-identical selected compiler
artifacts. See [the earlier report](../../phase6/obsolete-freshening.md),
[review](../../phase6/cleanup-independent-review.md), and
[patch](../../phase6/obsolete-freshening-candidate.patch). This evidence applies
to that unit, not automatically to the combined 548-line retirement.

Several tempting removals are deliberately excluded:

- `f_load` is explicitly selected in `tools/typed-driver.mjs:23`, and both that
  host and `tools/selfcheck.mjs` retain fallback calls. Its older loader and
  `FLoaded` type need a separate, deliberate host/API migration.
- `f_load_origins` and related origin APIs have maintained host/test references.
- `tele_check_head` is referenced by historical telescope/fact probes.
- `f_scan_word` and `f_scan_quote` are referenced by the retained lexer probe.
- The active graph evaluator, freshening worklist, source-parsed representation,
  compiler roots and host exports remain in scope for preservation.

## S1 reproduction, gates and falsifiers

After S0 review closes, S1 can reproduce the candidate mechanically from the JSON:
verify each module's complete SHA-256, verify each proposed declaration block's
SHA-256, then remove the listed inclusive ranges in descending order. The file
hashes make this fail safely if another phase changes a source file first. Recount
the manifest modules and repeat the remaining-reference check after deletion.

S1 must then build the genuinely checked selected compiler and verify its roots
and reachable generated output against the baseline, followed by the maintained
focused compiler controls. Byte equality is the strongest cheap expected result;
it has not yet been established for the full candidate. If bytes differ, explain
the difference before claiming behavioral equivalence. Source-wide/all-definition
compiler-library and self-reproduction validation must use the new source rather
than reusing old source-bound results.

Any remaining production reference, selected export, documented supported caller,
new checked build failure, output difference or maintained observation regression
falsifies an affected deletion unit. Retire only independently supported units;
the 16,000-line target cannot justify removing a live API. No execution-speed gain
is claimed: these functions are already outside the maintained selected runtime
closure. Reduced all-definition source and fewer competing mechanisms are the
benefits to verify.
