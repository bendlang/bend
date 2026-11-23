# A def whose tail op takes its own calls carries the result in a parameter
# (C lane), for each associative and commutative op: U32 mul, xor, and, or,
# add spelled as U32.inc, Bool or and xor. A def that mixes ops (xor of an
# inc of a call) keeps its frames, and so does Nat.mul. Every size comes
# from the command line's length (1 in the harness), which no compiler sees.
import Base

type T is Data:
  Lf{v: U32}
  Br{l: T, r: T}

def mk(+n: Nat, +s: U32) -> T:
  match n:
    case 0n:
      Lf{s}
    case 1n+p:
      Br{mk(p, (s * 7 + 1 : U32)), mk(p, (s * 5 + 3 : U32))}

def prod(t: T) -> U32:
  match t:
    case Lf{v}:
      U32.or(v, 1)
    case Br{l, r}:
      U32.mul(prod(l), prod(r))

def xall(t: T) -> U32:
  match t:
    case Lf{v}:
      v
    case Br{l, r}:
      U32.xor(xall(l), U32.xor(xall(r), 77))

def aall(t: T) -> U32:
  match t:
    case Lf{v}:
      U32.or(v, 4026531840)
    case Br{l, r}:
      U32.and(aall(l), aall(r))

def oall(t: T) -> U32:
  match t:
    case Lf{v}:
      U32.and(v, 255)
    case Br{l, r}:
      U32.or(oall(l), oall(r))

def size(t: T) -> U32:
  match t:
    case Lf{v}:
      0
    case Br{l, r}:
      U32.inc(U32.add(size(l), size(r)))

def any7(t: T) -> Bool:
  match t:
    case Lf{v}:
      U32.is_eq((v % 7 : U32), 0)
    case Br{l, r}:
      Bool.or(any7(l), any7(r))

def par(t: T) -> Bool:
  match t:
    case Lf{v}:
      U32.is_eq((v % 3 : U32), 1)
    case Br{l, r}:
      Bool.xor(par(l), par(r))

def mixed(t: T) -> U32:
  match t:
    case Lf{v}:
      v
    case Br{l, r}:
      U32.xor(mixed(l), U32.inc(mixed(r)))

def pw(+x: U32, n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      U32.mul(x, pw(x, p))

def fact(+n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.mul(n, fact(p))

def b(t: Bool) -> String:
  U32.show(Bool.to_u32(t))

def run(+k: Nat) -> String:
  U32.show(prod(mk(Nat.mul(k, 12n), 1))) ++ " " ++ U32.show(xall(mk(Nat.mul(k, 11n), 2)))
    ++ " " ++ U32.show(aall(mk(Nat.mul(k, 10n), 3))) ++ " " ++ U32.show(oall(mk(Nat.mul(k, 9n), 4)))
    ++ " " ++ U32.show(size(mk(Nat.mul(k, 13n), 5))) ++ " " ++ b(any7(mk(Nat.mul(k, 8n), 6)))
    ++ " " ++ b(par(mk(Nat.mul(k, 9n), 7))) ++ " " ++ U32.show(mixed(mk(Nat.mul(k, 10n), 8)))
    ++ " " ++ U32.show(pw(U32.from_nat(Nat.add(k, 2n)), Nat.mul(k, 21n)))
    ++ " " ++ Nat.show(fact(Nat.mul(k, 12n)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(run(List.length(&1, String, args)))
#| 2734903297 3330660237 4026531841 255 8191 1 0 3420002431 1870418611 479001600
