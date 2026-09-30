# P32-003: semantic-reuse

Status at creation: investigate; no measurement or promotion.

Hypothesis: A measurable fraction of unchanged semantic work can be safely reused with complete dependency identities.

Domain, proof obligations, ownership, falsification and integration gates are in
[the campaign design](../../design/phase32/representation-and-reuse.md).
The owner must freeze the exact derivative and measurement plan before timing.
Failures and neutral outcomes remain evidence; no gain is presumed.

Results will be linked from [the Phase32 report](../../implementation/phase32/README.md).

Completed; full-world retention is rejected for normal library requests. The
bounded checkpoint prototype preserves 22 complete observations and can skip
484–508 events, but equality/freezing/retention remains expensive. Two duplicate/
order fixtures are parse refusals, not event-level checker coverage. This does
not reject dependency reuse in a persistent inspector with shared immutable
Base identities. [Report](../../implementation/phase32/reuse-counts.md).
