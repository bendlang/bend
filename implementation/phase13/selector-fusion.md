# Phase13 selector fusion

The [prospective followup](../../experiments/phase13/P13-005-selector-fusion.md)
tests whether removing intermediate tag-selection steps is more useful than
replacing closures with explicit captures. Plain worker lifting kept dispatch
unchanged and was 1.01% slower on the paired complete-source pilot. The current
release remains Phase12; this followup has no accepted performance result yet.

The initial rule is restricted to `norm_eval_node`. A removable false arrow has
exactly one returned choice, no use of its Unit parameter, and a nested comparison
of an initialized, unshadowed owner parameter's tag with a literal string.
Declarations, writes and unsupported arrow shapes are refused. Tag/equality
helpers and runtime bindings are checked. The original String equality call and
condition order remain; there is no cached tag or speculative branch evaluation.
Selected bodies keep their original literal arrows and non-tail calls. Selection
itself moves to an earlier frame, so stack equivalence still requires real gates.

## Retained preparation failure

`selfhost/build/phase13/selector-norm-eval-01` fails before producing an API. The
new pass redundantly applied the old guard against every bare generated-function
reference after v5 lowering. Existing valid leaf packets contain precisely such
references in their `f` fields, so the guard refused the input. This is an adapter
mistake, not a semantic or performance result. The failed helper and consumed
inputs are retained in that attempt's `consumed/` directory.

The correction retains v5's original binding validation and checks the new
pass's actual dependencies again: tag access, String equality and trampoline
helpers. These have no existing bare leaf-packet references in the pinned input.
Unknown references to those dependencies still fail closed. The retry uses a
new attempt directory; the failed record is unchanged.

Independent semantic controls, fresh-string and exact-history gates, operation
counts and controlled measurements will determine the outcome.

## Frozen candidate and diagnostic counts

Attempt `selector-norm-eval-02` produces API
`5a1a9449ec9a190e1bee0b695d211fd83e5672a6e1fc87623c3e3826268d4441`
from the genuine checked Phase12 parent. Five intermediate false selectors
disappear. The Rwt proof check and all selected body arrows remain separate.

The independent operation probe passes exact loading/checking on two-module graphs
with 4, 16 or 64 definitions per module. At 64 definitions per module, actual trampoline dispatches decline from
60,344 to 56,799; selected closures/Units decline from 4,254 to 709; consumed
argument-array elements decline from 70,287 to 66,742. The 3,545 removed selector
steps each eliminate a closure, Unit, message, singleton array and dispatch.
These are instrumented operation counts, not allocated-byte or timing results.
Evidence: `selfhost/build/phase13/rewriter-selector-counts-01/report.json`.

## Independent gates and first timing

The actual transformation passes 30 paired demand/error/ABI observations and
23 refusal controls. A separate check compares the manifest-selected v5 baseline
with the exact candidate: all nine surviving arrows are byte-identical to their
original source ranges; five intermediate false arrows disappear. The first
body-identity harness used the raw checked parent by mistake and is retained as
a setup failure; the corrected comparison passes. See [independent controls](controls.md).

Both fresh 6,000-character checks and the paired exact 53/60-request histories
pass: all 226 complete historical observations match the retained released
results and their paired baseline. No worker recycle, launch error or input
drift occurred. Evidence: `selfhost/build/phase13/measure-selector-history-01`.

The exclusive CPU0 ABBA pilot then checks the exact complete compiler source:

| Mean of two fresh processes | Phase12 baseline | Selector candidate |
| --- | ---: | ---: |
| Process wall | 27.3299 s | 25.5166 s |
| Request | 26.1801 s | 24.3722 s |
| Maximum observed RSS | 1,345,268 KiB | 1,337,296 KiB |

This is 6.63% less process time and 6.91% less request time, with identical
complete ordinary checker results. The pilot uses the same source, hosts, Node,
4MiB stack and 4GiB heap; each API has its own validated Base cache. No TypeScript
comparison or generated-user-code gain is inferred from this experiment.
Evidence: `selfhost/build/phase13/measure-selector-pilot-01/report.json`.

The gain earns the prospective plan's bounded opportunity inventory for other
owners under the exact same rule. It does not yet earn production integration:
the prototype still carries 626 helper/support/historical lines against the
maintained helper's 296, before tests. Any relaxed grammar or binding domain
requires a separately recorded prospective decision and independent controls.
