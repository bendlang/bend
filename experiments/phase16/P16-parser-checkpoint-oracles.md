# P16 parser checkpoint oracle and frame census

Design: design/phase16/parser_failure_chronology.md. Read-only compiler work.
Baseline wave8-build-01; pinned TypeScript b2111cf. CPU3 selected correctness
only, one producer at a time. Freeze fixtures varying pattern category, RHS and
continuation failure order, enclosing lexical scope and module aliases. No
compiler edit, diagnostic override or acceptance-oracle relaxation. Any fixture
syntax error invalidating its intended witness is retained and corrected under
a new version. Record exact paired vectors and worker health; expected remaining
semantic gaps do not count as infrastructure failures. Frame inventory covers
parameters, lambda/all, local/parallel, match, do and generated rewrite/Exists
binders before proposing a rejected-body transport.
