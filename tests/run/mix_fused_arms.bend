# #2153 x #2177 (and #2176): continuations with equal code that push calls into a
# tree recursion (the callee's returning arms are copied to each call), under one
# thread and many.
import Base

# two arms with the same code after the first call; the continuation makes
# the second call as a tail call (queens' shape)
def qs(+n: Nat, sel: Bool, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, 1)
    case 1n+p:
      match sel:
        case True{}:
          x = qs(p, False{}, U32.mul(acc, 3))
          qs(p, True{}, U32.xor(x, 5))
        case False{}:
          x = qs(p, False{}, U32.mul(acc, 3))
          qs(p, True{}, U32.xor(x, 5))

# the same with the second call outside the tail: each continuation pushes
# a frame of its own for a call with copied arms
def qt(+n: Nat, sel: Bool, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, 1)
    case 1n+p:
      match sel:
        case True{}:
          +x = qt(p, False{}, U32.mul(acc, 3))
          y = qt(p, True{}, U32.xor(x, 5))
          U32.add(U32.mul(y, 7), x)
        case False{}:
          +x = qt(p, False{}, U32.mul(acc, 3))
          y = qt(p, True{}, U32.xor(x, 5))
          U32.add(U32.mul(y, 7), x)

# a tree over a datatype, called from two defs with the same continuation
type T is Data:
  L{v: U32}
  N{l: T, r: T}

def mk(+d: Nat, +s: U32) -> T:
  match d:
    case 0n:
      L{s}
    case 1n+p:
      N{mk(p, U32.add(U32.mul(s, 2), 1)), mk(p, U32.mul(s, 3))}

def ev(t: T) -> U32:
  match t:
    case L{v}:
      v
    case N{l, r}:
      a = ev(l)
      b = ev(r)
      U32.xor(U32.mul(a, 31), b)

def use1(t: T, u: T, +k: U32) -> U32:
  a = ev(t)
  b = ev(u)
  U32.add(U32.mul(a, k), b)

def use2(t: T, u: T, +k: U32) -> U32:
  a = ev(t)
  b = ev(u)
  U32.add(U32.mul(a, k), b)

# forks around the same recursion: the join is no continuation
def par(+d: Nat, +s: U32) -> U32:
  match d:
    case 0n:
      ev(mk(6n, s))
    case 1n+p:
      a b = par(p, U32.add(s, 1)) par(p, U32.mul(s, 5))
      U32.add(a, U32.mul(b, 3))

def show(+one: Nat) -> String:
  +d = Nat.mul(12n, one)
  String.join([
    U32.show(qs(d, True{}, 1)),
    U32.show(qs(d, False{}, 2)),
    U32.show(qt(d, True{}, 1)),
    U32.show(qt(d, False{}, 2)),
    U32.show(use1(mk(d, 1), mk(d, 2), 3)),
    U32.show(use2(mk(d, 3), mk(Nat.add(d, one), 4), 5)),
    U32.show(par(Nat.mul(8n, one), 7)),
    U32.show(ev(L{9}))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|247114414
#|4189377875
#|3364289104
#|1461252826
#|1763859503
#|694813703
#|1024947360
#|9
