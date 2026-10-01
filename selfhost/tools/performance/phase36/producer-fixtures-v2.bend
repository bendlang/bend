import Base

type PTree is Data:
  PLeaf{value: U32}
  PNode{left: PTree, right: PTree}

def p.choose(code: Nat, left: PTree, right: PTree) -> PTree:
  match code:
    case 0n: PNode{left, right}
    case 1n+p: PNode{right, left}

def p.leaf(seed: U32, z: Bool) -> PTree:
  match z:
    case False{}: PLeaf{U32.add(seed, 9)}
    case True{}: PLeaf{U32.xor(seed, 17)}

# Sequential independent children and parent-dependent combiner.
def p.gen(+depth: Nat, +seed: U32) -> PTree:
  match depth:
    case 0n: p.leaf(seed, U32.is_lt(seed, 40))
    case 1n+p:
      left = p.gen(p, U32.add(U32.mul(seed, 3), 1))
      right = p.gen(p, U32.add(U32.mul(seed, 5), 7))
      p.choose(U32.to_nat(U32.mod(seed, 2)), left, right)

# Parallel children are already in the recognized source form.
def p.parallel(+depth: Nat, +seed: U32) -> PTree:
  match depth:
    case 0n: p.leaf(seed, False{})
    case 1n+p:
      left right = p.parallel(p, U32.add(seed, 3)) p.parallel(p, U32.add(seed, 5))
      p.choose(0n, left, right)

# Repeated references must preserve alias identity, not copy or memoize trees.
def p.share(+depth: Nat, +seed: U32) -> PTree:
  match depth:
    case 0n: p.leaf(seed, False{})
    case 1n+p:
      +left right = p.share(p, U32.add(seed, 3)) p.share(p, U32.add(seed, 5))
      p.choose(0n, left, left)

def p.hash(tree: PTree) -> U32:
  match tree:
    case PLeaf{value}: value
    case PNode{left, right}: U32.add(U32.mul(p.hash(left), 31), p.hash(right))

def p.size(tree: PTree) -> U32:
  match tree:
    case PLeaf{value}: 1
    case PNode{left, right}: U32.add(1, U32.add(p.size(left), p.size(right)))

def producer_check(depth: Nat, seed: U32) -> U32:
  p.hash(p.gen(depth, seed))

def producer_parallel(depth: Nat, seed: U32) -> U32:
  p.hash(p.parallel(depth, seed))

def producer_share(depth: Nat, seed: U32) -> U32:
  p.hash(p.share(depth, seed))

# RHS dependence refuses flattening, while generic execution remains valid.
def p.dependent(+depth: Nat, +seed: U32) -> PTree:
  match depth:
    case 0n: p.leaf(seed, False{})
    case 1n+p:
      +left = p.dependent(p, U32.add(seed, 1))
      right = p.dependent(p, p.hash(left))
      p.choose(0n, left, right)

def producer_dependent(depth: Nat, seed: U32) -> U32:
  p.hash(p.dependent(depth, seed))

# One-child recursion is intentionally outside the binary subset.
def p.unary(+depth: Nat, +seed: U32) -> PTree:
  match depth:
    case 0n: p.leaf(seed, False{})
    case 1n+p:
      +child = p.unary(p, U32.add(seed, 1))
      p.choose(0n, child, child)

def producer_unary(depth: Nat, seed: U32) -> U32:
  p.hash(p.unary(depth, seed))

def main() -> U32:
  producer_check(3n, 42)
