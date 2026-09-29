# Phase18: stable specialization output around the internal checker world

Prospective correction to source03, before any semantic migration. The measured
representation ablation is retained unchanged. Its public `specialize_book`
result exposes the expanded six-field KChecked through KSpecialized.error;
existing projector and CLI equivalence does not establish raw-result equality.

Rename the expanded internal record to **KChecking** throughout kernel, trace,
diagnostic producers and specialization state. Restore **KChecked** as exactly
the historical four-field `{term, typ, uses, error}` payload at KSpecialized.error.
No public capability number or host decoder is reinterpreted. KEnv/KWorld and
all internal transport behavior stay as source03.

`sp_finish` is the sole public producer of KSpecialized. Bind its existing
internal result once and construct the four-field payload there. This allocates
one small compatibility record per completed specialization call, never one per
recursive checker call. Keep the original constructor name and field order so
raw success and failure results can equal the parent byte for byte.

`specialized_error` matches that stable payload to return its error string.
`specialized_diagnostic` matches it and calls a shared term/error/name renderer.
Factor the existing dg_report body into `dg_report_payload(term,error,name)`;
internal dg_report projects its KChecking into the same helper. No renderer is
duplicated and no stable payload is converted back into a checking result with a
fabricated world. `specialized_book` and program completion keep their contracts.

The source/export census and parent-relative patch will be retained before
building. Expected incremental cost is one explicit compatibility type and one
renderer helper, plus a small finite adapter, with no removed semantic visitor.
The KChecking rename changes many type references but adds no semantic rule.
Count physical/nonblank lines, bytes, definitions and types exactly after
preparation. The public export inventory must remain unchanged; the sole
advertised root returning KSpecialized is specialize_book, accompanied by its
three public projections. Check host/API consumers rather than assuming all
callers only use those projections.

Build a fresh genuine checked B1/v5 source04 candidate. Repeat the closed
representation gates with the renamed internal tag explicitly identified in
probe-only controls: default36, 22 complete parent-outcome comparisons, eight
memo/name sets, and the 42 transport/demand/result controls. Add exact raw
KSpecialized success/failure controls, repeated specialization, and literal
historical four-field payloads passed to all three public projections. Compare
complete books, payloads and rendered diagnostics against the Phase17 parent;
assert exact field membership/order and absence of world/count in public output.
Program DResult and CLI observations stay unchanged, including both known
chronology gaps. Preserve source03 and every superseded attempt; no host wrapper,
semantic instance checking or live/default edit is included.
