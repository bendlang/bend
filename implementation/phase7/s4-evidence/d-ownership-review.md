# B mechanism judgment and D ownership review

This is a read-only review of B01, the S4 D design committed at `f94591c`, and
the subsequently created `candidate-b02-project` source. This reviewer moved no
source and ran no compiler/API/benchmark. The parent executed B02's checked
artifact gate; this review independently inspected the source relocation,
context counts and resulting artifact bytes. Final gate evidence is below.

## B after charging its dependencies

B is a **modest net simplification of maintained algorithm implementations**,
not a demonstrated reduction in every form of complexity. It removes a second
canonical graph recursion and a second embedded-error recursion. Their shared
workers already exist; B adds no representation or new recursive algorithm.
The eight small utility substitutions additionally remove redundant interfaces,
but do not remove eight language concepts.

Charge the costs explicitly: ordinary graph loading gains an empty-seed disabling
convention and its nonempty-source-path invariant; `graph.bend` now depends on the
seed worker, which calls graph finishing; and frontend error aliases now depend
on the structured walker in `graph.bend`. Two new forward laws and the explanatory
comment are already included in the net source count. The error projection also
requires preserving empty-name sentinel semantics. This is not a claim of cleaner
layering everywhere.

The net mechanism judgment remains positive because two separately maintained
recursive algorithms—and the need to keep their decisions aligned—are replaced
by existing implementations plus one bounded disabling invariant and projections.
The ownership edges make the savings smaller than raw helper counts imply. There
is no meaningful arithmetic that turns a module edge and a recursive algorithm
into interchangeable units; the judgment must remain attached to those named
changes, not a fabricated “concept score.” Runtime/RSS neutrality is separately
gated.

B01's parser context still grows under the original whole-file rule. Its
5,928-line owner-inclusive set must remain visible alongside the 5,234-line
same-path subtotal. That prevents calling B a uniform context improvement or
closing S4's 50% milestone. The following ownership correction addresses a real
unnecessary dependency; it earns no production-size saving.

## D source review: exact relocation and required artifact gate

`norm_join` and `norm_defs_join` operate only on lists of `KTerm` and `KDef`.
Their bodies require `Nil`, `Con`, their arguments and their own recursive names;
they use no normalizer state, evaluation rule, conversion rule or normalization
helper. Their datatype owner, `core/term.bend`, already defines both data types,
`terms_len`, `has_name` and related structural list operations. The normalizer
already depends on that module. This is a coherent common owner, not an arbitrary
file chosen solely to lower a context count.

Exact B01 source units, including one existing separator after each block:

| `core/normalize.bend` block | Inclusive lines | Physical | Nonblank | Bytes |
| --- | ---: | ---: | ---: | ---: |
| `@unsafe` + typed `norm_join` definition | 5–15 | 11 | 10 | 177 |
| Existing `norm_defs_join` law | 299–303 | 5 | 4 | 88 |
| `@unsafe` + `norm_defs_join` fill | 320–327 | 8 | 7 | 131 |
| Total relocated | | **24** | **21** | **396** |

The actual [B02 patch](b02-ownership.patch) moves those three blocks unchanged to
the end of `core/term.bend`. Independent byte comparison confirms identical
bodies, signatures, `+a/+b`, `List<&2,...>`, return types, unsafe markers,
recursive names, forward law and separator bytes. Only term and normalize
change among all 59 manifest modules. Actual combined totals remain
**14,667 / 12,505 / 470,062**. Moving 396 bytes is not removing 396 bytes.

The moved blocks' SHA256 values are respectively
`e4267053c8329ce819aba453e18fbed08a7d5a7a0a37a1c44910a770491887d7`,
`c176f63b8adf208fa819c74dc548b22bfbf625e48c265825f7eb9e5d2395d685`, and
`2640df6f631e4e164e4ba98d76067fcb2020169e29e6a7f4b13ea8f2da9c39bd`.
B02 term SHA256 is
`4fc40e715ceb59d581b91fb006f84698429e687e1ab86d460fc2d49d878bb80c`;
B02 normalize SHA256 is
`9716a4eed46fae3e0bcd99fb4df3754e89cd2b39d724fc6225d9d11ec5e1b2ab`.

A scan of all manifest frontend/load modules finds only these shared joins as
actual normalization-function references: frontend modules use `norm_join`,
while `load/graph.bend`, `load/seed.bend` and `load/modules.bend` use
`norm_defs_join`. The word `compare` in `seed.bend` is a comment, not a call.
The move therefore removes this parser-to-normalizer ownership dependency.
The seed-worker dependency and frontend-to-graph error ownership remain.

