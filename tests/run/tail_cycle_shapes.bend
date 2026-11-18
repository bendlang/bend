# A tail-call cycle across defs is one loop when one of its defs (a head) is
# on every turn and the others are each called from one place: a ring of
# three entered at each def, a helper with a caller outside the cycle too, a
# def that calls itself and another, a def called from two places. A cycle
# with no head (pa and pb each call themselves) stays as it was. Three
# million turns run in constant stack. IO.now keeps the counts out of
# constant folding.
import Base

# a ring of three, entered at each def
@unsafe
def r0(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      r1(p, U32.add(acc, 1))

@unsafe
def r1(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, 1000)
    case 1n+p:
      r2(p, U32.mul(acc, 3))

@unsafe
def r2(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, 2000000)
    case 1n+p:
      r0(p, U32.xor(acc, 5))

# a helper with a caller inside the cycle and one outside
@unsafe
def col.if(even: Bool, +n: Nat, steps: Nat) -> Nat:
  match even:
    case True{}:
      col(Nat.div(n, 2n), 1n+steps)
    case False{}:
      col(Nat.add(Nat.mul(n, 3n), 1n), 1n+steps)

@unsafe
def col(+n: Nat, steps: Nat) -> Nat:
  match n:
    case 0n:
      steps
    case 1n:
      steps
    case 1n+p:
      col.if(Nat.is_eq(Nat.mod(n, 2n), 0n), n, steps)

def col.from_even(+n: Nat) -> Nat:
  col.if(True{}, n, 100n)

# a self tail call and a cross tail call in one def; the other def is no head
@unsafe
def hop(n: Nat, acc: Nat) -> Nat:
  loop(n, False{}, acc)

@unsafe
def loop(n: Nat, b: Bool, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      match b:
        case True{}:
          hop(p, Nat.add(acc, 2n))
        case False{}:
          loop(p, True{}, 1n+acc)

# no head: each def calls itself and the other
@unsafe
def pa(+n: Nat, +k: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      pa.if(Nat.is_eq(Nat.mod(p, k), 0n), p, k, acc)

@unsafe
def pa.if(sw: Bool, n: Nat, +k: Nat, acc: Nat) -> Nat:
  match sw:
    case True{}:
      pb(n, k, 1n+acc)
    case False{}:
      pa(n, k, acc)

@unsafe
def pb(+n: Nat, +k: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      Nat.add(acc, 1000000000n)
    case 1n+p:
      pb.if(Nat.is_eq(Nat.mod(p, k), 0n), p, k, acc)

@unsafe
def pb.if(sw: Bool, n: Nat, +k: Nat, acc: Nat) -> Nat:
  match sw:
    case True{}:
      pa(n, k, Nat.add(acc, 3n))
    case False{}:
      pb(n, k, acc)

# a def called from two places in the cycle
@unsafe
def two(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n:
      two.a(0n, acc)
    case 2n+p:
      two.b(p, 1n+acc)

@unsafe
def two.a(n: Nat, acc: Nat) -> Nat:
  two.b(n, Nat.add(acc, 10n))

@unsafe
def two.b(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      Nat.add(acc, 5n)
    case 1n+p:
      two(p, Nat.add(acc, 100n))

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    +z : Nat = Nat.mod(t, 1n)
    IO.print(U32.show(r0(Nat.add(10n, z), 0)))
    IO.print(U32.show(r1(Nat.add(11n, z), 7)))
    IO.print(U32.show(r2(Nat.add(12n, z), 9)))
    IO.print(U32.show(r0(Nat.add(3000000n, z), 0)))
    IO.print(U32.show(r1(Nat.add(3000001n, z), 0)))
    IO.print(U32.show(r2(Nat.add(3000002n, z), 0)))
    IO.print(Nat.show(col(Nat.add(27n, z), 0n)))
    IO.print(Nat.show(col.from_even(Nat.add(54n, z))))
    IO.print(Nat.show(col.if(False{}, Nat.add(27n, z), 0n)))
    IO.print(Nat.show(hop(Nat.add(3000001n, z), 0n)))
    IO.print(Nat.show(loop(Nat.add(3000000n, z), True{}, 0n)))
    IO.print(Nat.show(pa(Nat.add(3000000n, z), 2n, 0n)))
    IO.print(Nat.show(pb(Nat.add(3000000n, z), 1n, 0n)))
    IO.print(Nat.show(pa(Nat.add(3000000n, z), 3000001n, 0n)))
    IO.print(Nat.show(two(Nat.add(3000000n, z), 0n)))
    IO.print(Nat.show(two(Nat.add(3000001n, z), 0n)))
    IO.print(Nat.show(two.a(Nat.add(3000001n, z), 0n)))
    IO.print(Nat.show(two.b(Nat.add(3000002n, z), 0n)))

#|1055
#|486
#|2000969
#|3431156224
#|409817472
#|407818478
#|111
#|212
#|111
#|4500001
#|4500000
#|3000000
#|1006000000
#|1000000001
#|101000000
#|101000015
#|101000110
#|101000115
