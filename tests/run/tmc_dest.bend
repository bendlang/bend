# A constructor that boxes a call's result is built before the call, which
# fills that field (C lane: tail recursion modulo cons, no frame a level):
# a list map that reuses each cell, a list built in a chain of two defs
# (the second def's hole is the first's field), a tree insert through a
# helper whose node packs its words (the hole's slot past the packed word),
# the hole in a middle field with words read on both sides, a list lent to
# another field's call and dropped before the hole's call, one the arm
# never reads, a call that
# answers at once, and a map 20,000 deep. Every size comes from the command
# line's length (1 in the harness), which no compiler sees.
import Base

type L is Data:
  N{}
  C{h: U32, t: L}

type Color is Data:
  Red{}
  Blk{}

type T is Data:
  E{}
  Nd{c: Color, l: T, k: U32, v: U32, r: T}

type M is Data:
  MN{}
  MC{a: U32, t: M, b: U32}

def mk(n: Nat, +i: U32) -> L:
  match n:
    case 0n:
      N{}
    case 1n+p:
      C{i, mk(p, (i + 1 : U32))}

def inc(l: L) -> L:
  match l:
    case N{}:
      N{}
    case C{h, t}:
      C{(h * 3 + 1 : U32), inc(t)}

def sum(l: L, +a: U32) -> U32:
  match l:
    case N{}:
      a
    case C{h, t}:
      sum(t, (a * 31 + h : U32))

# two defs, each boxing the other's result
@unsafe
def odd(l: L) -> L:
  match l:
    case N{}:
      N{}
    case C{h, t}:
      C{(h + 1000 : U32), even(t)}

@unsafe
def even(l: L) -> L:
  match l:
    case N{}:
      N{}
    case C{h, t}:
      C{(h * 2 : U32), odd(t)}

@unsafe
def ins(t: T, +k: U32) -> T:
  match t:
    case E{}:
      Nd{Red{}, E{}, k, (k * 3 : U32), E{}}
    case Nd{c, l, +k2, +v, r}:
      ins.at(U32.is_lt(k, k2), c, l, k2, v, r, k)

@unsafe
def ins.at(lt: Bool, c: Color, l: T, +k2: U32, +v: U32, r: T, +k: U32) -> T:
  match lt:
    case True{}:
      Nd{c, ins(l, k), k2, v, r}
    case False{}:
      Nd{c, l, k2, (v + k : U32), ins(r, k)}

def tsum(t: T, +a: U32) -> U32:
  match t:
    case E{}:
      a
    case Nd{c, l, k, v, r}:
      tsum(r, tsum(l, (a * 7 + k + v : U32)))

def fill(n: Nat, +x: U32, t: T) -> T:
  match n:
    case 0n:
      t
    case 1n+p:
      fill(p, (x * 1103515245 + 12345 : U32), ins(t, (x % 1000 : U32)))

def mid(n: Nat, +i: U32) -> M:
  match n:
    case 0n:
      MN{}
    case 1n+p:
      MC{i, mid(p, (i + 2 : U32)), (i * i : U32)}

def msum(m: M, +a: U32) -> U32:
  match m:
    case MN{}:
      a
    case MC{x, t, y}:
      msum(t, (a * 5 + x + y : U32))

def tagd(l: L, j: L) -> L:
  match l:
    case N{}:
      j
    case C{h, t}:
      C{(h + sum(j, 3) : U32), tagd(t, N{})}

def tj(l: L, junk: L) -> L:
  match l:
    case N{}:
      junk
    case C{h, t}:
      C{h, tj(t, N{})}

def one(n: Nat) -> L:
  match n:
    case 0n:
      N{}
    case 1n+p:
      C{7, N{}}

def wrap(n: Nat) -> L:
  C{1, one(n)}

def run(+k: Nat) -> String:
  U32.show(sum(inc(inc(mk(Nat.mul(k, 1000n), 0))), 0)) ++ " "
    ++ U32.show(sum(odd(mk(Nat.mul(k, 999n), 5)), 0)) ++ " "
    ++ U32.show(tsum(fill(Nat.mul(k, 3000n), 1, E{}), 0)) ++ " "
    ++ U32.show(msum(mid(Nat.mul(k, 500n), 3), 0)) ++ " "
    ++ U32.show(sum(wrap(k), 0)) ++ " "
    ++ U32.show(sum(tj(mk(Nat.mul(k, 30n), 1), mk(Nat.mul(k, 20n), 4)), 0)) ++ " "
    ++ U32.show(sum(tagd(mk(Nat.mul(k, 50n), 2), mk(Nat.mul(k, 40n), 9)), 0)) ++ " "
    ++ U32.show(sum(inc(mk(Nat.mul(k, 20000n), 1)), 0))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(run(List.length(&1, String, args)))
#| 3861267348 9949488 2008994644 3112759308 38 2775178735 3229133477 2461048112
