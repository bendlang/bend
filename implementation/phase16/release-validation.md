# Final compact compiler interface and historical compatibility gates

These gates bind `compact-final-build-01`, API
`35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`,
to its genuine checked parent and immutable source snapshot. They establish
bounded interface and historical-helper compatibility, not full conformance,
performance, installation or publication.

The unchanged **16 maintained equality-helper test groups pass** on the final
genuine checked image. All **five authentic derivation replays pass**, covering
versions 1–5 with their original historical artifacts and emitter rules. No
recognizer, test expectation or historical payload changed. The Phase16 launcher
uses the final snapshot workflow verifier, so the current termABI1/cache6
contract is explicit rather than interpreted by an older cache reader. It
checks byte identity of the helper and maintained tests before execution.
Evidence: `compact-final-helper-01/report.json`, `tests-report.json` and
`replay/report.json`.

The **standalone 25-module loader compiles and passes** the unchanged maintained
raw/traced/seeded equivalence controls. Its source is copied from the exact final
attempt snapshot. The launcher additionally verifies that the maintained test's
imported assembly tools match the frozen tools before compilation. The module
closure still excludes the checker and diagnostic tracing/production; it shares
only the diagnostic model and renderer. There is no new term-ABI adaptation in
the component test. Evidence: `compact-final-standalone-01/report.json` and
`component/report.json`.

The final interface controls also pass on that exact API:

| Gate | Controls | Evidence |
|---|---:|---|
| Supplied-source/contextual parsing | 39 | `compact-final-context-supplied-01/report.json` |
| Ordered host loading and lifecycle | 43 | `compact-final-context-host-01/report.json` |
| Constructor/imported-law namespace | 8 | `compact-final-context-namespace-01/report.json` |
| Consolidated term ABI and Base cache | 39 | `compact-final-term-host-01/report.json` |

The supplied-source gate compares complete raw parsing and Base bytes against
`spans-lambda-build-03`, the predecessor with the same termABI1 representation.
It does not erase fields or compare incompatible representations. The separate
Lambda metadata experiment proves the intentional old-to-new representation
projection. All pinned TypeScript expectations, trusted parsed-source behavior,
source intervals and seeded/raw/traced loader contracts remain in the controls.

The host gate retains exact lifecycle counts: cold loading parses four module
bodies; cached Base loading parses three and injects one Base seed; both finalize
once. Repeated physical files through aliases do not trigger another body parse.
It also checks dependency error order, missing/cyclic imports, header/body
precedence, source identity, foreign paths and corrupted returned intervals.

Both the supplied-source and host reports explicitly retain one known strict
wording difference for `@unsafe` followed by an import. These are not newly exact
conformance claims. Namespace and term-host controls have no declared exception.
The latter checks native-Boolean Lambda presence, compact literal payloads,
unknown present capabilities, source bounds, cache version6 identity and
historical no-capability host paths, including positional round trips.

All owned validation processes closed before root's final exclusive timing
window. Sources, consumed tools, inputs and failed predecessors remain immutable.
No installation or publication was performed by these gates. Root owns the full
corpus/backend/history evidence, final timing, release installation and CLI smoke
checks; those outcomes must be read from their respective reports.
