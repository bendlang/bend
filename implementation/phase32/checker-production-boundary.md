# Why the checker microexperiment is not a public fast path

Current status: no production admission. The checker experiments retain
H17's original public module unchanged and append private diagnostic entries.
The measured immutable-input domain is narrower than both the emitted public
JavaScript ABI and the compiler host adapter's current contract.

The [direct-call experiment](checker-direct-calls.md) retains a concrete
counterexample. A record getter changes G.dn during lookup; captured private
code misses that update. The separate field-read experiment retains another:
the old projection slice reads an unselected getter that changes the selected
name, while a single direct read omits that effect. A once-per-public-entry
function guard handles neither arbitrary input callbacks nor their later
mutations. Both original public modules keep the old observations.

## Existing ABI is not an ownership certificate

Inspection of `selfhost/tools/compiler-abi.mjs` finds useful copying and view
isolation, but no recursive plain-data or no-callback certificate:

-`encode` immediately returns the raw graph for an existing decoded view;
  it intentionally does not inspect children again. The maintained
  `test-compiler-abi.mjs` explicitly checks that
  `encode(decode(lazyRaw))` retains a throwing child getter without traversal.
-Non-object values, including JavaScript functions, pass through unchanged.
  Constructor metadata records field names, not a validated type for each leaf.
-Cycles and sparse arrays are supported deliberately. They cannot silently be
  reclassified as finite, dense, deeply immutable constructor graphs.
-`wrap` invokes the optional `onPhase` callback after encoding and before
  entering the method. A validity token installed before that callback could
  already be invalid at invocation.
-Read-only views prevent ordinary host edits through those views; that does not
  prove every underlying object came from an unobservable private producer or
  that mutable module G and inherited runtime hooks remain unchanged.

Fresh encoding does replace host getter-bearing record containers with new
ones, but all getters run during encoding and may change module bindings.
The ordinary handoff also mixes fresh data with unwrapped existing graphs.
Therefore neither `encoded > 0` nor `view is read-only` supplies the needed
proof. Do not skip the old path based on either condition.

A reusable owned-graph brand would need schema/leaf validation during encoding,
proven producer ownership for returned graphs, a private capability that host
inputs cannot forge, invalidation/lifetime rules, and admission after all
callbacks. The invocation must then be closed against later host callbacks,
foreign code, mutation and relevant prototype hooks. Its validation/branding
cost, retained memory and repeated-view benefit must be measured separately.
This is substantially more work and concepts than the26-call transformation;
it is not justified by its first6–9% lookup-only result alone.

## A narrower possible production route

An isolated compiler worker may establish the boundary with fewer per-node
runtime mechanisms. It would accept only validated plain structured messages,
import its pinned generated compiler privately, and expose neither G nor raw
ADT references. While checking, it would execute only the known synchronous
compiler graph, with no user JavaScript callbacks, user foreign implementation
or reentrant host entry. Messages and cached compiler outputs would remain
owned by that worker. These are proposed requirements, not established facts
about the existing worker tools.

A future test must first audit every message/entry, module dependency, callback,
foreign-code path, cache handoff and relevant intrinsic. It must retain generic
in-process/public execution unchanged, then compare complete normal compilation
requests, diagnostics, source graphs, outputs and cache provenance before any
speed result. A new private H image also needs actual-hash Base preparation;
the old H17 cache cannot merely be relabeled. No whole-compiler benefit follows
from the helper screen, and normal checked-B1 compilation would not become
faster automatically because it uses a different generated implementation.

This could become a general closed execution mode, but adding such a mode is a
separate design/implementation decision. No compiler-name recognition, broad
recursive-type exception or omission of existing exact-entry guards is proposed
for production in this phase. The existing local-region proof can independently
expand toward internally produced recursive structures once producer closure,
recursive call/stack behavior and typed layouts have their own evidence.
