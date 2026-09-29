# P16-002F — load dependencies before contextual body parsing

Status: prospective. Design: design/phase16/contextual-module-parsing.md.
Parent: immutable local-law-source-01/project (accepted wave6 plus20 exact local-law
controls). Keep pin, KTerm and Base-cache schemas fixed.

Hypothesis: the remaining imported declaration/refill/error-precedence differences
share missing dependency context during the one raw body parse. One shared module
completion step after dependencies can replace late corrective checks on the normal
path and avoid reparsing successful modules. Header-only collect-all IO is rejected
because it would reverse earlier-body versus later-IO error precedence.

CheckpointA is Bend/header/supplied-source only. CheckpointB is host IO lifecycle
and explicit capability/ABI review. Root owns full conformance, histories, timing
and promotion. Preserve failed tools, checked artifacts and nonexact controls;
no git writes or installed-source edits by this owner.
