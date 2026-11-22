# erased fields in a record and in a three-armed sum, around boxed fields: re-formed, swapped, looked into, lent, dropped
import Base

type T is Data:
  TL{}
  TN{l: T, k: U32, r: T}

type R is Data:
  R{-n: Nat, a: T, -m: Nat, k: U32, b: T, kids: List<&2, R>}

type S is Data:
  S0{}
  S1{-n: Nat, t: T}
  S2{x: T, -n: Nat, y: S, -m: Nat}

def dig(t: T, +acc: U32) -> U32:
  match t:
    case TL{}:
      U32.add(U32.mul(acc, 29), 5)
    case TN{l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, acc), 137), k))

def gen(+d: Nat, +i: U32) -> T:
  match d:
    case 0n:
      TL{}
    case 1n+e:
      TN{gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

@unsafe def rsum(xs: List<&2, R>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case r <> rest:
      rsum(rest, U32.add(U32.mul(acc, 3), rdig(r)))

@unsafe def rdig(r: R) -> U32:
  match r:
    case R{n, a, m, k, b, ks}:
      rsum(ks, dig(b, dig(a, k)))

def sdig(s: S, +acc: U32) -> U32:
  match s:
    case S0{}:
      U32.add(acc, 3)
    case S1{n, t}:
      dig(t, acc)
    case S2{x, n, y, m}:
      sdig(y, dig(x, U32.mul(acc, 7)))

def rsame(r: R) -> R:
  match r:
    case R{n, a, m, k, b, ks}:
      R{n, a, m, k, b, ks}

def rswap(r: R) -> R:
  match r:
    case R{n, a, m, k, b, ks}:
      R{m, b, n, k, a, ks}

def rkey(r: R) -> R & U32:
  match r:
    case R{n, a, m, +k, b, ks}:
      (R{n, a, m, k, b, ks}, k)

# a record whose first box is looked into and re-formed
def rlook(r: R) -> R:
  match r:
    case R{n, TN{l, +k2, x}, m, k, b, ks}:
      R{n, TN{l, k2, x}, m, U32.add(k, k2), b, ks}
    case r0:
      r0

def ssame(s: S) -> S:
  match s:
    case S0{}:
      S0{}
    case S1{n, t}:
      S1{n, t}
    case S2{x, n, y, m}:
      S2{x, n, ssame(y), m}

# a nested S2 re-formed under its parent, with the erased fields swapped
def snest(s: S) -> S:
  match s:
    case S2{x, n, S2{x2, n2, y2, m2}, m}:
      S2{x, m, S2{x2, n2, y2, m2}, n}
    case s0:
      s0

def skey(s: S) -> S & U32:
  match s:
    case S1{n, t}:
      (S1{n, t}, 1)
    case s0:
      (s0, 2)

def rkdig(p: R & U32) -> U32:
  (r, k) = p
  U32.add(rdig(r), k)

def skdig(p: S & U32) -> U32:
  (s, k) = p
  sdig(s, k)

def mks(+n: Nat, +t: T, acc: S) -> S:
  match n:
    case 0n:
      S1{3n, t}
    case 1n+p:
      mks(p, t, S2{t, n, acc, 0n})

# lent: a flat def that keeps the record in one arm
def keep(-q: Nat, z: Bool, r: R, acc: List<&2, R>) -> List<&2, R>:
  match z:
    case True{}:
      r <> acc
    case False{}:
      acc

def all(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  +r : R = R{1n, t, 2n, i, gen(d, U32.inc(i)), [R{5n, gen(1n, i), 6n, 2, TL{}, []}]}
  +s = mks(d, t, S0{})
  a = rdig(rsame(r))
  b = rdig(rswap(r))
  c = rkdig(rkey(r))
  e = rdig(rlook(r))
  f = rdig(rlook(R{0n, gen(d, 5), 0n, 9, TL{}, []}))
  g = sdig(ssame(s), 1)
  h = sdig(snest(s), 2)
  j = skdig(skey(s))
  k = skdig(skey(S1{4n, gen(d, 6)}))
  o1 = rdig(rsame(R{3n, gen(d, 7), 4n, 8, gen(d, 9), []}))
  o2 = rkdig(rkey(R{3n, gen(d, 10), 4n, 8, gen(d, 11), []}))
  o3 = sdig(snest(mks(d, gen(d, 12), S0{})), 3)
  o4 = skdig(skey(S2{gen(d, 13), 1n, S1{2n, gen(d, 14)}, 3n}))
  l = rsum(keep(0n, True{}, r, keep(1n, False{}, r, keep(2n, True{}, r, []))), 0)
  z = U32.add(rdig(r), U32.add(sdig(s, 0), dig(t, 0)))
  U32.add(o1, U32.add(o2, U32.add(o3, U32.add(o4, U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, U32.add(g, U32.add(h, U32.add(j, U32.add(k, U32.add(l, z))))))))))))))

def par(+n: Nat, +d: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      x y = all(d, U32.from_nat(n)) par(p, d)
      U32.add(x, y)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(all(0n, 1)))
    Unit <- IO.print(U32.show(all(4n, 2)))
    Unit <- IO.print(U32.show(sdig(mks(100000n, gen(2n, 1), S0{}), 0)))
    IO.print(U32.show(par(80n, 4n)))

#|65397390
#|189454050
#|1025602078
#|912784216
