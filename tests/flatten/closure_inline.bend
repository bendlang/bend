# bend3's term_leaf closure-inlining pin (partial applications of
# known defs collapsing to direct calls); bend's compiler has no such
# pass, so the SHAPES carry as plain closures: the boundary return,
# the curried 2-stage chain, multi-arm consumption, the escaping
# partial and the bare def reference all evaluate -- countdowns ride
# Nat with a U32 mirror, dispatch guards ride is_eq (word views stay
# out of tocl), contraction rides +Nat/+U32 (Cop) binders, computed
# dispatch guards ride worker defs (applied matches are banned); the count
# is 8, not bend3's 1000: the interp re-forces the acc chain (the
# class cost_stuck_chain_compact pins as the suite's yellow) and goes
# exponential past ~10
import Base

law mk:
  for +i: U32
  U32 -> U32

law mk.pick:
  for +i: U32
  for  z: Bool
  U32 -> U32

def mk.pick(i, z):
  match z:
    case True{}:
      x => (x + i * 3 : U32)
    case False{}:
      x => (x .^. (i << 2n) : U32)

def mk(i):
  mk.pick(i, U32.is_eq((i .&. 1 : U32), 0))

law mk2:
  for +a: U32
  U32 -> U32 -> U32

def mk2(a):
  x => y => (x * a + (y .^. a) : U32)

law use:
  for f: U32 -> U32
  for x: U32
  U32

def use(f, x):
  f(x)

law go2:
  for n   : Nat
  for +i  : U32
  for acc : U32
  U32

def go2(n, i, acc):
  match n:
    case Zero{}:
      acc
    case Succ{k}:
      f = mk2(i)
      g = f(acc)
      go2(k, (i - 1 : U32), g(7))

law arms:
  for b: U32
  for i: U32
  U32

law arms.pick:
  for i: U32
  for z: Bool
  U32

def arms.pick(i, z):
  match z:
    case True{}:
      f = mk(i)
      f(10)
    case False{}:
      f = mk(i)
      f(20)

def arms(b, i):
  arms.pick(i, U32.is_eq((b .&. 1 : U32), 0))

law esc:
  for i: U32
  U32

def esc(i):
  f = mk(i)
  use(f, 5)

law bare:
  for i: U32
  U32

def bare(i):
  f = {mk : @+z:U32 -> U32 -> U32}
  f(i, 9)

law main.out:
  Nat

def main.out():
  U32.to_nat((go2(8n, 8, 3) + (arms(2, 7) + arms(3, 8) + (esc(11) + bare(6))) : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|196899n
