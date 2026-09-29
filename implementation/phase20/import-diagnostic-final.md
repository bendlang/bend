# Final declaration checkpoint candidate: source04

Source04 is the final isolated candidate for root integration. It combines the
structured decorator error, the datatype constructor checkpoint, and two empty
first-element guards around the original match parser bodies. The datatype
whitespace correction below **supersedes source02 and source03 for promotion**.
Neither earlier source nor its bounded report was rewritten.

The final genuinely checked B1/default36 is fully exact. On this same image:

| Frozen suite | Earlier exact | Final exact |
| --- | ---: | ---: |
| Decorator, supplied and host | 4/24 | 24/24 |
| Constructor raw/loaded | 18/50 | 50/50 |
| First elements, raw/supplied/host | 42/54 | 54/54 |
| Datatype whitespace, source01 baseline | 6/44 | 44/44 |
| Original supplied-source controls | inherited one strict gap | 39 pass, zero strict gaps |
| Original ordered-host controls | inherited one strict gap | 43 pass, zero strict gaps |

These are separate suite observations with overlapping grammar coverage, not
distinct corpus fixtures or a full-language conformance claim. New focused reference
diagnostics were frozen before the final source change. Ordered-host suites also
assert actual read order and preserve earlier dependency failures.

The two first-element guards use List.is_empty before accepting an initial colon
or skipping an initial comma, then call existing fpe_error with `a term`. Original
f_match_heads/f_case_pats bodies are preserved byte-for-byte inside the wrappers;
no FInput, contextual case/body worker or parser-state migration is included.
They fix nine false-acceptance and three diagnostic observations. Valid multiple
heads/patterns with optional commas, trailing/double-comma rejection, EOF/newline
positions and a bound head with zero rows remain exact. List.is_empty avoids the
rejected prototype's repeated accumulator-length traversal.

Independent review found a real flaw in source02 after its initial focused gates:
f_skip consumed semicolons before `{` and around the datatype constructor loop.
For example, `type T is Data: C;{}` was newly accepted while the pin rejects at `;`.
The widened column-zero constructor admission also exposed before/between-loop
semicolon errors. Identical source01/source02/pin controls prove 15 newly false
accepted observations across five fixtures, plus nine inherited false acceptances
at neighboring datatype boundaries. Those raw reports and the checked source03
composition remain preserved. A passing earlier narrow gate is not evidence that
this counterexample is safe.

Source04 uses the existing newline-only f_space at the brace checkpoint and both
constructor-loop feeds. The loop exits through f_top on its already-spaced cursor,
preserving an offending semicolon for the ordinary top-level diagnostic. Name,
alias and duplicate checks still run before the opening-brace check. All 44 new
whitespace observations are exact, including comments/newlines, malformed and
reserved names, aliases, duplicates, and declaration exits. Global f_skip/f_tops
and telescope grammar remain unchanged; this is not a general semicolon audit.

The complete delta from installed Phase19 is one file, **17 additional physical
lines, one function, zero laws/types, and 1110 bytes**. No host, cache/public ABI,
semantic state, checker, backend or normalizer change is included. This adds a
small readable constructor-header worker and corrects shared existing grammar
checkpoints. It is not a line-count reduction. No timing was performed by this
owner; root's separate controlled screen must establish cost before promotion.

Authoritative project: `selfhost/build/phase20/import-diagnostic-source-04/project`.
The manifest binds all 214 project files; cumulative patch is
`declarations-phase19.patch`, and the final whitespace delta is
`declarations-parent03.patch`. Checked image: `import-diagnostic-build-04`.
Final closed gates are `import-diagnostic-{brace,first,type}-focused-04`,
`import-diagnostic-focused-04`, `import-diagnostic-supplied-04`, and
`import-diagnostic-host-04`. The machine report binds exact API/input identities,
all changed focused observations, rejected candidates, and scope limitations.
Root owns broad frontend/group checks, cost screening, installation and release.
