# Exact event-prefix checkpoint: prospective second prototype

The first complete-state per-definition prototype preserves all15 observations,
but body-edit equality costs about1.1–1.8seconds and visits362,000 objects. Do
not promote it. This successor moves the exact comparison to one initial world
and restores a previously completed event checkpoint, reducing repeated world
construction as well as checking. It remains a saved-generated-code experiment.

Freeze previous request's initial `(world, seen)` at `dg_check_events`, ordered
source definitions and checkpoint `(world, seen)` before each event actually
reached. Compare the new complete initial state exactly. This includes the
full declaration book, specialization memo, checked outputs, fresh bound and
source coordinates. Use iterative equality with a request-local object-pair
memo; never omit coordinates or force a mismatch into a hit.

Initial-world equality alone is insufficient: later events affect signature
filling and publication. For each candidate prefix event require all three:

1. Exact original definition equality (used by `event_error` and publication).
2. Exact `signature_mode(definition, remainingEvents)` result equality, obtained
   by executing the original compiler helper, including the later law fill.
3. Equal presence of a later same-name event, the predicate used by
   `dg_event_publish` to decide whether to install the checked definition.

These, equal initial state, and deterministic pure checker operations establish
the same event transition inductively. Stop at the first mismatch and only jump
to a checkpoint previously reached after every skipped event succeeded. Do not
reuse a failed event or infer a checkpoint after it. Resume the original event
worker with the new remaining source list and the exact cached world/seen state;
normal completion, specialization, trust, diagnostics and emission then run.

Retain only one request's checkpoints and recursively freeze their plain data.
Reuse already frozen graphs and canonical identical prefix entries; no opaque
function/native handle enters the cache. All equality, schedule construction,
freeze and checkpoint maintenance costs belong to the request. Bound10,000
events and one million equality/freeze visits/request. Preserve failed limits.

Correctness uses the prior15-case suite plus closed-law/later-fill edits,
duplicate/order rejection and restoration. Compare full observations and exact
output bytes against ordinary full checking. Include complete dependency paths.
Outer120seconds CPU2 only after root grant; no timing claim from correctness.
A surviving mechanism needs a separate clean edit-loop screen and independent
review of the induction/future-event dependencies before any production API.
Prefer the simpler request-local emitter memo if its measured gain is useful;
this experiment does not authorize a broad incremental compiler rewrite.
