# P13-002 — Structured branch workers without enclosing-frame expansion

- Owner: `/root/p10_membership`; independent semantic reviewer:
  `/root/research_binders_semantics`; measurement/replay owner: `/root/p10_layout`.
- Started: 2026-09-28. This prospective record precedes implementation probes.
  Initial activity is static design while root profiles the released compiler.
- First investigation: 20 minutes after root releases a CPU, with an early
  opportunity/capture-domain decision. A surviving implementation gets a separate
  checked-image and resource gate; no full-source timing without coordination.
- Correctness: untested proposal. Measurement: none. Decision: investigate.
- Report: [structured rewriter](../../implementation/phase13/rewriter.md).
- Related evidence: [Phase12 calls](../../implementation/phase12/calls.md),
  [Phase12 release](../../implementation/phase12/avoidable_work.md).

## Claim and immediate disproof

A small shared representation of reviewed generated calls, literal arrows,
conditional branches and lexical bindings can reproduce version5 exactly, then
replace one hot family of literal branch closures with named workers carrying
explicit captures. This may reduce closure allocation while preserving the
separate frame in which branch-local and non-tail work executes. It is not an
estimate of a future speedup or a general JavaScript optimizer.

Phase12 broad inlining failed fresh and matched-history long-string controls
even after the normalizer seed change was removed. The independent seed change
also failed matched histories despite passing fresh checks. Neither transformation
is revived. A different worker calling convention can still change frame sizes
and V8 optimization; keeping a source-level boundary is necessary evidence, not
a guarantee of the fixed4MiB resource contract.

Stop on any version5 byte/statistic mismatch, unknown admitted syntax, changed
capture/demand/error order, unavailable provenance, resource regression, absent
dynamic allocation opportunity, or growing infrastructure without a clear
benefit. Promotion requires roughly20% controlled full-source improvement, or a
compelling measured gain together with lower maintained complexity. Root makes
that decision; operation counts alone cannot satisfy it.

## Small representation and compatibility step

Use the existing reviewed tokenization grammar and source ranges. Share one
module/function/binding view plus helpers for parenthesized ranges, calls,
literal arrows, conditional choices and branch bodies. Keep expressions opaque
where their internals need no analysis. Do not introduce a general parser,
optimizer pipeline, alternate runtime, mutable IR, cache or new compiler stage.

The first implementation must reproduce the current version5 output and
statistics exactly from its genuine checked parent. Unchanged source ranges
retain their bytes. Exact profile/runtime/dependency/export checks precede
rewriting; duplicate/rebound/shadowed protected names and unknown syntax fail
closed. Explicit historical versions1–5 must replay their authentic artifacts
with original metadata. A later maintained candidate would need a distinct
version; an experiment cannot silently change version5 semantics or lineage.

## Worker contract

The initial admissible branch is a literal single-parameter arrow whose body
uses the reviewed generated grammar. Its local declarations, nested closures,
calls and return remain in a separate named worker. Conceptually:

```js
return condition
  ? {$: "$JMP", f: $worker_yes$, x: [{$: "Unit"}, capture1, capture2]}
  : {$: "$JMP", f: $worker_no$, x: [{$: "Unit"}, capture3]};

function $worker_yes$(unit, capture1, capture2) {
  // Original branch body, with binding identities preserved.
}
```

The unchanged reviewed `run_loop` already invokes `r.f(...r.x)`. This uses its
existing multiargument message; it does not call unary `run_tail` incorrectly
or introduce an adapter. Only the selected packet is constructed, after the
condition is evaluated once. The Unit parameter keeps its binding and identity
within that branch. Non-tail arguments are evaluated inside the worker, at
their original point; they are not transplanted into the enclosing function.

Capture only identifiers referring to initialized, dominating lexical bindings.
Parameters require a binding-write check; `const` declarations after the site
are not eligible because the original closure may defer a TDZ access. Exclude
mutable/assigned captures and unsupported binding forms initially. Do not
capture projections or evaluate getters while constructing a packet. Resolve
nested-arrow scopes and transitive free references; distinguish member names,
object keys and bindings from reads. Fresh worker names must not collide with
any binding. Reject lexical `this`, `arguments`, `new.target`, `super`, dynamic
evaluation and unsupported control flow rather than infer their equivalence.

Runtime and public wrappers stay byte-identical. Public forced observations,
partial/extra arguments, chosen/unchosen demand and exceptions remain required.
Private unforced message identity, reflective function/stack text and hostile
prototype mutation remain outside the existing checked-image contract. Explicit
capture parameters may themselves enlarge frames, so resource gates remain hard.

## Frozen setup and bounded sequence

Baseline is Phase12 commit `9a4e1098043ef32a080a41440aa84728078d0d7b`, unchanged
upstream b2111cf, attempt `selfhost/build/phase12/integrated-03`. Checked parent:
`a8453133f37a0965b7291795af2e06c7c65e3ee7c97a8ff4b14b98cfba2e5568`.
Released API:
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
The normalizer seed remains at its released original bytes.

1. Reproduce exact version5 bytes/statistics using the shared representation.
   Record added/removed active code, retained history code and concept obligations.
2. After root's fresh profile, choose one hot owner/family. `norm_eval_node` is
   a static candidate, not a predeclared performance winner. Count eligible sites,
   lexical captures and actual closure/message operations on small valid inputs.
3. Produce a separately identified derivative and deterministic replay function
   `transform(source, options) -> {source, report}`. Bind parent, source, helper,
   options, runtime, Base, ABI and all consumed tools; never forge bootstrap status.
4. Independent reviewer controls challenge TDZ, writes, shadowing, nested arrows,
   object/member reads, Unit capture, effect/error order, arity, raw values and
   deep tail execution. Preserve every failed candidate and actual input.
5. Before any timing, require fresh long-string and both exact53/60-request
   histories, unchanged4MiB stack/4GiB heap, byte-identical hosts and per-image
   validated caches. Any baseline-accepted history regression rejects the image.
6. Only a survivor reaches same-source checking and memory screening, then
   broader correctness, authentic historical replay and root's controlled matrix.
   Node24.18.0 and fixed CPU affinity apply; no simultaneous intentional compiler
   or archive jobs during final measurements. Launch errors/signals/timeouts are
   failures even if a wrapper supplies status0.

## Ownership and preservation

Owner writes only this record, `implementation/phase13/rewriter.md`,
`selfhost/tools/performance/phase13/rewriter-*` and isolated
`selfhost/build/phase13/rewriter-*`. No production helper/source/dist or pinned
upstream edits initially. Root owns integration/release and final archive.
Plans remain unchanged after freezing; outcomes and corrections go in the report.
