# A tail-call cycle that runs as one loop, called from every kind of place:
# a fork's branches, a ! call, a def passed as a function, a partial
# application, a closure, a def of the cycle that answers a closure, a
# literal call the emitter runs itself. And the cycles that must stay as they
# were: one with a call to itself in an argument, one with a fork, one whose
# helper calls a def that is not flat, one a def outside calls back into.
# The last two recurse 20,000 frames deep in sixteen forked leaves: merged,
# they would ride the C stack of a pool thread.
import Base

@unsafe
def ev.if(odd: Bool, +n: U32, steps: U32) -> U32:
  match odd:
    case True{}:
      ev(U32.add(U32.mul(n, 3), 1), U32.add(steps, 1))
    case False{}:
      ev(U32.shr(n), U32.add(steps, 1))

@unsafe
def ev.end(small: Bool, +n: U32, steps: U32) -> U32:
  match small:
    case True{}:
      steps
    case False{}:
      ev.if(U32.is_eq(U32.and(n, 1), 1), n, steps)

@unsafe
def ev(+n: U32, steps: U32) -> U32:
  ev.end(U32.is_le(n, 1), n, steps)

# a fork over the cycle, each branch a task
def tree(+d: Nat, +x: U32) -> U32:
  match d:
    case 0n:
      ev(U32.add(x, 27), 0)
    case 1n+p:
      a b = tree(p, U32.mul(x, 2)) tree(p, U32.add(U32.mul(x, 2), 1))
      U32.add(a, b)

# the fork's branches are the cycle's defs themselves
def both(+x: U32) -> U32:
  a b = ev(x, 0) ev.if(True{}, x, 5)
  U32.add(a, b)

# a def as a function value, and a partial application of each def
def apply(f: @+n:U32 -> U32 -> U32, x: U32) -> U32:
  f(x, 0)

def twice(f: U32 -> U32, g: U32 -> U32, +x: U32) -> U32:
  U32.add(f(x), g(x))

# a closure that captures a value and runs the cycle
def later(+k: U32) -> U32 -> U32:
  x => ev(U32.add(x, k), k)

# a def of the cycle that answers a closure calling the other
@unsafe
def cl.b(n: Nat, +k: U32) -> U32 -> U32:
  match n:
    case 0n:
      x => U32.add(x, k)
    case 1n+p:
      cl.a(p, U32.add(k, 1))

@unsafe
def cl.a(n: Nat, +k: U32) -> U32 -> U32:
  match n:
    case 0n:
      x => U32.mul(x, k)
    case 1n+p:
      cl.b(p, U32.add(k, 10))

