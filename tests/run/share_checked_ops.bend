# share: an arm that computes a checked Nat operation or a division twice,
# where clang could not merge the copies, computes it once (isqrt's Newton
# iterate). Two divisions with nothing checked between them stay as they
# are (digits), a copy that names one of the arm's own lets stays in place
# (lets), a big Nat stays a Nat when it is bound (big), and a shared product
# past the Nat limit stops the program on every lane (over); copies inside a
# closure stay there (clo).
import Base

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

def digits(+n: Nat) -> Nat:
  Nat.add(Nat.mod(Nat.div(n, 10n), 10n), Nat.mul(Nat.div(n, 10n), 3n))

def lets(+x: Nat) -> Nat:
  +a = Nat.add(x, 1n)
  +b = Nat.add(a, Nat.div(a, 3n))
  Nat.add(Nat.mul(Nat.add(a, b), 2n), Nat.mul(Nat.add(a, b), 5n))

def big(+x: Nat, +y: Nat) -> Nat:
  Nat.add(Nat.mul(x, 2n),
    Nat.add(Nat.mul(Nat.add(x, y), 3n), Nat.div(Nat.mul(Nat.add(x, y), 3n), 7n)))

def mix(+a: U32, +b: U32, +n: Nat) -> U32:
  U32.add(U32.div(U32.add(a, U32.div(a, b)), 3), U32.mod(U32.add(a, U32.div(a, b)), 7))

# a checked add runs between the two U32 divisions
def mixn(+a: U32, +b: U32, +n: Nat) -> Nat:
  Nat.add(Nat.add(n, U32.to_nat(U32.div(a, b))), U32.to_nat(U32.mod(U32.div(a, b), 7)))

def over(+a: Nat) -> Nat:
  Nat.add(Nat.mul(a, Nat.add(a, 1n)), Nat.div(Nat.mul(a, Nat.add(a, 1n)), 2n))

# the copies inside the closure name its own parameter: they stay inside
def app(f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def clo(+k: Nat) -> Nat:
  app(+x => Nat.add(Nat.mul(Nat.add(x, k), 3n), Nat.mul(Nat.add(x, k), 3n)), 5n)

# every argument is read at run time (one is 1 with no arguments), so no call
# is evaluated by the compiler
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +one : Nat = List.length(&1, String, args)
    +u : U32 = U32.from_nat(one)
    IO.print(Nat.show(sum(Nat.mul(5000n, one), 0n)))
    IO.print(Nat.show(digits(Nat.mul(98765n, one))))
    IO.print(Nat.show(lets(Nat.mul(40n, one))))
    IO.print(Nat.show(big(Nat.mul(Nat.mul(4000000000n, 5n), one), Nat.mul(7n, one))))
    IO.print(U32.show(U32.add(mix(U32.mul(100, u), U32.mul(7, u), one), mix(U32.mul(9, u), U32.sub(u, 1), one))))
    IO.print(Nat.show(mixn(U32.mul(4000000000, u), U32.mul(3, u), Nat.mul(5n, one))))
    IO.print(Nat.show(clo(Nat.mul(4n, one))))
    IO.print(Nat.show(over(Nat.mul(1000n, one))))
    IO.print(Nat.show(over(Nat.mul(16777216n, one))))

#|233275
#|29634
#|665
#|108571428595
#|45
#|1333333341
#|54
#|1501500
#|bend: a Nat past the largest immediate 2^48-1
