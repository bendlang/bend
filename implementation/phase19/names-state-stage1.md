# Private names/state primitives

Stage1 establishes a checked contextual name/state primitive, not a contextual
body parser. The corrected candidate matches all 23 supported TypeScript oracle
records and four explicit Unsupported contracts. Maintained36 and all194 raw
cursor/complete-book controls pass. No production parser routing, conformance
improvement or new timing result is claimed.

The frozen [Stage1 design](../../design/phase19/names-state-stage1.md) uses one
experimental `f_context_probe` bootstrap root. The isolated parent is Phase18
cursor-source-02/API5d19edf5. Selected source is
`selfhost/build/phase19/context-source-02/project`; checked attempt
`context-build-02` has genuine B1 `fadc7427` and guarded API `7c4d83bd`.
Upstream remains `b2111cf`. Complete hashes, source memberships and host deltas
are bound by `context-stage1-audit-01/report.json`.

The root runs a fixed lookup/open/lookup/close/lookup/token-rewind protocol using
the actual prospective helpers. It accepts only a raw cursor, seeds a contextual
cursor, and returns that explicit contextual state. It has no test instruction
language and never emits a Core result. Ordinary production entry points never
call it. The sole host delta adds its export so the Bend implementation is
genuinely checked and emitted, rather than supplied by probe JavaScript.

Names retain their parsing distinction: a bound Var keeps its identity; an
unbound ordinary name gets a fresh Var syntax view and canonical Ref fallback;
an unbound dotted name remains Ref. Aliases are resolved only after lexical
lookup. Fallback creation does not materialize ADTs or trigger value-only errors.
Opening a new binding allocates a fresh identity; closing and token rewind retain
the advanced counter. The open primitive deliberately does not prove lambda or
pattern eligibility. Marked/compound/body syntax remains explicitly Unsupported.

The source adds120 Bend lines, one manifest line and one host-export line:
122 total, below the150-line review threshold. The new module has13 definitions
and two types; the existing cursor-context type gains one variant. FName is one
private syntax tag. Of the120 Bend lines, the119-line new module contains both
reusable primitives and the fixed probe protocol; no production pass is removed.
There is no net simplicity or performance claim yet.

The control preparation freezes27 cases. Independent pinned `parse_tele` records
actual parameter identities, quantities, type syntax, spans and the next counter.
Pinned `parse_var`, `parse_open` and `parse_close` supply the expected state
sequence. Supported cases include zero-arity datatypes, families, constructor
spellings, shadowed parameters, underscore, near/far/missing module names,
aliases, ambiguity and a dotted binder shadowing that ambiguity. The sole
supported error is the expected unbound alias ambiguity. Raw TypeScript errors
and complete state observations are preserved. The candidate never invokes the
TypeScript oracle.

The first checked source/probe is retained as a real failed attempt. Source01
seeded the lexical stack by reversing every parameter. TypeScript allocates an
ID for `_` but excludes it from ordinary lexical lookup; the control caught an
extra underscore stack cell. Existing lookup ignored the cell, but the state
contract was still wrong. Source02 introduces one shared parameter-env builder
that filters `_` while retaining its already consumed ID. Full27 rerun passes;
the source01 report remains `pass:false` with exactly that failed row.

All194 reused raw controls pass, including complete raw and lowered Base and
unchanged parent compiler books, with full IDs/ranges retained. The probe
extension appends exports of existing generated lexer/index/error-renderer
functions to a byte-identical production API prefix; its separate identity is
recorded. The experimental production image has its own explicit bootstrap-root
identity. CPU3 jobs use Node24.18, stack4MiB/heap4GiB; process reports verify exit,
signal, errors, timeout and output overflow, not just exit status.

Primary local evidence under `selfhost/build/phase19/` is `context-controls-01`,
`context-oracle-01`, both `context-source-*`/`context-build-*`/`context-probe-*`
attempts, `context-raw-01`, and `context-stage1-audit-01`. All Stage1 producers are
closed. Durable evidence capture remains root-owned. The next approved bounded
step must route the real grammar's ordinary-name owner through these helpers and
demonstrate a real alias-versus-later-syntax ordering witness; isolated state
simulation alone does not establish that migration.
