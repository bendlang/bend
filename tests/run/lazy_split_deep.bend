# lazy splits: a fork chain 20000 frames deep on one thread (each level forks
# its rest against one small leaf), beside a tiny sibling, so that the idle
# threads split the chain's oldest frames while it is deep; then the same
# chain with its sides swapped, the long side second
import Base

def leaf(+i: U32) -> U32:
  (i * 2654435761 + 7 : U32)

def chain(+n: Nat, +i: U32) -> U32:
  match n:
    case 0n:
      leaf(i)
    case 1n+p:
      a b = chain(p, (i + 1 : U32)) leaf(i)
      (a + b : U32)

def chain2(+n: Nat, +i: U32) -> U32:
  match n:
    case 0n:
      leaf(i)
    case 1n+p:
      a b = leaf(i) chain2(p, (i + 1 : U32))
      (a * 3 + b : U32)

def fill(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      leaf(i)
    case 1n+p:
      a b = fill(p, (i * 2 : U32)) fill(p, (i * 2 + 1 : U32))
      (a + b : U32)

def top(+n: Nat) -> U32:
  a b = chain(n, 1) leaf(5)
  c d = leaf(9) chain2(n, 2)
  (a + b + c + d : U32)

# the filler takes the rows a grow fills, so the chains run in a drain
def main() -> U32:
  x y = fill(9n, 1) top(20000n)
  (x + y : U32)

#|1363575357
