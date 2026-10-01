import Base

# The same tagged records are consumed by the generic and private paths.
type FoldTree is Data:
  Tip{+value: U32}
  One{+child: FoldTree}
  Two{+left: FoldTree, +right: FoldTree}

type FoldResult is Data:
  FoldResult{+score: U32, +weighted: U32}

def fold.make(+n: Nat, +seed: U32) -> FoldTree:
  match n:
    case 0n: Tip{seed}
    case 1n+p: One{fold.make(p, U32.inc(seed))}

def fold.share(+n: Nat, +seed: U32) -> FoldTree:
  +child = fold.make(n, seed)
  Two{child, child}

# Right-before-left call order and subtraction make child-slot mistakes visible.
def fold.value(tree: FoldTree, +extra: U32) -> U32:
  match tree:
    case Tip{x}: U32.add(x, extra)
    case One{x}: U32.inc(fold.value(x, extra))
    case Two{left, right}: U32.sub(fold.value(right, extra), fold.value(left, extra))

def fold.size(tree: FoldTree) -> U32:
  match tree:
    case Tip{x}: U32.inc(x)
    case One{x}: U32.inc(fold.size(x))
    case Two{left, right}: U32.add(1, U32.add(fold.size(right), fold.size(left)))

def fold.weight(tree: FoldTree, +extra: U32) -> U32:
  match tree:
    case Tip{x}: U32.add(x, extra)
    case One{x}: U32.mul(3, fold.weight(x, extra))
    case Two{left, right}: U32.add(U32.mul(7, fold.weight(right, extra)), fold.weight(left, extra))

# These are legal source programs, deliberately outside structural fold proof.
def fold.duplicate(tree: FoldTree, +extra: U32) -> U32:
  match tree:
    case Tip{x}: U32.add(x, extra)
    case One{+x}: U32.add(fold.duplicate(x, extra), fold.duplicate(x, extra))
    case Two{left, right}: U32.add(fold.duplicate(left, extra), fold.duplicate(right, extra))

def fold.changing(tree: FoldTree, +extra: U32) -> U32:
  match tree:
    case Tip{x}: U32.add(x, extra)
    case One{x}: fold.changing(x, U32.inc(extra))
    case Two{left, right}: U32.add(fold.changing(left, extra), fold.changing(right, extra))

def benchDeep(+n: U32, +seed: U32) -> U32:
  fold.value(fold.make(U32.to_nat(n), seed), 7)

def benchShared(+n: U32, +seed: U32) -> U32:
  fold.size(fold.share(U32.to_nat(n), seed))

def benchOrder(+n: U32, +seed: U32) -> U32:
  fold.value(Two{fold.make(U32.to_nat(n), seed), Tip{17}}, 7)

def fold.order.make(+n: Nat, +seed: U32) -> FoldTree:
  Two{fold.make(n, seed), Tip{17}}

def benchOrderLocal(+n: U32, +seed: U32) -> U32:
  fold.value(fold.order.make(U32.to_nat(n), seed), 7)

def benchWeight(+n: U32, +seed: U32) -> U32:
  fold.weight(fold.make(U32.to_nat(n), seed), 7)

def benchRecord(+n: U32, +seed: U32) -> FoldResult:
  +score = fold.value(fold.make(U32.to_nat(n), seed), 7)
  FoldResult{score, U32.mul(score, 65599)}

def benchDuplicate(+n: U32, +seed: U32) -> U32:
  fold.duplicate(fold.make(U32.to_nat(n), seed), 7)

def benchChanging(+n: U32, +seed: U32) -> U32:
  fold.changing(fold.make(U32.to_nat(n), seed), 7)

def bench(+n: U32, +seed: U32) -> U32:
  U32.xor(benchDeep(n, seed), benchShared(n, seed))

def main() -> U32:
  bench(7, 17)
