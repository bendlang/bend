import Base

type ChoiceProbe is Data:
  Lower{value: U32}
  Upper{value: U32}

def make(t: Bool, value: U32) -> ChoiceProbe:
  match t:
    case False{}: Upper{value}
    case True{}: Lower{value}

def consume(value: ChoiceProbe) -> U32:
  match value:
    case Lower{x}: U32.add(x, 1)
    case Upper{x}: U32.mul(x, 2)

# The residual graph is pure, but its tagged sum does not fit the original
# direct-region grammar. No benchmark names or constants identify this helper.
def opaque(+x: U32) -> U32:
  consume(make(U32.is_lt(x, 10), x))

def choose.go(t: Bool, x: U32) -> U32:
  match t:
    case False{}: 0
    case True{}: opaque(x)

def choose(+x: U32, limit: U32) -> U32:
  choose.go(U32.is_lt(x, limit), x)

def traverse(+depth: Nat, +seed: U32, +limit: U32) -> U32:
  match depth:
    case 0n: choose(seed, limit)
    case 1n+p:
      left right = traverse(p, seed, limit) traverse(p, U32.add(seed, U32.shln(1, p)), limit)
      U32.add(left, right)

def bench(depth: U32, seed: U32) -> U32:
  traverse(U32.to_nat(depth), seed, 80)

def main() -> U32:
  bench(8, 3)
