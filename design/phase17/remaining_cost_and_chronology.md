# Phase17: remaining cost and error chronology

Start from Phase16 release commit `0b51d965e2638048b5526b351047daae0c61ed7c`,
API `35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`,
and unchanged upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`.
The installed release stays unchanged while the following independent experiments
run in new Phase17 directories. Preserve consumed tools, failures and exact source
membership; no change enters production from a small witness alone.

The main corpus has two exact differences from one do-block's diagnostic order.
Independent controls expose same-body instance chronology, decorator/import
wording and broader parser-stage differences. These are distinct causes. The
3.42× same-window TypeScript cost deficit is a checking/trust-reporting result,
not generated-program execution speed or complete developer-build latency.

## Establish the new cost distribution without compiler changes

Reuse the immutable Phase16 CPU sampler against the exact final attempt and
the final assembled source. Preserve the raw V8 profile, input hashes, resource
limits, ordinary result and streamed summary. Sampling on CPU0 may overlap
other work on separate CPUs; label it diagnostic and exclude its wall time from
speed ratios. Before/after identity checks must bind the current selected API,
host, runtime and Base cache. Type checking must succeed with the same expected
proof-trust refusal as the final timing matrix.

Inspect exclusive samples and physical caller paths before proposing a shortcut.
The old expanded-literal profile cannot predict the new bottleneck. If API-stage
attribution is needed, use the existing wrapper worker as a separately identified
diagnostic run. Avoid interpreting overlapping stage/sample shares as additive
speedups. Promote no optimization until exact semantic controls survive and an
exclusive same-source alternating process comparison demonstrates useful gain.

## Preserve parser group boundaries before general failure transport

The Phase16 investigation proves that ordinary raw ASTs erase a grouping boundary
which changes when flattening errors must occur. Test a minimal frontend-only
`FGroup` wrapper around raw `Local`, `Match` and `Parallel` bodies. Successful
non-tuple exits from `f_group` use one helper; `f_scope` consumes the wrapper by
applying the existing term-level scope/flattening operation to its child. Scalars,
tuples and errors retain their existing forms. This is an estimated 10–25-line,
two-file ablation, not a promised final size.

Audit raw-shape consumers: namespace handling, binary/lambda validity, marking,
`f_grow_base`/`f_grow_args`, `f_family_first_done`, bang syntax and pattern
validation. Do not erase grouping just to satisfy a shape predicate. First run a
genuine checked build, maintained 36 controls, group/tuple/local/parallel/namespace/
call/lambda/pattern/delimiter witnesses, the saved 16 stage-order observations
and 114 pattern observations. Verify successful lowering removes every wrapper
before checking/emission. The prior Base/compiler census predicts zero allocated
body wrappers for those inputs, but additional dispatch still has unmeasured cost.
Any unexpected acceptance, rejection, error order or lowered-book change blocks
integration. Full frontend/backend and timing gates follow only a surviving trial.

This marker does not directly fix the monad tuple fixture. A later experiment
must retain the rejected `f_let_value`/`f_let_body` checkpoint and lexical frames,
resolve it before module rendering, and preserve left-expression → RHS → pattern
→ continuation order. Prior ungrouped rows use `f_scope_body`; grouped bodies cross
the explicit boundary. Do not use source-text/offset heuristics or thread parser
context through every function without first testing narrower ownership.

## Determine where live instances must be checked

Compare the installed checker/specializer with pinned `infer_ref`. The current
whole-program path checks ordinary bodies before `specialize_book`; upstream can
instantiate and check a live template when it is referenced. First isolate both
error-order directions with minimal exact paired witnesses and inspect recursion,
memo reuse and scope requirements. Produce a bounded proposal before modifying
the checker. A parser group marker cannot resolve this separate ordering issue.

Keep implicit instantiation, canonical key identity, size/depth limits, optional
lambda quantity and invalid-instance refusal in the controls. Prefer one existing
owner handling the operation over a duplicate partial checker or a global replay.
Record line/type/definition deltas along with semantics and cost; a faster or
more exact compiler is not automatically a simpler source implementation.

## Integration and reporting

Each experiment gets its own report and unchanged-oracle verdicts. Known
differences remain visible, even if the bounded no-regression gate passes.
Only combine independently validated changes, with full membership-aware merges.
Final installation requires the relevant complete frontend/backend, original
histories, helper/host/CLI and controlled timing gates. Keep Phase16's source,
reports and evidence capsules immutable while preserving this phase separately.
No full-conformance, new fixed-point, proof-kernel or GPU claim follows from a
selected gate. Remote publication remains subject to the unresolved earlier
automatic approval rejection.
