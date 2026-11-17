# #2162 x #2175 / #2180 / #2188: a statement's call with a literal into a def that
# has a second copy (d~acc, k~fix) or sits in a tail cycle.
import Base

def tri(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      tri(p, Nat.add(acc, n))

# d~acc with two self calls
def fibs(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n:
      1n
    case 2n+p:
      Nat.add(fibs(1n+p), fibs(p))

# d~acc with one self call and a list operand
def lsum(xs: List<Nat>) -> Nat:
  match xs:
    case []:
      0n
    case x <> t:
      Nat.add(x, lsum(t))

# k~fix: not flat (a self call outside the tail), with a fixed call
def walk(+i: Nat, +k: Nat) -> Nat:
  match i:
    case 0n:
      1n
    case 1n+p:
      Nat.mul(Nat.add(1n, Nat.mod(tri(k, 0n), 3n)), walk(p, k))

# d~acc~fix
def both(+i: Nat, +k: Nat) -> Nat:
  match i:
    case 0n:
      0n
    case 1n+p:
      Nat.add(tri(k, 0n), both(p, k))

# a tail cycle that is not flat (a call outside the tail inside)
@unsafe
def pa(+n: Nat, +k: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      pb(p, k, Nat.add(acc, fibs(k)))

@unsafe
def pb(+n: Nat, +k: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      1n+acc
    case 1n+p:
      pa(p, k, Nat.add(acc, 3n))

def show(+one: Nat) -> String:
  +k = Nat.mul(9n, one)
  a = fibs(12n)
  b = fibs(Nat.add(12n, one))
  c = lsum([1n, 2n, 3n, 4n, 5n])
  d = lsum([one, 2n, Nat.mul(3n, one), k])
  e = walk(3n, k)
  f = walk(Nat.mul(3n, one), 4n)
  g = both(4n, k)
  h = both(k, 5n)
  i = pa(3n, k, 0n)
  j = pa(k, 6n, 0n)
  String.join([Nat.show(a), Nat.show(b), Nat.show(c), Nat.show(d), Nat.show(e),
    Nat.show(f), Nat.show(g), Nat.show(h), Nat.show(i), Nat.show(j),
    Nat.show(fibs(3n)), Nat.show(both(0n, k)), Nat.show(walk(1n, 0n))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|144
#|233
#|15
#|15
#|1
#|8
#|180
#|135
#|72
#|53
#|2
#|0
#|1
