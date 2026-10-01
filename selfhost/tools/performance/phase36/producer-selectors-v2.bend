import Base

type SelectTree is Data:
  SelectLeaf{value: U32}
  SelectNode{left: SelectTree, right: SelectTree}

def s.bool_first(flag: Bool, seed: U32) -> SelectTree:
  match flag:
    case False{}: SelectLeaf{U32.add(seed, 9)}
    case True{}: SelectLeaf{U32.xor(seed, 17)}

def s.bool_last(seed: U32, flag: Bool) -> SelectTree:
  match flag:
    case True{}: SelectLeaf{U32.add(seed, 9)}
    case False{}: SelectLeaf{U32.xor(seed, 17)}

def s.bool_children(flag: Bool, left: SelectTree, right: SelectTree) -> SelectTree:
  match flag:
    case True{}: SelectNode{right, left}
    case False{}: SelectNode{left, right}

# Non-final Nat input, complete 0/1/2/default choices, and observed remainder.
def s.node(code: Nat, +left: SelectTree, right: SelectTree, seed: U32) -> SelectTree:
  match code:
    case 0n: s.bool_children(U32.is_lt(seed, 40), left, right)
    case 1n: SelectNode{right, left}
    case 2n: SelectNode{left, left}
    case 3n+p: SelectLeaf{U32.add(seed, U32.from_nat(p))}

# Existing final-Nat behavior should remain intact inside the same producer.
def s.last(+seed: U32, code: Nat) -> SelectTree:
  match code:
    case 0n: s.bool_first(U32.is_zero(seed), seed)
    case 1n+p: s.bool_last(U32.add(seed, U32.from_nat(p)), U32.is_lt(seed, 40))

def s.gen(+depth: Nat, +seed: U32) -> SelectTree:
  match depth:
    case 0n: s.last(seed, U32.to_nat(U32.mod(seed, 3)))
    case 1n+p:
      left = s.gen(p, U32.add(U32.mul(seed, 3), 1))
      right = s.gen(p, U32.add(U32.mul(seed, 5), 7))
      s.node(U32.to_nat(U32.mod(seed, 6)), left, right, seed)

def s.hash(tree: SelectTree) -> U32:
  match tree:
    case SelectLeaf{value}: value
    case SelectNode{left, right}: U32.add(U32.mul(s.hash(left), 31), s.hash(right))

def selector_check(depth: Nat, seed: U32) -> U32:
  s.hash(s.gen(depth, seed))

def main() -> U32:
  selector_check(3n, 42)

# Complete ordinary roots do not inherit the private producer context.
def s.make(seed: U32) -> SelectTree:
  SelectLeaf{seed}

def selector_outside(seed: U32) -> U32:
  s.hash(s.make(seed))

# An ordinary helper call inside a deferred field retains generic construction.
def s.step(seed: U32) -> U32:
  U32.add(seed, 1)

def s.nonprimitive(seed: U32) -> SelectTree:
  SelectLeaf{s.step(seed)}

def s.refused(+depth: Nat, +seed: U32) -> SelectTree:
  match depth:
    case 0n: s.nonprimitive(seed)
    case 1n+p:
      left right = s.refused(p, U32.add(seed, 1)) s.refused(p, U32.add(seed, 3))
      s.node(U32.to_nat(U32.mod(seed, 6)), left, right, seed)

def selector_refused(depth: Nat, seed: U32) -> U32:
  s.hash(s.refused(depth, seed))