No B01 host/tool/test source refers to either helper name. Component/diagnostic
assembly lists that mention the normalizer already include `core/term.bend`.
The manifest order is term, index, normalize; both moved functions use types
already declared in term and require no new forward declaration. Retaining the
existing `norm_defs_join` law is conservative and meets the bounded design.

Definition positions do change. The pinned JS library emitter uses the explicit
root list and dependency-discovery order (`comp.ts:1424–1483`, `1522–1524`,
`3234–3268`), supporting the expectation that identical reachable bodies yield
identical selected output. That is not a proof about source spans/binder IDs or
every compiler path. Require the fresh checked/default APIs and ordered exports
to match B01 exactly, as designed; otherwise reject this unit and retain B01.
Do not extend B01's measured evidence to merely similar generated code.

## Actual source-owner context and required validation supplement

`core/term.bend` is already in all three original S0 context sets. The parser's
former 534-line normalizer owner can be excluded after the join ownership moves,
but all 24 moved lines remain charged in term. Its 160-line seed owner remains.

| Parser context | Physical | Nonblank | Bytes |
| --- | ---: | ---: | ---: |
| Original S0 fixed task | 5,716 | 4,851 | 198,816 |
| B01 including replacement owners | 5,928 | 5,135 | 212,787 |
| B02 source owners, same whole-file policy | **5,418** | **4,693** | **196,578** |
| B02 source owners minus original S0 | **-298** | **-158** | **-2,238** |
| B02 plus new shared-operation control | **5,560** | **4,834** | **209,145** |
| That supplemented set minus original S0 | **-156** | **-17** | **+10,329** |

These counts are for the actual source relocation and the same original S0
nonproduction entries as the B01 recount. The new maintained
`selfhost/tests/frontend/shared-operations.mjs` costs another **142 physical /
141 nonblank lines / 12,567 bytes**. Its first-error projection, graph ordering
and cached-result controls are relevant validation for this change and cannot
be silently discarded to make review context appear smaller. With that control
included, byte context is **larger** than S0. Further relevant S1–S3 controls are
itemized in the [separate D context recount](d-context-counts.md); these tables do not claim an
exhaustive validation context or general cognitive-effort improvement.

For the source-owner view alone, physical/nonblank/byte reductions are
5.21% / 3.26% / 1.13%. Those narrower percentages must retain that qualification.
Checker context includes both source and destination, so this relocation changes
none of its totals. Backend context includes term but not normalize, so it must
be charged **+24 physical / +21 nonblank / +396 bytes** rather than presented as
unchanged. Context sets overlap and must not be summed.

B01's behavioral/cost evidence can transfer only after the designed observed
artifact identity gate. A02's completed genuine B1→H→H proof remains about A02's
source. D does not establish a later-source fixed point or satisfy the remaining
6,413-line gap to the 50% production milestone.

## Final gate review and recommendation

The parent subsequently completed B02's genuine checked build and 21 focused
observations. Its [artifact identity record](b02-artifact-identity.json) reports
complete/pass, all 55 ordered exports, and nine identical artifact pairs. This
review independently reread both files in each of those pairs and verified their
recorded SHA-256 values and byte equality: the checked API, default derived API,
runtime, Base and five host helper files. The default API hash is
`9826ac8f2cb2ad17ab07d7a1f3fcefc701c64cd44d3c50333b3410d761d98b7f`;
the checked API hash is
`f201bdea7ea4041483b40704f622703945858e981c404a4d7e50979b74370110`.
The B02 attempt records `checked: true`, and its focused validation records
complete/pass. This reviewer executed none of those compiler jobs.

The [release smoke record](release-smoke.json) also reports all 11 installed and
relocated integrity/check/interpreter/JavaScript/CPU-native observations passing.
The relocated package has no upstream checkout. This remains a bounded ordinary
use smoke test, not broad native or GPU validation.

Approve the bounded B02 ownership unit: its exact source move removes an
unnecessary parser dependency, earns zero production-size saving, and now meets
the artifact-identity gate needed to reuse B01's behavioral and cost evidence.
The relevant shared-operation and S2 provenance control files bring parser
review context to **5,687 physical / 4,958 nonblank / 218,720 bytes**: **29 fewer
physical lines, 107 more nonblank lines and 19,904 more bytes** than the original
S0 set. The original B01 recount remains unchanged, and no uniform context
reduction, B02 self-host fixed point or 50% completion is claimed.
