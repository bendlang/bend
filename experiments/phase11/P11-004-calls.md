# P11-004 — Remove choice-closure allocation while keeping tail boundaries

Prospective plan registered before probes, 2026-09-28. Owner: calls subagent;
reviewer: root. Initial read-only/investigation budget about10minutes, followed by
one justified checked candidate. Baseline Phase10 integrated01, selected API
`ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9`;
upstream b2111cf. No production source, installed artifacts or pinned checkout
mutations. Report: [calls](../../implementation/phase11/calls.md).

## Why this is not ordinary uncurrying

Pinned `comp.ts` already emits saturated calls directly; its current overhead
is different. Every literal-thunk `kc`/`f_choose` call allocates two `run_clo`
wrappers plus the two underlying branch closures, then returns a trampoline
message to the selected closure. The self-hosted JS emitter already recognizes
this choice pattern; upstream-generated B1 does not. Phase4/5 ordinary-call
transforms had weak/zero opportunity, and Phase6 stability workers added source
complexity with an unresolved malformed-H gate. Phase10's narrower index loop
proved that exposing real control flow can help; none of those old timings is
transferred to this artifact.

## First falsifiable candidate

For a structurally verified choice function and two literal `run_clo` arrow
arguments, replace `choice(condition, run_clo(yes), run_clo(no))` by
`run_tail(condition ? yes : no, Unit)`. The original runtime already unwraps a
fresh run_clo wrapper to its underlying arrow before placing it in its tail
message. Keep that trampoline boundary: naively invoking the chosen arrow can
turn stack-safe tail recursion into recursion on the JS stack. This candidate
removes unchosen closure allocation and both wrapper functions/properties; it
does not claim removal of every trampoline or closure.

First inspect/count structural sites in the exact checked image; then disposable
instrumented allocation counts and tiny boundary controls. Recognition must use
reviewed definition/runtime bodies, balanced syntax and literal closures, never
callee spelling alone. Preserve conditions and argument evaluation once, closure
lexical scopes, selected-only effects, Unit values, partial/overapplication,
exception order and deep tail behavior. Unsupported shapes remain unchanged.
No change to emitted user program runtime follows from specializing B1.

The native condition uses the original JS truthiness, including malformed raw
Boolean inputs. Structural controls include branches returning ordinary values,
closures, raw `$JMP` objects and exceptions, nested choices, captured variables,
and at least100,000 tail iterations. Mutated protected bodies and nonliteral
thunks must refuse/remain unchanged. Monkeypatched builtin prototypes/getters
are outside the standard runtime assumption and must be stated explicitly.

## Alternative and stop rule

If structural choice allocation is insignificant, stop this global candidate and
use the fresh profile to choose a single source Boolean-worker formulation.
A generic emitter implementation would need separate ownership/type/ABI gates;
a guarded derivative cannot be called a genuine checked bootstrap or a language
semantics change. Only advance after tiny controls and exact selected public
observations. Stop on a semantic mismatch, lost stack safety, weak operation
benefit or lack of robust syntax recognition. Do not repeat ordinary uncurrying
without new evidence.

## Setup and evidence

CPU3, Node24.18.0,4MiBstack,4GiBheap, fresh unique output directories. Record
source/API/runtime/Base/helper and consumed fixture identities before/after.
Coordinate checked-build launches with root. No full-source benchmark, broad
suite or installed release change by this task. Keep every failed/raw run and
preimage, distinguish structural counts and concurrent small screens from root's
controlled full-source measurement. Root owns integration, measurement and archive.

## Final disposition

Maintained version4 promoted; invalid microtimings excluded. See [call report](../../implementation/phase11/calls.md) and [final combined measurements](../../implementation/phase11/known_work.md).
