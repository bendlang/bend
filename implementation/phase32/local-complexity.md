# Local representation complexity and generated size

Counts use the canonical66-module Bend manifest at committed Phase31
`5f3015d1a84ce822d3ee1a8bcb899a517d7f8aec` and immutable checked01/02/03 source
snapshots. Physical lines use splitlines; nonblank lines exclude whitespace-only
lines; declarations are top-level `def`, `law` and `type`. Generated compilers,
runtime, tests, reports and experiment infrastructure are excluded from compiler
source counts. [Exact file identities and counts](local-complexity.json) and the
[small static producer](../../selfhost/tools/performance/phase32/local-complexity.py)
make the comparison reproducible without building or importing a compiler.

| Source | Physical lines | Nonblank lines | Definitions | Laws | Types | Modules |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Phase31 checked07 | 17,014 | 14,529 | 1,878 | 640 | 70 | 66 |
| Phase32 checked01 | 17,025 | 14,539 | 1,879 | 640 | 70 | 66 |
| Phase32 checked02 | 17,060 | 14,570 | 1,883 | 640 | 70 | 66 |
| Phase32 checked03 | 17,071 | 14,580 | 1,884 | 640 | 70 | 66 |

Checked03 adds57 physical lines (+0.335%),51 nonblank lines (+0.351%), six
functions and3,644 source bytes (+0.552%) over Phase31. It adds no datatype,
law or module. The change is confined to local.bend (+8 physical lines),
region.bend (+38), and emit.bend (+11). All66 checked03 module identities matched
the working tree at measurement. Runtime core and stage0-library support remain
byte-for-byte identical to the committed baseline.

## Concepts and maintenance cost

This is a small source increase, not a compiler line-count reduction. Three local
mechanisms explain the extra code:

1. Scoped statement lowering for return-position unpacking, with one field-binding
   emitter and the existing lexical/parallel-let rules.
2. One typed immediate-read bridge node, JReadCall, its producer/consumer shape
   proof, argument emitter and bridge definition. It reuses the bounded graph and
   native dependency guards; no general unboxing or new calling convention is
   exposed publicly.
3. One normalized private-vector layout predicate and JVector plan node, reused
   at construction and both unpack forms. It reuses the existing local-type and
   public-terminal-record proof rather than adding escape analysis or reboxing.

The phrase “three mechanisms” is a qualitative decomposition, not a universal
count of compiler concepts. Two private KTerm tags are new; KTerm itself and the
number of Bend datatype declarations are unchanged. The existing closed graph,
proof budgets, constructor fields, source ABI and fallback model stay in place.
Bridge bodies are duplicated for eligible consumers, including potentially unused
bridges; generated size and ordinary compiler-request cost therefore remain
necessary tradeoff measurements. No claim of architectural simplification follows
from fewer generated allocations alone.

## Generated module bytes

These are complete emitted JavaScript modules, including runtime support. Pair
cohort files have the same74-byte benchmark-export adapter in every Bend variant;
fold files are raw emissions. The TypeScript emitted module sizes are12,537 and
5,191 bytes respectively, but their runtime packaging differs, so these are not
normalized backend-instruction counts.

| Fixture | Phase31 checked07 | Statements01 | Read fusion02 | Private vectors03 |
| --- | ---: | ---: | ---: | ---: |
| Full-pair module | 95,697 | 96,661 | 99,897 | 99,723 |
| Independent fold | 76,606 | 76,730 | 77,475 | 77,433 |

Thus03 is4,026 bytes (+4.21%) larger than07 on the pair and827 bytes (+1.08%)
larger on the fold. Most additional bytes come from private read bridges.
The02→03 increment saves174/42 bytes, respectively. Raw pair emission is96,587
bytes for01,99,823 for02 and99,649 for03. The alias/nested fixture saves30 bytes
(77,233→77,203); scope is unchanged at73,184 bytes.

[The precise vector ablation](../../design/phase32/vector-ablation-scope.md)
includes direct canonical Sigma construction as well as nonterminal ordinary
record shells. In particular, fold's42-byte reduction is three private Tuple
constructor wrappers; it is not evidence about ordinary record allocations.
Source or emitted byte counts do not establish runtime speed.

## Focused correctness evidence

All six gate groups passed in the root's serial `local-checked-controls-03`
acquisition; their receipts and exact hashes are linked by
[the tracked review gate summary](review-local-gates.json). Pair covers six
oracles, four full-state/native-schedule variants and17 public boundaries. Fold
covers41 oracles,16 full-state observations, seven boundaries and three negative
witnesses (two distinguish delayed writes). Actual read-prologue ordering covers
12 scenarios and two negative witnesses. Scope covers40 oracles and three
boundaries. Vector aliases cover40 scalar oracles,40 boxed public-record outputs
and14 boundaries. Compiled type/layout predicates cover21 cases plus the alias
normalization witness. Counts overlap and are not summed as unique conformance.

The maximum supervised process-tree RSS was292.5625MiB, in the pair gate. Every
group stayed within the1,600MiB tree budget and above the2GiB free-memory floor.
The reviewer only inspected retained receipts; no repeat test or benchmark was
run for this report. These are focused gates, not broad conformance or final
release approval. The root-owned final capsule must retain their full raw records.
