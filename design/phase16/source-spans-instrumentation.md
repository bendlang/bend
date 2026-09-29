# Source-span instrumentation contract

Prospective second stage of [source-spans.md](source-spans.md), after the checked
zero-metadata ablation and common child-rebuild controls. Root authorizes the
shared eight-field contract; the immutable starting union is
`selfhost/build/phase16/spans-shared-migration-01/project`. Its parent contains
the frozen parser05/checker03 union. Owners edit separate copies and root composes
their exact file manifests.

Parser owner supplies one lexer with an optional UTF-16 cursor and actual
production-specific range attachment. Source-span owner supplies source ownership,
host/cache binding, lowering/freshening, and direct diagnostic resolution. Root
owns the separate Empty semantic fix. No TypeScript source changes are involved.

KTerm's `originBegin`/`originEnd` identify a global positive source interval;
zero/zero means absent, and a positive equal pair is a real zero-width occurrence.
`kb`/`ke` project these values. `k_with_span` explicitly replaces both endpoints;
`kt_span` constructs a final term directly. `k_with_children` preserves all other
fields. Equality/freshness and all six semantic fields remain independent.

`f_parse_indexed(start, source)` receives a validated positive source start.
Legacy `f_parse` and `f_lex` produce absent origins, never zero/nonzero pairs.
Token cursors retain actual consumed endpoints; the terminal cursor cannot
become a language token or change old EOF/indentation/error precedence. Tests
compare the complete original token fields. Atom/constructor, first-argument
datatype, binder, generated do statement and infix ranges match pinned parser
construction rather than a generic widening rule.

The host allocates disjoint intervals in UTF-16 units with one reserved EOF
position: `[start, start + source.length + 1)`. A term's exclusive end may equal
the real EOF coordinate, but cannot use the extra reservation position. Verify
safe integers before U32 conversion, canonical source identity, actual bytes,
nonoverlap, endpoint order and membership. Aliases share one physical parse,
source bytes and interval; a changed file on a later alias visit is rejected.

One `FLocatedSource{source, begin, end}` wrapper adds interval ownership to the
existing raw/parsed FSource distinction. Source getters unwrap it; nested or
invalid ownership is refused. Indexed parsed results are accepted only in their
validated source wrapper. Base uses the first interval, bound in a new cache
schema to exact compiler/Base/path/range identities and the cached graph hash.
Every parsed/cached KTerm range is checked before reuse. Raw and seeded request
modules allocate after Base's reserved interval. Unknown ABI/schema and stale
or cross-request metadata are rejected.

Legacy source-aware convenience functions keep their purpose through explicit
indexed replay. Raw sources are assigned immutable intervals and loaded normally.
An unlocated trace is replayed from its recorded sources/root into a located
FProvenance.result; callers must check that returned book to obtain a located
diagnostic. Normal indexed CLI traces need no replay. Preserve the original load
failure without replaying a partial failed graph. Document and test this boundary
instead of pretending that erased occurrences can be recovered from old terms.

Replace the old per-definition relexing, token-position search and structural
term matching with source-interval records. Each deepest error-trail term resolves
its own numeric range before its ancestor is considered. A source module follows
the term through imports and specialization, independent of synthesized definition
names. No source text, fixture name or diagnostic string is used to guess a span.

Scope/name transformations preserve ranges; renaming changes binder IDs only.
Literal expansion retains the literal occurrence. Substitution uses the inserted
term's occurrence and beta reduction retains the replacement's provenance.
Generated nodes remain absent unless a specific surface lowering owns an actual
pinned source range. Datatype/constructor/definition validation and first-error
order stay unchanged. The checker owner adds an origin equality guard to binder
notes only when both compared origins are present.

Required controls cover raw/parsed/traced/seeded APIs, located/unlocated replay,
same physical aliases and changed-byte aliases, cache/range tampering, interval
overlap/overflow/EOF, tabs/CRLF/astral UTF-16, repeated equal literals/variables,
substitution/renaming/specialization and synthetic absence. Retain exact frontend
and backend diagnostic gaps as failures. Measure actual provenance collection
on the final candidate; the zero-field +1.01% pilot is not its cost claim.
