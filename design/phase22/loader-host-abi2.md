# Host boundary for contextual loader ABI2

The private host project starts from all214 frozen Phase21 source/host members,
including35 host files. Only tools/typed-driver.mjs changes; no Bend source,
installed files, runtime, checker or cache policy changes. The parser owner will
separately implement compiler_load_abi()==2 and the completed-source factory.
No compiler build or promotion is authorized by this host preparation.

ABI2 requires f_source_header, f_complete_source, f_complete_seed,
f_import_namespace_at, f_graph_trace, f_load_graph, f_source_located and
f_source_completed(name,path,text,parsed). The latter creates FCompletedSource
with name/path/text/parsed fields. Its parsed value is the exact FResult returned
by actual contextual completion during this invocation. The host must never
manufacture it from a raw parse or trust an external raw AST as completed.
Physical aliases reuse that same completed record and source interval. The
existing header/completion/graph result structures otherwise stay unchanged.

Require this version and its entries at API loading and source discovery,
including explicit inspect({api}) injection. Unknown, absent and older loader
versions fail closed; this is an intentional internal ABI break. Remove raw
f_parse/f_parse_indexed/f_load bootstrap roots, raw parsed-source conversion,
legacy discovery and load fallback branches. Keep graph loading for Base and
request-local completion for ordinary source discovery. The generated-runtime
field adapter maps FCompletedSource instead of FParsedSource. Preserve existing
term/span validation, cache identities, import/cycle order, provenance and all
CLI flags. Historical frozen experiments remain reproducible with their own
host; they do not require the new host to accept older internal images.

For --checkup, follow the pinned upstream main.ts cli_checkup enumeration:
read Base once, inspect every physical parent line in order, trim it, and match
the same anchored `import <nonspace> as <ASCII identifier>` expression. Ignore
nonmatching lines, bare Base imports and parent body syntax. Preserve repeated
imports, relative/absolute path resolution and per-import output/exit handling.
This is CLI input enumeration, not a host implementation of Bend parsing.
It intentionally corrects the old full-parent-parse prerequisite. Do not use
the ordinary leading-header parser: upstream scans all lines, even later ones.

Freeze source patch and controls before probing. Host-only mock controls exercise
ABI2/older/unknown/missing-entry routing, actual completed handoff identity,
physical aliases, dependency order and early completion failure. A CLI mock
uses the actual new main() path and verifies --checkup line selection, duplicates,
invalid parent body, relative/absolute paths and failing-then-later imports.
No mock result is compiler conformance or a checked Bend build. Root owns the
real integrated ABI2 build, focused/full corpus, CLI/backend gates and cost.
