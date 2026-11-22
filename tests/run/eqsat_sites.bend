# eqsat: a def whose arms each call the same def once (work) has one call
# site, its argument chosen by a copy of the match (listops' runOne); pick
# reads an affine parameter in both arms, so it is left as it was; and a
# call under an unused let still runs once per turn.
import Base

def wsum(+i: Nat, +s: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      wsum(p, s, Nat.mod(Nat.add(Nat.mul(acc, 31n), Nat.add(s, p)), 1000003n))

def work(+s: Nat) -> Nat:
  wsum(64n, s, 0n)

def go(+t: Nat, +seed: Nat, acc: Nat) -> Nat:
  match t:
    case 0n:
      Nat.add(acc, work(seed))
    case 1n+p:
      go(p, seed, Nat.mod(Nat.add(acc, work(Nat.add(seed, Nat.mul(t, 131n)))), 1000000007n))

def pick(+t: Nat, x: Nat) -> Nat:
  match t:
    case 0n:
      work(x)
    case 1n+p:
      Nat.add(p, work(Nat.add(x, 1n)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(go(300n, 1n, 0n)))
    IO.print(Nat.show(go(0n, 7n, 5n)))
    IO.print(Nat.show(Nat.add(pick(0n, 3n), pick(4n, 3n))))

#|151825951
#|64831
#|551470
