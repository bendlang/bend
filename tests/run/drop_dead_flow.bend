# drop, per flow: values nobody reads are erased, and a flow left with one
# constructor of one field carries the field. build1's list is read by first
# alone: its tails, and every keep1, are dead, and it is its head.
# Each other list is read some other way, so it stays a list: its tail is
# counted (tail_len), read in a closure (via_clo), passed through generic
# code (via_gen), through a `!` call (via_bang), or matched with a catch-all
# arm (any_head); build2's lists are read by first2 and counted, so they stay.
# Arguments are read at run time, so no call is evaluated by the compiler.
import Base

type L is Data:
  LNil{}
  LCon{h: U32, t: L}

def keep(z: Bool, +x: U32, acc: L) -> L:
  match z:
    case True{}:
      LCon{x, acc}
    case False{}:
      acc

def build(+n: Nat, +x: U32, acc: L) -> L:
  match n:
    case 0n:
      LCon{x, acc}
    case 1n+p:
      build(p, U32.add(x, 3), keep(U32.is_zero(U32.mod(x, 2)), x, acc))

# the flow that changes: its own builder, its own keep, read by first alone
def keep1(z: Bool, +x: U32, acc: L) -> L:
  match z:
    case True{}:
      LCon{x, acc}
    case False{}:
      acc

def build1(+n: Nat, +x: U32, acc: L) -> L:
  match n:
    case 0n:
      LCon{x, acc}
    case 1n+p:
      build1(p, U32.add(x, 3), keep1(U32.is_zero(U32.mod(x, 2)), x, acc))

def first(l: L) -> U32:
  match l:
    case LNil{}:
      0
    case LCon{h, t}:
      h

def len(l: L, acc: U32) -> U32:
  match l:
    case LNil{}:
      acc
    case LCon{h, t}:
      len(t, U32.inc(acc))

def tail_len(l: L) -> U32:
  match l:
    case LNil{}:
      0
    case LCon{h, t}:
      U32.add(h, len(t, 0))

def app(f: L -> U32, l: L) -> U32:
  f(l)

def via_clo(l: L) -> U32:
  app(m => len(m, 0), l)

def via_gen(l: L) -> U32:
  len(Maybe.default(&2, L, Some{l}, LNil{}), 0)

def via_bang(l: L) -> U32:
  len!(l, 0)

def any_head(l: L) -> U32:
  match l:
    case LCon{h, t}:
      U32.add(h, len(t, 0))
    case _:
      7

# two flows of L: one only its head read, one counted
def build2(+n: Nat, +x: U32, acc: L) -> L:
  match n:
    case 0n:
      LCon{x, acc}
    case 1n+p:
      build2(p, U32.inc(x), LCon{x, acc})

def first2(l: L) -> U32:
  match l:
    case LNil{}:
      1
    case LCon{h, t}:
      h

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +one : Nat = List.length(&1, String, args)
    +u : U32 = U32.from_nat(one)
    +n : Nat = Nat.mul(50n, one)
    IO.print(U32.show(first(build1(n, u, LNil{}))))
    IO.print(U32.show(tail_len(build(n, u, LNil{}))))
    IO.print(U32.show(via_clo(build(n, u, LNil{}))))
    IO.print(U32.show(via_gen(build(n, u, LNil{}))))
    IO.print(U32.show(via_bang(build(n, u, LNil{}))))
    IO.print(U32.show(any_head(build(n, u, LNil{}))))
    IO.print(U32.show(U32.add(first2(build2(n, u, LNil{})), len(build2(n, u, LNil{}), 0))))

#|151
#|176
#|26
#|26
#|26
#|176
#|102
