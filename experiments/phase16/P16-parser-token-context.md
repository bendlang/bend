# Parser token context and template refusals

Prospective stage after semantic source05. The exact remaining parser frontier
is33 fixtures from the independently audited integration04 wave3 comparison.
This bounded candidate targets7 fixtures/14 paired observations:
`comptime/err_extra.bend`, `err_head.bend`, `err_later.bend`, `err_runtime.bend`,
`flatten/mark_computed_optout.bend`, `parse/comp_arrow_position.bend`, and
`parse/chain_old_spellings_001.bend` (the abbreviated comptime names share that
prefix). Freeze the selected IDs and positive controls before probes.

The pinned parser reads `~` only in a call's leading template argument region;
the current parser admits it as any atom and can lose the first malformed child.
Move raw `~` recognition from the universal atom to parenthesized argument
parsing, preserving TemplateArg nodes/ranges for valid existing calls. Keep the
existing successful-call template validation unchanged. On rejection only,
walk the same argument sequence to retain the first bad marker and distinguish
an exhausted template count from an ordinary/non-template position. This uses
the same current visible declaration book; no new global context or second
successful traversal is introduced.

Only the exact adjacent `!(` spelling belongs to postfix offload parsing. Other
`!` tokens remain for their real enclosing grammar to refuse. A non-name head
such as `.` is an invalid term, not a malformed alphabetic name. Annotation
construction must propagate its existing first Error rather than wrapping it
and letting a later continuation replace it.

Validate the7 paired fixtures, existing36 focused cases, successful template
calls/partial runtime calls/offloads/ordinary annotations, and all244 parser
observations. Save failures and raw vectors. Acceptance/phase/trust may not
change in the corpus; direct grammar controls must match pinned TypeScript.
No fixture oracle changes, message matching or TypeScript fallback. Only
front/parser.bend and front/families.bend are expected to change. The import
owner separately owns import/name-token metadata; no overlap is intended.
