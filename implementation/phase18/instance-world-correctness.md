# Phase18 checker world: representation and correctness checkpoint

The isolated world representation passes its scoped equivalence and transport
checks. It adds **87 physical lines, 72 nonblank lines, 3,594 bytes, 13 definitions
and two types**, with no removed laws or semantic visitor. Cost is still a
separate root-coordinated gate. This checkpoint does not justify installing the
representation or claim to fix either chronology gap.

The [prospective design](../../design/phase18/instance-world-representation.md)
starts from the exact Phase17 `find-worker-source-01/project`. Final candidate is
`instance-world-source-03`, genuinely checked in `instance-world-build-03`, API
`dc884368665186eff97094201f5b5fa1bc5a8f2a10ac00fb017a35bef20b008d`.
Only five Bend modules change: kernel, specializer, annotation, diagnostic trace
and diagnostic production. Public exports, runtime, host, cache format, upstream
pin and maintained version5 derivation remain unchanged.

## What the ablation actually changes

KEnv replaces its book field with a KWorld reference and adds instance depth.
KChecked retains its four old fields and appends the result world and consumed
comptime-application count. KWorld contains the original semantic book, memo and
explicit fresh-state availability. It contains no error or checked-output field;
the result retains the single failure owner.

Fresh state has Known and Deferred constructors. Ordinary public entry creates
Deferred without reading any book field. This was a necessary correction to the
initial interface proposal: eagerly computing a bound would demand previously
irrelevant plain-book bodies. Existing specializer crossings already own the
actual fresh value and memo and carry those as Known. Stage1 never resolves
Deferred; future instantiation must separately prove the bound covers the owner
body and temporaries as well as visible definitions.

Leaf diagnostics receive their actual environment world. A translated failure
keeps the completed check's world/count, including through trace, note and
captured-template diagnostic reconstruction. Successful generic checking restores
the caller's book view while preserving result memo/fresh/count. Failure retains
the actual private generic scope. Ordinary successes share their world reference.

There are no new instance effects. Existing eager sibling evaluation, source
body/event order, postcheck specialization and final TODO handling remain in
place. Actual checking still produces consumed count zero. Nonzero counts in
transport controls are deliberately injected sentinels; they demonstrate field
preservation, not comptime-application consumption. Source bodies remain source
bodies, and no checked-output migration has occurred.

## Closed gates

| Gate | Recorded result |
| --- | --- |
| Genuine checked B1 + maintained derivative + default 36 witnesses | Pass; two inherited strict diagnostic differences retained |
| Frozen chronology controls against exact parent and pinned TS | 22/22 complete outcome records equal to parent; both known TS differences retained |
| Direct representation, diagnostics, demand and public-result controls | 42/42 pass |
| Public ABI2 materialized instance-name sets | 8/8 exact against TS and declared names |

The 42 direct controls include distinct nonempty worlds and nonzero counts,
first-error preservation, application/comparison/rewrite and quantity failures,
successful lambda/let rebuilding, diagnostic trace/note/template translation,
specializer failure translation, generic success/failure scope, and explicit
Known/Deferred transfer. Eight rows compare complete public program results and
annotation books; these overlap the eight memo fixtures and are not additional
unique conformance coverage. Exact-prefix and empty-book paths are included.

Demand controls cover both sides: an entirely poisoned book remains unread by
world construction and a closed-law check; an unused poisoned body remains
unread. Live references still demand the book/body, erased references still
leave the body untouched, and definition validation still demands its required
body. These are controlled low-level API witnesses, not claims about arbitrary
malformed language input.

Internal helpers were exposed only through separate named probe extensions.
Each production API is the exact byte prefix of its corresponding extension;
manifested suffixes wrap already present compiled functions. The production
export list was never changed. Extension hashes are distinct from production
API hashes and are retained with the direct report.

## Attempts and limitations

Build01 correctly refused a new unannotated KEnv constructor binding. Source02
added the required local type annotation and passed checked/default gates. An
independent review then found metadata transport misses that ordinary zero-count
language tests could not expose: two derived failures used an enclosing world,
and some translated failures/successful rebuilds reset the count. Source03 fixes
those with direct successful record reconstruction and an error-only transfer
helper. All sources, consumed tools and the failed bootstrap remain retained.

This is an increase in source size and concepts. It retains KSpecState and the
specialization visitor while introducing world and fresh-availability records.
The two unchanged diagnostic gaps are precisely why stage2 would need immediate
instance checking and ordered child-state propagation. No such semantic change
is authorized or implemented in this checkpoint.

[Machine evidence](instance-world-correctness.json) binds source patches,
attempts, raw vectors, demand controls, tools and designs. The prospective
[measurement contract](../../design/phase18/representation_cost.md) uses the exact
same source in fresh TS/B/C/C/B/TS processes and a 5% process-overhead screening
threshold. No timing or memory conclusion is drawn here.

## Public representation boundary found after the focused checkpoint

The low-level exported `specialize_book` returns KSpecialized whose `error` field
contains KChecked. Source03 therefore exposes the two extra internal world/count
fields in that raw result. The closed whole-result controls above compare public
program DResult and annotation output, not raw KSpecialized byte equality.
`specialized_error` and `specialized_diagnostic` retain their results, and the
public ABI capability numbers did not change, but this is still a real raw-result
compatibility change. Source03 must not be promoted with an implicit reinterpretation
of that result. The next proposed correction is a Bend-side stable payload
projection, preserving the historical four-field KChecked at this boundary and
keeping the expanded internal checking result separate. No host wrapper is proposed.

The subsequent [cost screening](instance-world-cost.md) is neutral. It does not
remove this compatibility prerequisite or establish full public-shape equivalence.
