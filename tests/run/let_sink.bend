# a let of U32 operations moves below the next non-tail call when the call
# does not read it and what it reads is read after the call; lets the call
# reads (directly or through another let) stay where they are
import Base

# lets of U32 ops before a non-tail self call, the last two read only after
# it (they sink), the first read by the call (it stays); queens' shape

def walk(+f: Nat, +a: U32, +b: U32, +acc: U32) -> U32:
  match f:
    case 0n:
      U32.add(acc, a)
    case 1n+g:
      +c = U32.xor(a, U32.shl(b))
      +x = U32.and(a, U32.sub(0, a))
      +y = U32.or(b, x)
      walk(g, U32.sub(a, x), U32.add(y, b), walk(g, U32.add(c, 3), U32.shr(b), U32.add(acc, c)))

# a name rebound between the sunk let and the call: the let must read the
# old value, which the code after the call also reads

def f(+n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      +x2 = U32.add(x, 7)
      +b = U32.mul(x, 3)
      U32.add(f(p, x2), U32.xor(b, U32.add(x2, x)))

def g(+n: Nat, +x: U32, +k: U32) -> U32:
  match n:
    case 0n:
      U32.add(x, k)
    case 1n+p:
      +b = U32.mul(x, k)
      +k = U32.add(k, 1)
      U32.xor(g(p, U32.add(x, 1), k), U32.add(b, U32.add(x, k)))

def h(+n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      +y = U32.add(x, 1)
      +b = U32.mul(x, 5)
      +x = U32.add(y, 100)
      U32.add(h(p, y), U32.xor(b, x))

# two non-tail calls in a row: a let read only after the second; a let read
# between them; a let before a parallel let (a fork is not a frame call)

def h3(+n: Nat, +a: U32) -> U32:
  match n:
    case 0n:
      a
    case 1n+p:
      +w = U32.shr(U32.mul(a, 2654435761))
      +u = U32.mul(a, 2654435761)
      +v = U32.add(a, 17)
      +r1 = h3(p, w)
      +r2 = h3(p, U32.add(r1, a))
      U32.add(U32.xor(r2, u), U32.add(v, a))

def k(+n: Nat, +a: U32) -> U32:
  match n:
    case 0n:
      U32.inc(a)
    case 1n+p:
      +u = U32.add(a, 5)
      l r = k(p, a) k(p, U32.inc(a))
      U32.add(U32.add(l, r), U32.add(u, a))

# every U32 operation kind in sunk lets, with division and modulo by zero,
# shifts by a Nat and past 32, a comparison, and a constant

def ops(+n: Nat, +a: U32, +b: U32) -> U32:
  match n:
    case 0n:
      U32.add(a, b)
    case 1n+p:
      +q = U32.div(a, U32.and(b, 3))
      +m = U32.mod(a, U32.and(b, 1))
      +s = U32.shln(a, U32.to_nat(U32.and(b, 63)))
      +t = U32.shrn(b, 33n)
      +c : U32 = 1000
      +z = U32.add(U32.mul(U32.not(a), b), U32.sub(q, m))
      +e = U32.add(U32.mul(a, a), U32.xor(b, 77))
      U32.add(ops(p, U32.add(b, 1), U32.mul(a, 3)), U32.add(U32.add(U32.add(q, m), e), U32.add(U32.add(s, U32.add(t, U32.add(a, b))), U32.add(c, z))))

# deep non-tail recursion (20000 frames) with sunk lets at each level; a
# closure that captures the sunk let's operand; a sunk let feeding a match's
# helper (a def that is also passed as a template)

def deep(+n: Nat, +a: U32) -> U32:
  match n:
    case 0n:
      a
    case 1n+p:
      +x = U32.mul(a, 31)
      +y = U32.add(x, 1)
      U32.xor(deep(p, U32.inc(a)), U32.add(y, a))

def cl(+n: Nat, +a: U32) -> U32:
  match n:
    case 0n:
      a
    case 1n+p:
      +x = U32.mul(a, 7)
      f : U32 -> U32 = z => U32.add(z, a)
      f(U32.add(cl(p, U32.inc(a)), U32.add(x, a)))

def tw(x: U32) -> U32:
  U32.mul(x, 3)

def ap(~t: U32 -> U32, +n: Nat, +a: U32) -> U32:
  match n:
    case 0n:
      t(a)
    case 1n+p:
      +x = U32.add(a, 9)
      U32.add(t(ap(~t, p, U32.inc(a))), U32.add(x, a))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(walk(16n, 2654435761, 40503, 7)))
    Unit <- IO.print(U32.show(f(18n, 12345)))
    Unit <- IO.print(U32.show(g(18n, 99, 5)))
    Unit <- IO.print(U32.show(h(18n, 4242)))
    Unit <- IO.print(U32.show(h3(12n, 7)))
    Unit <- IO.print(U32.show(k(12n, 3)))
    Unit <- IO.print(U32.show(ops(20n, 77, 1234567)))
    Unit <- IO.print(U32.show(deep(20000n, 1)))
    Unit <- IO.print(U32.show(cl(1000n, 2)))
    Unit <- IO.print(U32.show(ap(~tw, 30n, 5)))
    IO.print(U32.show(tw(ap(~tw, 3n, 1))))

#|2682133566
#|1123128
#|3831
#|309320
#|1385982557
#|126967
#|873158583
#|625185
#|4514502
#|1578725199
#|1527
