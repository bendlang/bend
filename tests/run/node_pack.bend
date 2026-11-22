# A heap node's U32 and tag fields share one word when that drops its size
# class: T's Nd (c, k, b beside two boxes) goes from 8 words to 4, Q's Qn
# (two U32, three Bools, a box) from 8 to 4, and H, boxed in a List, from 4
# to 2. Each is built, matched, rebuilt in place (flip), shared (twice,
# qtwice), captured by a closure and a partial application (r_clo), held in
# a List and a Maybe, dropped (r_poly, qhead, r_drop), handed to a fork and
# to a `!` call, read down a deep spine, and laid out in the static image
# (k3). The keys use the top bit, so a shift or mask out of place shows in
# the hashes; r_drop's dropped tree lies next to the one it reads, so a
# drop that walks the wrong word leaks or overwrites it.
import Base

type Col is Data:
  Ra{}
  Gr{}
  Bl{}

# k, c and b share a word.
type T is Data:
  Lf{}
  Nd{c: Col, l: T, k: U32, b: Bool, r: T}

# a, x, y and z share a word, b another.
type Q is Data:
  Qe{}
  Qn{a: U32, l: Q, x: Bool, b: U32, y: Bool, z: Bool}

# m and t share a word.
type H is Data:
  H{m: Bool, t: U32, i: U32}

def col.at(m: U32) -> Col:
  match m:
    case 0:
      Ra{}
    case 1:
      Gr{}
    case _:
      Bl{}

def col(+n: U32) -> Col:
  col.at(U32.mod(n, 3))

def ci(c: Col) -> U32:
  match c:
    case Ra{}:
      7
    case Gr{}:
      11
    case Bl{}:
      13

def bi(b: Bool) -> U32:
  match b:
    case False{}:
      3
    case True{}:
      5

def mix(+h: U32, +x: U32) -> U32:
  U32.mul(U32.xor(h, x), 16777619)

def key(+n: U32) -> U32:
  U32.xor(U32.mul(n, 2654435761), U32.shln(n, 31n))

def build(+n: Nat, +s: U32) -> T:
  match n:
    case 0n:
      Lf{}
    case 1n+p:
      Nd{col(s), build(p, U32.add(U32.mul(s, 2), 1)), key(s), U32.is_eq(U32.and(s, 1), 1), build(p, U32.add(U32.mul(s, 2), 2))}

def hash(t: T, +h: U32) -> U32:
  match t:
    case Lf{}:
      mix(h, 1)
    case Nd{c, l, k, b, r}:
      hash(r, hash(l, mix(mix(mix(h, ci(c)), k), bi(b))))

def hash_par(t: T) -> U32:
  match t:
    case Lf{}:
      1
    case Nd{c, l, k, b, r}:
      x y = hash_par(l) hash_par(r)
      mix(mix(mix(mix(x, y), ci(c)), k), bi(b))

# rebuilds every node with its fields moved (node reuse): c to the next
# colour, b negated, k complemented
def flip(t: T) -> T:
  match t:
    case Lf{}:
      Lf{}
    case Nd{Ra{}, l, k, b, r}:
      Nd{Gr{}, flip(l), U32.not(k), Bool.not(b), flip(r)}
    case Nd{Gr{}, l, k, b, r}:
      Nd{Bl{}, flip(l), U32.not(k), Bool.not(b), flip(r)}
    case Nd{Bl{}, l, k, b, r}:
      Nd{Ra{}, flip(l), U32.not(k), Bool.not(b), flip(r)}

# a shared tree read twice
def twice(+t: T) -> U32:
  U32.add(hash(t, 0), hash_par(t))

# a closure that captures a tree, and a partial application
def later(t: T) -> U32 -> U32:
  x => hash(t, x)

def spine(+n: Nat, t: T) -> T:
  match n:
    case 0n:
      t
    case 1n+p:
      spine(p, Nd{col(U32.from_nat(n)), t, U32.from_nat(n), U32.is_eq(U32.and(U32.from_nat(n), 3), 0), Lf{}})

def qb(+n: Nat) -> Q:
  match n:
    case 0n:
      Qe{}
    case 1n+p:
      +m = U32.from_nat(n)
      Qn{U32.not(m), qb(p), U32.is_eq(U32.and(m, 1), 0), U32.mul(m, 4294967291), U32.is_eq(U32.and(m, 2), 0), U32.is_eq(U32.and(m, 4), 0)}

def qh(q: Q, +h: U32) -> U32:
  match q:
    case Qe{}:
      h
    case Qn{a, l, x, b, y, z}:
      qh(l, mix(mix(mix(mix(mix(h, a), bi(x)), b), bi(y)), bi(z)))

# a shared Q read twice, and a List whose tail of Qs is dropped
def qtwice(+q: Q) -> U32:
  U32.add(qh(q, 0), qh(q, 1))

def qhead(xs: List<Q>) -> U32:
  match xs:
    case Nil{}:
      0
    case q <> r:
      qh(q, 2)

def hs(+n: Nat) -> List<H>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      +m = U32.from_nat(n)
      H{U32.is_eq(U32.and(m, 1), 1), U32.not(m), U32.mul(m, 3)} <> hs(p)

def hh(xs: List<H>, +h: U32) -> U32:
  match xs:
    case Nil{}:
      h
    case H{m, t, i} <> r:
      hh(r, mix(mix(mix(h, bi(m)), t), i))

def first(xs: List<T>) -> Maybe<T>:
  match xs:
    case Nil{}:
      None{}
    case t <> r:
      Some{t}

def mh(m: Maybe<T>) -> U32:
  match m:
    case None{}:
      0
    case Some{t}:
      hash(t, 9)

# a constant tree: its nodes are laid out in the static image
def k3() -> T:
  Nd{Bl{}, Nd{Gr{}, Lf{}, 2147483648, False{}, Lf{}}, 4294967295, True{}, Nd{Ra{}, Lf{}, 1, True{}, Lf{}}}

# drops a big tree while another is live, then reads the live one
def second(a: T, b: T) -> T:
  b

def r_drop() -> U32:
  hash(second(build(14n, 3), build(14n, 5)), 0)

def r_clo() -> U32:
  +t = build(12n, 0)
  f = later(t)
  g = U32.add(hash_par(t))
  g(f(5))

def r_poly() -> U32:
  mh(first([build(3n, 4), build(12n, 0)]))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(hash(build(12n, 0), 0)))
    Unit <- IO.print(U32.show(U32.add(hash(k3(), 3), hash_par(k3()))))
    Unit <- IO.print(U32.show(hash_par(build(12n, 0))))
    Unit <- IO.print(U32.show(hash(flip(flip(flip(build(12n, 0)))), 0)))
    Unit <- IO.print(U32.show(twice(build(12n, 0))))
    Unit <- IO.print(U32.show(r_clo()))
    Unit <- IO.print(U32.show(r_drop()))
    Unit <- IO.print(U32.show(r_poly()))
    Unit <- IO.print(U32.show(hash_par!(build(10n, 7))))
    Unit <- IO.print(U32.show(hash(spine(3000n, Lf{}), 0)))
    Unit <- IO.print(U32.show(qh(qb(1000n), 0)))
    Unit <- IO.print(U32.show(U32.add(qtwice(qb(50n)), qhead([qb(20n), qb(30n), qb(40n)]))))
    IO.print(U32.show(hh(hs(1000n), 0)))

#|692408375
#|495232873
#|1245431191
#|1668074648
#|1937839566
#|3347258723
#|2880941446
#|4140507220
#|756992728
#|2335103075
#|1799177720
#|1240449645
#|246665000
