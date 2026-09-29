# Phase16 import diagnostic follow-up

The first candidate is retained and unselected. Its44 observations include14
original corpus cases and30 independent boundaries;32 are exact. The12 remaining
observations exposed real alias law/type acceptance/phase differences, discarded
import-line display intent, normalized lexer spelling used as physical path text,
and the separate dependency-sensitive annotated-law diagnostic.

The follow-up starts from accepted wave4-source-02. It uses the explicit lexer
symbol mapping for import path spelling, preserving physical columns and the
pinned header→extension→duplicate-alias→path-validation error order. Alias-qualified
law/type declarations are refused from the header's alias table, independently
of dependency contents. Their original name token supplies the range. Definition
fills retain the existing dependency boundary; no imported-law status is guessed.

A shared parser failure snippet helper distinguishes original import display
(ParseLine or explicit ParseRaw) from module body display. The existing leading
import-line elision changes only displayed lines; absolute intervals and token
coordinates remain unchanged. Semantic ParseNote rendering survives. An explicit
ParseObservedPoint reads a UTF16 code unit at the producer's actual cursor and
handles EOF; it does not search for matching source text.

Fresh source02 genuinely compiles, passes the unchanged optimized v5 guards and
all36 maintained focused cases (four strict differences retained). Its58 paired
observations produce54 exact results and no primitive differences. All14 original
import observations are exact. The two remaining causes are the no-path import
header pointing at its newline instead of its keyword (two lanes), and the
annotated imported-law diagnostic (two lanes). The latter is correctly refused
by both compilers but still differs: upstream expects a colon after the telescope;
the raw candidate parser still reports alias freshness before dependency loading.

Source03 applies only the no-path header cursor correction to source02. Its
genuine checked build and v5 derivation pass36 focused cases; all58 paired probes
complete with56 exact results and only the two annotated-law diagnostics left.
All primitive fields agree. This closes the initial twelve boundary differences
except the explicitly dependency-sensitive annotated-law case.

Independent direct controls on source03 found another real boundary:68 of70 pass,
but observing either UTF16 half of an astral character throws because Bend
`Char.from_u32` correctly refuses non-scalar surrogate values. Those failed controls
and their consumed runner remain; the runner captured a thrown string without an
Error.stack, so those two rows have no textual exception field. Inspection of the
checked function and runtime establishes the scalar-value rejection. No runtime
rule is weakened.

Source04 removes surrogate construction. An unrepresentable point observation
retains the producer's legacy diagnostic, matching the conservative boundary of
the pre-existing lexical renderer. Its direct70-control report passes exact raw /
indexed header checks and safe point behavior. It separately records **two strict
Unicode differences**; fallback controls do not turn them into TypeScript matches.
The report verifies complete header strings at legacy start0 and indexed starts1
and4097, and checks ASCII, tabs, CRLF, EOF, existing isolated surrogates and astral
UTF16 offsets against the authentic checked image. Source04 is genuinely checked,
passes existing v5 and36 focused cases. Its final58 paired controls preserve
**56 exact / 2 strict remaining**, with zero primitive differences; the raw-vector
summary binds every observation.
All source snapshots, consumed tools, build logs, raw vectors and strict failures
remain unchanged. No new performance result is claimed by this correctness work.

The frozen handoff is `spans-import-source-04-handoff/manifest.json`, with five
module patches against wave4-source-02 and optimized API
`44d5fef2ce66104c417471503166610e03fb3b1da05287cacf11cede57439f65`.
The bounded change adds82 physical lines and10 definitions across those modules;
there is no new type, KTerm/source/cache ABI, host semantic code or source pass.
These definitions cover original-line observation, exact point fallback, shared
display selection, physical token spelling and alias prefix handling. Integration
notes distinguish the other parser owner's replacement header worker from this
candidate's mechanical name-token threading; do not overwrite that newer worker.
