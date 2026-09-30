# Conditional integration of per-depth tree frames

This supplement proposes the smallest emitter-only change if the isolated
actual12 frame-reuse experiment earns promotion. It changes no admission rule,
runtime helper, value representation or analysis state. Do not apply it merely
because the allocation counters improve; retain the actual checked compiler
controls and a fresh timing confirmation after integration.

In `selfhost/src/back/js/tree.bend`, change the final pop in `j_tree_body` from
`$frames.length=--$top;` to `--$top;`. In the non-right branch of
`j_tree_enter`, replace the inline fresh-frame string with
`j_tree_push(succ)`. The call stays immediately after `j_nat_loop_next` and
before `j_nat_loop_assign`. Add these two emission helpers:

```bend
@unsafe
def j_tree_push(+succ: KTerm) -> String:
  "const $saved=$frames[$top++];if($saved){" ++ j_tree_save(succ, 0) ++
  "$saved.phase=0;$saved.left=null;}else $frames[$top-1]={args:[" ++
  j_tree_aliases(succ) ++ "],phase:0,left:null};"

@unsafe
def j_tree_save(+t: KTerm, +at: U32) -> String:
  +body = j_strip(t)
  kc(String, String.eq(tg(body), "Lam"), u =>
    "$saved.args[" ++ U32.show(at) ++ "]=" ++ j_local(ix(body)) ++ ";" ++
    j_tree_save(kid(body, 0), U32.inc(at)), u => "")
```

`j_tree_save` deliberately follows the same stripped lambda telescope as
`j_tree_aliases`, the existing initial-allocation path. Every saved parameter
therefore has exactly one overwritten slot at its original position. Every
frame pushed by this definition has the same arity. There are no trailing
slots whose previous values could survive a shorter later invocation. Reset
both phase and left result, so a previously completed right branch cannot be
mistaken for a newly entered node. Keep the backing array local to the one
private tree invocation; do not cache it in a definition closure.

The invariants are:

1. Entries below `$top` are the active ancestors. Reusing entry `$top` touches
   only a popped frame. When a parent switches from left to right, its frame
   remains at `$top-1`; the next descent can reuse only the deeper entry.
2. All saved arguments are native scalar parent aliases. The tree admission
   excludes container state, escaping functions and parent captures in the
   combine expression. Private helper arguments/results are scalar, and no
   closure can retain either the frame or its `args` array.
3. Left-child argument expressions finish, in their existing order, before
   the push or any reused-slot write. Save the original immutable parent
   aliases, not the computed left arguments. Right-child expressions execute
   only after the full left result and read that same saved parent state.
   The original combine expression runs before the logical pop.
4. The logical top is the sole active-stack measure. The current emitter uses
   `frames.length` only in the removed truncation. A source assertion or exact
   output check should preserve that fact as the emitter evolves.
5. The unchanged guard admits a predecessor less than 32, so the complete tree
   depth is at most 32. There are at most 32 retained frame objects and 32
   argument arrays, each with the already bounded parameter count of at most
   32. Popped storage can live until return, but cannot grow with tree node
   count or persist into the next public call.

The proof retains the ordinary Array/intrinsic scope. Numeric Array.prototype
getters could observe a lookup of an as-yet-empty pool slot; arbitrary changes
to private allocation/indexing intrinsics are outside that existing contract.
Object.prototype runtime-marker hooks still use the existing scalar guard and
generic fallback. No new guard or weaker mutation policy is proposed.

After a checked build, rerun the actual tree admission/refusal book, the
noncommutative and differing-child-state witnesses, inherited ordered public
boundaries, depth sentinels and independent 85 observations. Retain complete
allocation/traversal counts and repeated calls with different palettes and
depths. The actual generated identifier may be `$saved` instead of the
disposable prototype's `$reuseFrame30`; measure the checked output itself and
do not transfer the prototype timing by assumption.
