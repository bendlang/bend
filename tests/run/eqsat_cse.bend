# eqsat: an arm's word expression read twice is computed once (isqrt's
# Newton iterate), a Nat sum reassociates, and units and literals fold. The
# shared iterate below is passed twice; a Nat product read twice stops the
# program with the Nat message on every lane, shared or not.
import Base

def step(+n: Nat, +y: Nat) -> Nat:
  Nat.div(Nat.add(y, Nat.div(n, y)), 2n)

@unsafe
def iter(+n: Nat, +x: Nat, +y: Nat, lt: Bool) -> Nat:
  match lt:
    case False{}:
      x
    case True{}:
      iter(n, y,
        Nat.div(Nat.add(y, Nat.div(n, y)), 2n),
        Nat.is_lt(Nat.div(Nat.add(y, Nat.div(n, y)), 2n), y))

@unsafe
def isqrt(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      iter(n, n, Nat.div(Nat.add(n, 1n), 2n),
        Nat.is_lt(Nat.div(Nat.add(n, 1n), 2n), n))

def sum(+i: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      sum(p, Nat.add(acc, isqrt(i)))

# U32 units and wrap: (x + 0) * 1 ^ 0 | 0 and a sum that wraps
def mix(+x: U32, +y: U32) -> U32:
  U32.xor(U32.mul(U32.add(x, 0), 1), U32.add(U32.add(y, 4294967295), U32.or(x, 0)))

def twice(+a: Nat, +b: Nat) -> Nat:
  Nat.add(Nat.mul(Nat.add(a, b), Nat.add(b, a)), Nat.mul(Nat.add(a, b), 3n))

# a Nat difference both ways round is two values; a literal picks an arm
def both(+a: Nat, +b: Nat) -> Nat:
  +d = Nat.sub(a, b)
  +e = Nat.sub(b, a)
  Nat.add(Nat.mul(Nat.add(d, 1n), Nat.add(d, 1n)), Nat.mul(Nat.add(e, 1n), 10n))

def small(n: Nat) -> Nat:
  match n:
    case 0n:
      100n
    case 1n+p:
      p

# y and z are one value; the closures of the do block read both
def shown(+x: Nat) -> IO(Unit):
  +y = Nat.mul(x, Nat.add(x, 1n))
  +z = Nat.mul(x, Nat.add(x, 1n))
  do IO<Unit>:
    IO.print(Nat.show(Nat.add(y, z)))
    IO.print(Nat.show(Nat.add(Nat.add(small(0n), small(5n)), z)))

def main() -> IO(Unit):
  do IO<Unit>:
    shown(12n)
    IO.print(Nat.show(both(10n, 3n)))
    IO.print(Nat.show(both(3n, 10n)))
    IO.print(Nat.show(sum(5000n, 0n)))
    IO.print(U32.show(mix(7, 5)))
    IO.print(Nat.show(twice(1000n, 234n)))
    IO.print(Nat.show(twice(16777216n, 1n)))

#|312
#|260
#|74
#|81
#|233275
#|12
#|1526458
#|bend: a Nat past the largest immediate 2^48-1
