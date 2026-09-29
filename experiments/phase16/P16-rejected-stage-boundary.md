# P16: rejected-path body versus term checkpoints

Prospective bounded synthetic stage under `rejected_parser_transport.md`.
Root authorized resolver-stage demonstration but not parser callback wiring.
Parent checked image: marked-pattern-checked-01. CPU3 only.

Test the existing reusable separation: f_scope_body performs parse-time raw
body scope/pattern processing; f_scope on the same Match crosses its flattening
boundary. Independent TS fixtures compare a completed prior row's global-head
match with later syntax/pattern failures, and the same match enclosed in a
completed parenthesized term. f_group currently erases that grouping distinction.
If the oracle pair establishes different required ordering but the raw AST loses
the stage, stop before full transport implementation: a failure-only resolver
cannot infer absent metadata. No source text/span heuristic is allowed.

No production compiler edit is included. Freeze fixture bytes and direct harness
before running paired oracles and existing-worker synthetic controls. Retain all
failed fixture attempts and report scopes separately. Results belong in
`implementation/phase16/rejected_stage_boundary.md`.
