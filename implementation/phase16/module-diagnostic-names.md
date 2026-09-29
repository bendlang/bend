# Source-module names without changing terms

The [design](../../design/phase16/module-diagnostic-names.md) preserves resolved
import aliases in the existing loader trace and carries file context through the
existing pretty-printer environment. Global names are displayed after canonical
sugar decisions; lexical binders retain their own identities and depths. An
optional host call uses the loaded renderer only after normal source-origin
validation. Context-free rendering remains available.

`module-names-build-02` passes genuine checked bootstrap, unchanged v5 and the
36-case development gate. The two corpus cases, `import/goal_alias.bend` and
`import/goal_own.bend`, are exact. Across ten paired controls, eight baseline
differences become one: **9/10 exact**, with all acceptance/refusal contracts
satisfied. The remaining alias/local-binder case exposes a preexisting semantic
resolution error, not a renderer error. It is retained for the separate binding
investigation, with a valid acceptance witness; the custom-oracle `pass` flag
does not imply exact agreement.

An independent review identified a public boundary: an already located span
could disagree with the first numeric range in its trail. Source02 verifies the
selected interval's source and local offsets against the span; otherwise it
keeps canonical names. Ownership is still selected by numeric ranges, never by
searching for equal source text. The ordinary host already locates from that
same trail.

`module-names-direct-02` passes **20 controls**: ten source/printing controls and
ten complete loaded-book equality comparisons. These include wrong prelocated
spans, absent spans, fallback ranges, own and imported namespaces, canonical Nil
versus module Nil, removed constructors, shadow markers and duplicate binder
depths. Complete parsed books, term identities and ranges are unchanged. The
first control harness mistakenly used `inner` instead of the existing public
`FLocatedSource.source` field; its nine failures remain in direct01. Correcting
that fixture field requires no compiler change.

The integration candidate also contains independently validated parser/import
corrections. Full-corpus, standalone-loader, history, backend, CLI and performance
gates remain separate. This error-only rendering work is not a speed claim.
