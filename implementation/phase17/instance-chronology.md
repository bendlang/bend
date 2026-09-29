# Phase17 live-instance chronology investigation

The installed compiler still has two distinct, measured diagnostic-order gaps.
Fixing them requires the normal checker to instantiate and validate at the live
reference it encounters. Moving the existing specializer earlier retains its own
incorrect ordering inside new instances. No compiler source changed in this
investigation, and no performance claim is made.

The unchanged genuine checked Phase16 attempt was `compact-final-build-01`, API
`35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`.
Reference was pinned TypeScript `b2111cf43244e65f76ddc278ee695e669f720cbf`.
All probes ran serially on CPU1 after root's timing window closed. The original
paired oracle, input verification and resource limits remained in force.

## Actual results

| Scoped observation | Result |
| --- | --- |
| Initial same-body, nested, memo, cycle and growth checks | 18 complete; 17 exact; zero primitive differences |
| Corrected immediate local-lambda nested checks | 4 complete; 3 exact; zero primitive differences |
| Public ABI2 materialized instance-name sets | 8/8 exact, with explicit expected names |
| Compiler/source changes or rebuilds | None |

All 22 paired observations meet their acceptance/refusal contracts. Twenty are
exact; the two remaining strict differences are retained in raw reports. Passing
this experiment means a healthy complete observation, not that the compiler has
become conformant on those two cases.

The first counterexample calls an invalid `app` instance and then returns a Bool
where Nat is required. Upstream first reports repeated consumption of `x` in
`app~0`; the installed compiler reports the later Bool/Nat mismatch in `main`.
Reversing the order reports the ordinary error in both. Making the earlier
instance valid also preserves the later ordinary error in both.

The second counterexample is inside a newly minted template instance:

```bend
def outer(~f: Nat -> Nat, x: Nat) -> Nat:
  g: Nat -> Nat = n => f(n)
  app(~(n => Nat.add(n, n)), x)
def main() -> Nat:
  outer(~(n => Nat.add(n, n)), 1n)
```

Upstream detects the local lambda's repeated `n` in `outer~0` before reaching the
later invalid `app`. Our specialization prewalk reports `app~0` first. Reversing
these operations is exact, as are both controls that make one side valid.
The fixture also contains the ordinary Base import and `app` definition; this
excerpt is not intended as a standalone source.

The first proposed nested witness did not discriminate. It used `f(x)` directly,
so the affine error concerned the outer lambda's `x`, checked only when that
lambda exits. Both compilers correctly reached the nested `app` first. That
falsification is preserved; the local annotated lambda above creates the required
earlier validation boundary. This rules out reasoning from textual occurrence
order alone.

The eight memo controls compare actual final instance names from public
`check_program_diagnostic` with pinned `book_valid`, using their normal completed
books. Repeated keys, interleaved templates, nested templates, decreasing self
reuse, erased calls, same/renamed lambda binders and quantity differences all
match. Erased calls materialize no instances. Existing cycle refusal and both
saved growth boundaries (`grow~9`, `grow~63`) remain exact in the paired set.
These controls constrain a future change; they do not prove all recursion cases.

## Cause and proposed correction

`infer_template` currently checks only closed argument types. ABI2 program
completion checks ordinary source bodies before `specialize_book`. The
specializer then prewalks each new instance before calling the normal checker.
Pinned `term_infer` instead calls `def_inst` immediately, and `def_inst` calls the
same `def_check` before resuming its caller. The Ref result also carries how many
comptime applications the surrounding application chain consumes.

The [review proposal](../../design/phase17/instance-shared-checker.md) recommends
one shared world for visible source book, memo and fresh IDs, threaded through
normal checking. Existing pure comparison/normalization remain readers. Instance
reservation and immediate validation use that same checker, preserving the
canonical key, active recursion identity, per-template numbering and limits.
Child checks must sequence returned state; eager sibling checks against the old
book are insufficient.

A further boundary is original versus checked syntax: upstream stores `Def.v`
and `Def.e`, while our KDef has one body. Source bodies must remain authoritative
for later normalization. Checked output needs a separate output accumulator or
a temporary memo-only materializer that cannot mint or validate. The eventual
objective is to return elaborated children and retire that duplicate traversal.
Existing ABI2 completion and final TODO handling stay in force; arbitrary cached
prefixes cannot silently acquire missing memo state.

The source census finds a 1215-line/108-definition kernel and a
1047-line/104-definition specializer. Forty-seven kernel definitions reach
infer_template in a conservative kernel-only lexical graph; cross-module flows
are not counted. KChecked occurrences are confined to kernel, trace and
specializer; KEnv also appears in annotate. A named duplicate visitor family has
29 definitions plus 28 laws in 280 block lines, excluding unsafe markers. That is
a possible future deletion budget, not an achieved reduction; all new state and
output plumbing counts against it. Several hundred edited lines and several
hours through focused gates are a planning estimate, with no supported speed or
net-line-reduction estimate yet. A representation-only whole-host cost checkpoint
should precede semantic threading.

## Evidence and retained attempts

[Machine report](instance-chronology.json) binds designs, tools, current source,
reference source, every paired vector, memo rows and the source census by hash.
The prospective witness designs are [initial](../../design/phase17/instance-chronology.md)
and [corrected nested](../../design/phase17/instance-nested-witness.md).
Raw attempts are under `selfhost/build/phase17/instance-*`:
`instance-paired-01`, `instance-nested-paired-01`, `instance-memo-01`, and
`instance-source-census-01`.

Preparation01 failed because a guessed pinned cycle-fixture path did not exist.
Its failure record and partial sources remain. Corrected preparation02 used the
actual pinned path and preceded all compiler observations. No setup failure or
strict difference was erased. No production edit, installed-artifact mutation,
commit or push was performed by this investigation owner.
