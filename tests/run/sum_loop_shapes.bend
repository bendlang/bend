# A def that answers a Nat or a U32 and adds one call to itself in its tail
# runs as a loop on the C lane however the add is spelled: the call bound by
# a let first, adds inside adds, successors over an add and an add over
# successors, U32.add (which wraps: here past 2^32), and a def that also
# tail-calls a def that forks, or sums a def that recurses. The loop keeps
# the sum in a first parameter of a second def, d~acc, and the answer of
# every other arm is added to it. What must stay a recursion and answer the
# same: a bound call used twice, U32.sub (not associative), F32.add (the
# order changes the rounding: 64 ones under 1e8 are lost one at a time, and
# kept if summed first), a call behind ! and a call in a closure. An arm
# that cannot run (it holds a value of the empty type) stays as it is. Every
# count comes from the command line's length (1 in the harness), which no
# compiler sees.
import Base

def bound(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      r = bound(p)
      Nat.add(n, r)

def nest(+n: Nat) -> Nat:
  match n:
    case 0n:
      3n
    case 1n+p:
      Nat.add(1n, Nat.add(Nat.mul(n, 2n), nest(p)))

def succs(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      2n+Nat.add(n, 1n+succs(p))

def usum(+n: Nat, +k: U32) -> U32:
  match n:
    case 0n:
      7
    case 1n+p:
      U32.add(k, usum(p, U32.mul(k, 3)))

def ulet(+n: Nat, +k: U32) -> U32:
  match n:
    case 0n:
      k
    case 1n+p:
      r = ulet(p, U32.add(k, 1))
      U32.add(U32.add(r, k), 4000000000)

def psum(+d: Nat) -> Nat:
  match d:
    case 0n:
      1n
    case 1n+p:
      a b = psum(p) psum(p)
      Nat.add(a, b)

def tofork(+n: Nat, +d: Nat) -> Nat:
  match n:
    case 0n:
      psum(d)
    case 1n+p:
      Nat.add(n, tofork(p, d))

def slow(+n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.mod(Nat.mul(3n, slow(p)), 1000003n)

def over(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(slow(Nat.mod(n, 7n)), over(p))

def shared(+n: Nat, +xs: List<&2, Nat>) -> Nat:
  match n:
    case 0n:
      List.length(&2, Nat, xs)
    case 1n+p:
      Nat.add(List.length(&2, Nat, xs), shared(p, Con{n, xs}))

def twice(+n: Nat) -> U32:
  match n:
    case 0n:
      3
    case 1n+p:
      +r = twice(p)
      U32.add(r, U32.add(r, 1))

def down(+n: Nat, +k: U32) -> U32:
  match n:
    case 0n:
      k
    case 1n+p:
      U32.sub(k, down(p, U32.add(k, 3)))

def fsum(+n: Nat, x: F32) -> F32:
  match n:
    case 0n:
      x
    case 1n+p:
      F32.add(1.0, fsum(p, x))

def banged(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(n, banged!(p))

def app(f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def clo(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      app(y => Nat.add(y, clo(p)), n)

type Opt is Data:
  No{e: Empty}
  Yes{v: Nat}

def absurd(+n: Nat, +o: Opt) -> Nat:
  match n:
    case 0n:
      match o:
        case No{e}:
          match e:
        case Yes{v}:
          v
    case 1n+p:
      Nat.add(n, absurd(p, o))

def show(+one: Nat) -> String:
  String.join([
    Nat.show(bound(Nat.mul(1000n, one))),
    Nat.show(nest(Nat.mul(1000n, one))),
    Nat.show(succs(Nat.mul(1000n, one))),
    U32.show(usum(Nat.mul(40n, one), 5)),
    U32.show(ulet(Nat.mul(1000n, one), 9)),
    Nat.show(tofork(Nat.mul(100n, one), Nat.mul(5n, one))),
    Nat.show(over(Nat.mul(500n, one))),
    Nat.show(shared(Nat.mul(300n, one), [7n, 8n])),
    Nat.show(bound(Nat.mul(20000n, one))),
    U32.show(twice(Nat.mul(40n, one))),
    U32.show(down(Nat.mul(101n, one), 10)),
    F32.show(fsum(Nat.mul(64n, one), 100000000.0)),
    Nat.show(banged(Nat.mul(30n, one))),
    Nat.show(clo(Nat.mul(300n, one))),
    Nat.show(absurd(Nat.mul(1000n, one), Yes{7n}))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|500500
#|1002003
#|503500
#|1724892247
#|1385956933
#|5082
#|77642
#|45752
#|200010000
#|4294967295
#|4294967143
#|100000000
#|465
#|45150
#|500507