# b calls a in an argument too: not a tail cycle to merge
@unsafe
def nt.a(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      nt.b(p, 1n+acc)

@unsafe
def nt.b(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      Nat.add(acc, 7n)
    case 1n:
      nt.a(0n, Nat.add(acc, nt.a(3n, 0n)))
    case 2n+p:
      nt.a(p, Nat.add(acc, nt.a(Nat.mod(p, 5n), 0n)))

# a fork in one def of the cycle
@unsafe
def fk.a(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      x y = fk.leaf(n) fk.leaf(p)
      fk.b(p, U32.add(acc, U32.add(x, y)))

@unsafe
def fk.b(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, 1)
    case 1n+p:
      fk.a(p, U32.mul(acc, 3))

def fk.leaf(+n: Nat) -> U32:
  U32.from_nat(Nat.mul(n, n))

# a cycle the emitter may run at compile time
@unsafe
def even(n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      odd(p)

@unsafe
def odd(n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      even(p)

def tab(x: U32) -> U32:
  match x:
    case 0:
      even(4n)
    case 1:
      even(7n)
    case 2:
      odd(7n)
    case 3:
      odd(2n)
    case _:
      even(1n)

# the outer cycle's helper runs the inner cycle to its end each turn
@unsafe
def out.if(odd: U32, n: Nat, acc: U32) -> U32:
  match odd:
    case 0:
      out(n, U32.add(acc, 1))
    case _:
      out(n, U32.mul(acc, 2))

@unsafe
def out(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      out.if(even(n), p, acc)

# a reusable parameter read after it is passed on, and a bound call first
@unsafe
def kp.if(hit: Bool, +s: String, n: Nat, acc: Nat) -> Nat:
  match hit:
    case True{}:
      kp(n, s, Nat.add(acc, kp.len(s, 0n)))
    case False{}:
      kp(n, s, acc)

@unsafe
def kp(+n: Nat, +s: String, acc: Nat) -> Nat:
  match n:
    case 0n:
      Nat.add(acc, kp.len(s, 0n))
    case 1n+p:
      l = kp.len(s, n)
      kp.if(Nat.is_gt(l, 6n), s, p, acc)

def kp.len(s: String, n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{h, t}:
      kp.len(t, 1n+n)

# the helper calls a def that is not flat (it recurses in an argument)
@unsafe
def hv.if(big: Bool, +xs: List<&2, U32>, n: Nat, acc: U32) -> U32:
  match big:
    case True{}:
      hv(n, xs, U32.add(acc, hv.sum(xs)))
    case False{}:
      hv(n, xs, U32.add(acc, 1))

@unsafe
def hv(+n: Nat, +xs: List<&2, U32>, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      hv.if(Nat.is_gt(n, 3n), xs, p, acc)

def hv.sum(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(h, hv.sum(t))

# a def outside the cycle calls back into it from an argument
@unsafe
def oc.a(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      oc.b(p, Nat.add(acc, oc.x(p)))

@unsafe
def oc.b(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      1n+acc
    case 1n+p:
      oc.a(p, 1n+acc)

@unsafe
def oc.x(n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      oc.a(Nat.mod(p, 4n), 0n)

# b calls a in an argument: every other turn holds a frame
@unsafe
def dp.a(n: Nat) -> U32:
  match n:
    case 0n:
      5
    case 1n+p:
      dp.b(p)

@unsafe
def dp.b(n: Nat) -> U32:
  match n:
    case 0n:
      9
    case 1n:
      dp.a(0n)
    case 2n+p:
      U32.xor(1, dp.a(p))

# x, outside the cycle, calls back into it from an argument
@unsafe
def oq.a(n: Nat) -> U32:
  match n:
    case 0n:
      3
    case 1n+p:
      oq.b(p)

@unsafe
def oq.b(n: Nat) -> U32:
  match n:
    case 0n:
      4
    case 1n:
      oq.a(0n)
    case 2n+p:
      oq.x(p)

@unsafe
def oq.x(n: Nat) -> U32:
  U32.xor(2, oq.a(n))

def deep(+n: Nat) -> U32:
  a b = dp.a(n) oq.a(1n+n)
  c d = dp.b(1n+n) oq.b(n)
  U32.add(U32.add(a, U32.mul(b, 10)), U32.add(U32.mul(c, 100), U32.mul(d, 1000)))

# sixteen leaves, so that some run on the pool's threads
def deep.tree(+d: Nat, +n: Nat) -> U32:
  match d:
    case 0n:
      deep(n)
    case 1n+p:
      a b = deep.tree(p, n) deep.tree(p, 1n+n)
      U32.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    +z : Nat = Nat.mod(t, 1n)
    +u : U32 = U32.from_nat(z)
    IO.print(U32.show(ev(U32.add(27, u), 0)))
    IO.print(U32.show(tree(Nat.add(6n, z), 1)))
    IO.print(U32.show(tree!(Nat.add(6n, z), 1)))
    IO.print(U32.show(ev!(U32.add(97, u), 0)))
    IO.print(U32.show(ev.if!(True{}, U32.add(97, u), 0)))
    IO.print(U32.show(both(U32.add(871, u))))
    IO.print(U32.show(apply(ev, U32.add(703, u))))
    IO.print(U32.show(apply(ev.if(False{}), U32.add(703, u))))
    IO.print(U32.show(twice(ev(U32.add(9, u)), ev.if(True{}, U32.add(9, u)), 100)))
    IO.print(U32.show(later(U32.add(3, u))(24)))
    IO.print(U32.show(cl.a(Nat.add(5n, z), 1)(7)))
    IO.print(U32.show(cl.b(Nat.add(5n, z), 1)(7)))
    IO.print(U32.show(cl.a(Nat.add(3000001n, z), 1)(7)))
    IO.print(Nat.show(nt.a(Nat.add(1001n, z), 0n)))
    IO.print(Nat.show(nt.b(Nat.add(1000n, z), 0n)))
    IO.print(U32.show(fk.a(Nat.add(11n, z), 0)))
    IO.print(U32.show(fk.b(Nat.add(12n, z), 0)))
    IO.print(U32.show(U32.add(even(10n), U32.mul(odd(9n), 10))))
    IO.print(U32.show(even(Nat.add(3000001n, z))))
    IO.print(U32.show(U32.add(tab(u), U32.mul(tab(U32.add(u, 1)), 2))))
    IO.print(U32.show(U32.add(tab(U32.add(u, 2)), U32.mul(tab(U32.add(u, 3)), 2))))
    IO.print(U32.show(tab(U32.add(u, 9))))
    IO.print(U32.show(out(Nat.add(20n, z), 1)))
    IO.print(Nat.show(kp(Nat.add(9n, z), String.append("abcd", Nat.show(z)), 0n)))
    IO.print(U32.show(hv(Nat.add(9n, z), [1, 2, 3], 0)))
    IO.print(Nat.show(oc.a(Nat.add(2001n, z), 0n)))
    IO.print(Nat.show(oc.b(Nat.add(40n, z), 0n)))
    IO.print(U32.show(deep.tree(4n, Nat.add(40000n, z))))

#|111
#|3238
#|3238
#|118
#|118
#|361
#|170
#|82
#|238
#|114
#|40
#|168
#|16500018
#|2186
#|2185
#|68153
#|68153
#|11
#|0
#|1
#|1
#|0
#|2047
#|45
#|39
#|4502
#|87
#|60095
