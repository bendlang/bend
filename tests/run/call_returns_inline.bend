# a call whose callee answers at once (#2177's arms) runs its continuation
# in place, so the frame is pushed only when the callee does not answer:
# continuations that read several frame words, an owned list kept across
# the call, a pair result, a call into another tree def, a comb 30000 deep
# a search shaped like queens' solve, and the calls under parallel lets
# (their task path must see the continuation's task first)
import Base

type T is Data:
  Leaf{+v: U32}
  Node{l: T, r: T}

def mk(+d: Nat, +s: U32) -> T:
  match d:
    case 0n:
      Leaf{s}
    case 1n+p:
      Node{mk(p, U32.mul(s, 3)), mk(p, U32.add(s, 7))}

def sum(t: T, +k: U32, +m: U32) -> U32:
  match t:
    case Leaf{v}:
      U32.xor(v, k)
    case Node{l, r}:
      +a = U32.add(k, m)
      U32.add(U32.mul(sum(l, a, m), 3), U32.add(sum(r, U32.inc(k), a), U32.xor(a, m)))

def keep(t: T, xs: List<U32>) -> List<U32>:
  match t:
    case Leaf{v}:
      v <> xs
    case Node{l, r}:
      keep(r, keep(l, xs))

def len(xs: List<U32>, +n: U32) -> U32:
  match xs:
    case Nil{}:
      n
    case h <> t:
      len(t, U32.add(n, h))

def two.join(a: U32 & U32, b: U32 & U32, +k: U32) -> U32 & U32:
  (a1, a2) = a
  (b1, b2) = b
  (U32.add(a1, b2), U32.xor(a2, U32.add(b1, k)))

def two(t: T, +k: U32) -> U32 & U32:
  match t:
    case Leaf{v}:
      (v, U32.add(v, k))
    case Node{l, r}:
      two.join(two(l, U32.inc(k)), two(r, U32.add(k, 2)), k)

def two.fst(p: U32 & U32) -> U32:
  (a, b) = p
  U32.add(a, U32.mul(b, 5))

def via(t: T, +k: U32) -> U32:
  match t:
    case Leaf{v}:
      U32.add(v, k)
    case Node{l, r}:
      U32.add(sum(l, k, 1), via(r, U32.inc(k)))

def comb(+d: Nat, +s: U32) -> T:
  match d:
    case 0n:
      Leaf{s}
    case 1n+p:
      Node{Leaf{U32.add(s, 1)}, comb(p, U32.mul(s, 5))}

def dep(t: T, +k: U32) -> U32:
  match t:
    case Leaf{v}:
      U32.add(v, k)
    case Node{l, r}:
      U32.xor(dep(r, U32.inc(k)), U32.add(dep(l, k), k))

def srch(+f: Nat, z: Bool, +c: U32, +full: U32, +acc: U32) -> U32:
  match f z:
    case 0n _:
      acc
    case 1n+g True{}:
      acc
    case 1n+g False{}:
      +b = U32.and(c, U32.sub(0, c))
      +rest = U32.sub(c, b)
      +cc = U32.and(full, U32.shr(U32.or(rest, U32.shl(b))))
      srch(g, U32.is_zero(rest), rest, full, srch(g, U32.is_zero(cc), cc, full, U32.add(acc, b)))

def pv(+d: Nat, +s: U32) -> U32:
  match d:
    case 0n:
      via(mk(8n, s), s)
    case 1n+p:
      a b = pv(p, U32.mul(s, 3)) pv(p, U32.add(s, 1))
      U32.xor(a, U32.add(b, s))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(sum(mk(14n, 1), 5, 9)))
    Unit <- IO.print(U32.show(len(keep(mk(12n, 2), []), 0)))
    Unit <- IO.print(U32.show(two.fst(two(mk(13n, 3), 1))))
    Unit <- IO.print(U32.show(via(mk(11n, 4), 2)))
    Unit <- IO.print(U32.show(dep(comb(30000n, 1), 3)))
    Unit <- IO.print(U32.show(srch(40n, False{}, 4095, 4095, 0)))
    IO.print(U32.show(pv(6n, 7)))

#|3356384698
#|92260352
#|206983734
#|460174074
#|4061494932
#|5225836
#|772016070
