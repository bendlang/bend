# A unit converter stores each conversion factor as a fraction of
# naturals (1 inch is 254/100 cm). The factor for an area or a volume
# is the linear factor raised to a power. A result whose denominator
# divides its numerator is shown as a whole number (300/100 m is 3 m).
# LAW: for a factor with a positive denominator, reducing its power and
# raising its reduced form to that power name the same number.

import Base

type Frac is Data:
  Frac{num: Nat, den: Nat}

def Frac.num(q: Frac) -> Nat:
  Frac{num, den} = q
  num

def Frac.den(q: Frac) -> Nat:
  Frac{num, den} = q
  den

def Nat.pow(+b: Nat, n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.mul(b, Nat.pow(b, p))

def Frac.pow(+q: Frac, +n: Nat) -> Frac:
  Frac{Nat.pow(Frac.num(q), n), Nat.pow(Frac.den(q), n)}

# the whole number d when the remainder r is 0n, else the fraction unchanged
def Frac.reduce.fin(q: Frac, dr: Nat & Nat) -> Frac:
  (d, r) = dr
  match r:
    case 0n:
      Frac{d, 1n}
    case 1n+rp:
      q

def Frac.reduce(+q: Frac) -> Frac:
  Frac.reduce.fin(q, Nat.divmod(Frac.num(q), Frac.den(q)))

# two fractions name the same number when they cross-multiply equal
def Frac.eq(+p: Frac, +q: Frac) -> Type:
  {Nat.mul(Frac.num(p), Frac.den(q)) == Nat.mul(Frac.num(q), Frac.den(p)) : Nat}

# LAW: reduce commutes with pow, as numbers, for a factor a/(1+b)
law reduce_pow:
  for +a: Nat
  for +b: Nat
  for +n: Nat
  Frac.eq(Frac.reduce(Frac.pow(Frac{a, 1n+b}, n)), Frac.pow(Frac.reduce(Frac{a, 1n+b}), n))

# solution

# Nat algebra
# -----------

def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

# the outer terms of a triple sum swap
def add_swap(+x: Nat, +y: Nat, +z: Nat) -> {Nat.add(x, Nat.add(y, z)) == Nat.add(y, Nat.add(x, z)) : Nat}:
  match x:
    case 0n:
      {==}
    case 1n+q:
      %add_succ(y, Nat.add(q, z)) : {1n+Nat.add(q, Nat.add(y, z)) == _ : Nat}
      %add_swap(q, y, z) : {1n+Nat.add(q, Nat.add(y, z)) == 1n+_ : Nat}
      {==}

def add_comm(+a: Nat, +b: Nat) -> {Nat.add(a, b) == Nat.add(b, a) : Nat}:
  %add_zero(b) : {Nat.add(a, _) == Nat.add(b, a) : Nat}
  %add_zero(a) : {Nat.add(a, Nat.add(b, 0n)) == Nat.add(b, _) : Nat}
  add_swap(a, b, 0n)

def mul_zero(a: Nat) -> {0n == Nat.mul(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      mul_zero(p)

def mul_succ(+a: Nat, +b: Nat) -> {Nat.add(a, Nat.mul(a, b)) == Nat.mul(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %mul_succ(p, b) : {1n+Nat.add(p, Nat.add(b, Nat.mul(p, b))) == 1n+Nat.add(b, _) : Nat}
      %add_swap(p, b, Nat.mul(p, b)) : {1n+Nat.add(p, Nat.add(b, Nat.mul(p, b))) == 1n+_ : Nat}
      {==}

def mul_one(+a: Nat) -> {a == Nat.mul(a, 1n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %mul_one(p) : {1n+p == 1n+_ : Nat}
      {==}

def mul_comm(+a: Nat, +b: Nat) -> {Nat.mul(a, b) == Nat.mul(b, a) : Nat}:
  match a:
    case 0n:
      mul_zero(b)
    case 1n+p:
      %mul_succ(b, p) : {Nat.add(b, Nat.mul(p, b)) == _ : Nat}
      %mul_comm(p, b) : {Nat.add(b, Nat.mul(p, b)) == Nat.add(b, _) : Nat}
      {==}

# b c + a c == (a + b) c: the sum is flipped so the step needs only add_swap
def mul_dist(+a: Nat, +b: Nat, +c: Nat) -> {Nat.add(Nat.mul(b, c), Nat.mul(a, c)) == Nat.mul(Nat.add(a, b), c) : Nat}:
  match a:
    case 0n:
      add_zero(Nat.mul(b, c))
    case 1n+p:
      %mul_dist(p, b, c) : {Nat.add(Nat.mul(b, c), Nat.add(c, Nat.mul(p, c))) == Nat.add(c, _) : Nat}
      add_swap(Nat.mul(b, c), c, Nat.mul(p, c))

def mul_assoc(+a: Nat, +b: Nat, +c: Nat) -> {Nat.mul(a, Nat.mul(b, c)) == Nat.mul(Nat.mul(a, b), c) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %mul_dist(b, Nat.mul(p, b), c) : {Nat.add(Nat.mul(b, c), Nat.mul(p, Nat.mul(b, c))) == _ : Nat}
      %mul_assoc(p, b, c) : {Nat.add(Nat.mul(b, c), Nat.mul(p, Nat.mul(b, c))) == Nat.add(_, Nat.mul(b, c)) : Nat}
      add_comm(Nat.mul(b, c), Nat.mul(p, Nat.mul(b, c)))

# mul_assoc, read right to left
def assoc_r(+x: Nat, +y: Nat, +z: Nat) -> {Nat.mul(Nat.mul(x, y), z) == Nat.mul(x, Nat.mul(y, z)) : Nat}:
  %mul_assoc(x, y, z) : {_ == Nat.mul(x, Nat.mul(y, z)) : Nat}
  {==}

def mul_swap(+x: Nat, +y: Nat, +z: Nat) -> {Nat.mul(x, Nat.mul(y, z)) == Nat.mul(y, Nat.mul(x, z)) : Nat}:
  %assoc_r(x, y, z) : {_ == Nat.mul(y, Nat.mul(x, z)) : Nat}
  %assoc_r(y, x, z) : {Nat.mul(Nat.mul(x, y), z) == _ : Nat}
  %mul_comm(x, y) : {Nat.mul(Nat.mul(x, y), z) == Nat.mul(_, z) : Nat}
  {==}

# (a b)(c d) == (a c)(b d)
def mul_mix(+a: Nat, +b: Nat, +c: Nat, +d: Nat) -> {Nat.mul(Nat.mul(a, b), Nat.mul(c, d)) == Nat.mul(Nat.mul(a, c), Nat.mul(b, d)) : Nat}:
  %mul_assoc(a, b, Nat.mul(c, d)) : {_ == Nat.mul(Nat.mul(a, c), Nat.mul(b, d)) : Nat}
  %mul_assoc(a, c, Nat.mul(b, d)) : {Nat.mul(a, Nat.mul(b, Nat.mul(c, d))) == _ : Nat}
  %mul_swap(b, c, d) : {Nat.mul(a, Nat.mul(b, Nat.mul(c, d))) == Nat.mul(a, _) : Nat}
  {==}

# a power of a product is the product of the powers
def pow_mul(+x: Nat, +y: Nat, +n: Nat) -> {Nat.pow(Nat.mul(x, y), n) == Nat.mul(Nat.pow(x, n), Nat.pow(y, n)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %mul_mix(x, y, Nat.pow(x, p), Nat.pow(y, p)) : {Nat.mul(Nat.mul(x, y), Nat.pow(Nat.mul(x, y), p)) == _ : Nat}
      %pow_mul(x, y, p) : {Nat.mul(Nat.mul(x, y), Nat.pow(Nat.mul(x, y), p)) == Nat.mul(Nat.mul(x, y), _) : Nat}
      {==}

# a power of a positive number is positive: it is some 1n+k
def pow_den.step(+b: Nat, -p: Nat, w: &k: Nat -> {1n+k == Nat.pow(1n+b, p) : Nat}) -> &j: Nat -> {1n+j == Nat.pow(1n+b, 1n+p) : Nat}:
  (+k, e) = w
  %e : &j: Nat -> {1n+j == Nat.mul(1n+b, _) : Nat}
  (Nat.add(k, Nat.mul(b, 1n+k)), {==})

def pow_den(+b: Nat, +n: Nat) -> &k: Nat -> {1n+k == Nat.pow(1n+b, n) : Nat}:
  match n:
    case 0n:
      (0n, {==})
    case 1n+p:
      pow_den.step(b, p, pow_den(b, p))

# Division
# --------

# x over 1n+k, reduced by the result go of a divmod, is still x over 1n+k
def KG(+x: Nat, +k: Nat, go: Nat & Nat) -> Type:
  Frac.eq(Frac.reduce.fin(Frac{x, 1n+k}, go), Frac{x, 1n+k})

# Base's divmod.go keeps m + r == k and the number r + d (1n+k) + n; reducing
# by its result keeps that number, as a fraction over 1n+k
def keeps_go(+n: Nat, +m: Nat, +d: Nat, +r: Nat, +k: Nat, e: {Nat.add(m, r) == k : Nat}) -> Frac.eq(Frac.reduce.fin(Frac{Nat.add(Nat.add(r, Nat.mul(d, 1n+k)), n), 1n+k}, Nat.divmod.go(n, m, d, r)), Frac{Nat.add(Nat.add(r, Nat.mul(d, 1n+k)), n), 1n+k}):
  match n:
    case 0n:
      match r:
        case 0n:
          %Equal.sym(Nat, Nat.add(Nat.mul(d, 1n+k), 0n), Nat.mul(d, 1n+k), add_zero(Nat.mul(d, 1n+k))) : {Nat.mul(d, 1n+k) == Nat.mul(_, 1n) : Nat}
          mul_one(Nat.mul(d, 1n+k))
        case 1n+rp:
          {==}
    case 1n+np:
      match m:
        case 0n:
          %e : KG(Nat.add(Nat.add(r, Nat.mul(d, 1n+_)), 1n+np), _, Nat.divmod.go(np, r, 1n+d, 0n))
          %add_succ(Nat.add(r, Nat.mul(d, 1n+r)), np) : KG(_, r, Nat.divmod.go(np, r, 1n+d, 0n))
          keeps_go(np, r, 1n+d, 0n, r, add_zero(r))
        case 1n+mp:
          %add_succ(Nat.add(r, Nat.mul(d, 1n+k)), np) : KG(_, k, Nat.divmod.go(np, mp, d, 1n+r))
          keeps_go(np, mp, d, 1n+r, k, Equal.trans(Nat, Nat.add(mp, 1n+r), 1n+Nat.add(mp, r), k, Equal.sym(Nat, 1n+Nat.add(mp, r), Nat.add(mp, 1n+r), add_succ(mp, r)), e))

# divmod.go counts m down and r up; when m hits 0n, r wraps to 0n and d steps
def go_wrap(+m: Nat, +x: Nat, +d: Nat, +r: Nat, +k: Nat, e: {Nat.add(m, r) == k : Nat}) -> {Nat.divmod.go(x, k, 1n+d, 0n) == Nat.divmod.go(1n+Nat.add(m, x), m, d, r) : Nat & Nat}:
  match m:
    case 0n:
      %e : {Nat.divmod.go(x, _, 1n+d, 0n) == Nat.divmod.go(x, r, 1n+d, 0n) : Nat & Nat}
      {==}
    case 1n+mp:
      go_wrap(mp, x, d, 1n+r, k, Equal.trans(Nat, Nat.add(mp, 1n+r), 1n+Nat.add(mp, r), k, Equal.sym(Nat, 1n+Nat.add(mp, r), Nat.add(mp, 1n+r), add_succ(mp, r)), e))

# an exact multiple q (1n+k) divides into the quotient q and no remainder
def go_exact(+q: Nat, +k: Nat, +d: Nat) -> {(Nat.add(q, d), 0n) == Nat.divmod.go(Nat.mul(q, 1n+k), k, d, 0n) : Nat & Nat}:
  match q:
    case 0n:
      {==}
    case 1n+p:
      %go_wrap(k, Nat.mul(p, 1n+k), d, 0n, k, add_zero(k)) : {(1n+Nat.add(p, d), 0n) == _ : Nat & Nat}
      %go_exact(p, k, 1n+d) : {(1n+Nat.add(p, d), 0n) == _ : Nat & Nat}
      %add_succ(p, d) : {(1n+Nat.add(p, d), 0n) == (_, 0n) : Nat & Nat}
      {==}

# reducing q (1n+k) over 1n+k gives the whole number q
def exact(+q: Nat, +k: Nat) -> {Frac.reduce(Frac{Nat.mul(q, 1n+k), 1n+k}) == Frac{q, 1n} : Frac}:
  %go_exact(q, k, 0n) : {Frac.reduce.fin(Frac{Nat.mul(q, 1n+k), 1n+k}, _) == Frac{q, 1n} : Frac}
  %add_zero(q) : {Frac{Nat.add(q, 0n), 1n} == Frac{_, 1n} : Frac}
  {==}

# a positive factor cancels: both sides reduce to the same whole number
def cancel(+k: Nat, +x: Nat, +y: Nat, e: {Nat.mul(x, 1n+k) == Nat.mul(y, 1n+k) : Nat}) -> {x == y : Nat}:
  %exact(x, k) : {Frac.num(_) == y : Nat}
  %exact(y, k) : {Frac.num(Frac.reduce(Frac{Nat.mul(x, 1n+k), 1n+k})) == Frac.num(_) : Nat}
  %e : {Frac.num(Frac.reduce(Frac{Nat.mul(x, 1n+k), 1n+k})) == Frac.num(Frac.reduce(Frac{_, 1n+k})) : Nat}
  {==}

# Frac.eq is transitive over a positive middle, and respected by pow
# ------------------------------------------------------------------

# (a f) d == (e b) d from a d == c b and c f == e d
def trans.go(+a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, pq: {Nat.mul(a, d) == Nat.mul(c, b) : Nat}, qr: {Nat.mul(c, f) == Nat.mul(e, d) : Nat}) -> {Nat.mul(Nat.mul(a, f), d) == Nat.mul(Nat.mul(e, b), d) : Nat}:
  +R = Nat.mul(Nat.mul(e, b), d)
  %mul_assoc(a, f, d) : {_ == R : Nat}
  %mul_swap(f, a, d) : {_ == R : Nat}
  %Equal.sym(Nat, Nat.mul(a, d), Nat.mul(c, b), pq) : {Nat.mul(f, _) == R : Nat}
  %assoc_r(f, c, b) : {_ == R : Nat}
  %mul_comm(c, f) : {Nat.mul(_, b) == R : Nat}
  %Equal.sym(Nat, Nat.mul(c, f), Nat.mul(e, d), qr) : {Nat.mul(_, b) == R : Nat}
  %mul_assoc(e, d, b) : {_ == R : Nat}
  %mul_assoc(e, b, d) : {Nat.mul(e, Nat.mul(d, b)) == _ : Nat}
  %mul_comm(d, b) : {Nat.mul(e, Nat.mul(d, b)) == Nat.mul(e, _) : Nat}
  {==}

def resp(+p: Frac, +q: Frac, +n: Nat, e: Frac.eq(p, q)) -> Frac.eq(Frac.pow(p, n), Frac.pow(q, n)):
  %pow_mul(Frac.num(p), Frac.den(q), n) : {_ == Nat.mul(Nat.pow(Frac.num(q), n), Nat.pow(Frac.den(p), n)) : Nat}
  %pow_mul(Frac.num(q), Frac.den(p), n) : {Nat.pow(Nat.mul(Frac.num(p), Frac.den(q)), n) == _ : Nat}
  %e : {Nat.pow(Nat.mul(Frac.num(p), Frac.den(q)), n) == Nat.pow(_, n) : Nat}
  {==}

# resp for a/(1n+b), with the power of the denominator named 1n+k
def resp.fix(+a: Nat, +b: Nat, +n: Nat, +k: Nat, e: {1n+k == Nat.pow(1n+b, n) : Nat}, +q: Frac, eq: Frac.eq(Frac{a, 1n+b}, q)) -> {Nat.mul(Nat.pow(a, n), Nat.pow(Frac.den(q), n)) == Nat.mul(Nat.pow(Frac.num(q), n), 1n+k) : Nat}:
  %Equal.sym(Nat, 1n+k, Nat.pow(1n+b, n), e) : {Nat.mul(Nat.pow(a, n), Nat.pow(Frac.den(q), n)) == Nat.mul(Nat.pow(Frac.num(q), n), _) : Nat}
  resp(Frac{a, 1n+b}, q, n, eq)

# reduce(pow(q)) ~ pow(q) ~ pow(reduce(q)), cancelling the positive denominator 1n+k of pow(q)
def reduce_pow.go(+a: Nat, +b: Nat, +n: Nat, +k: Nat, +e: {1n+k == Nat.pow(1n+b, n) : Nat}) -> Frac.eq(Frac.reduce(Frac.pow(Frac{a, 1n+b}, n)), Frac.pow(Frac.reduce(Frac{a, 1n+b}), n)):
  +R = Frac.reduce(Frac{a, 1n+b})
  +Q = Frac.pow(R, n)
  %e : Frac.eq(Frac.reduce(Frac{Nat.pow(a, n), _}), Q)
  +P = Frac.reduce(Frac{Nat.pow(a, n), 1n+k})
  cancel(k, Nat.mul(Frac.num(P), Frac.den(Q)), Nat.mul(Frac.num(Q), Frac.den(P)), trans.go(Frac.num(P), Frac.den(P), Nat.pow(a, n), 1n+k, Frac.num(Q), Frac.den(Q), keeps_go(Nat.pow(a, n), k, 0n, 0n, k, add_zero(k)), resp.fix(a, b, n, k, e, R, Equal.sym(Nat, Nat.mul(Frac.num(R), 1n+b), Nat.mul(a, Frac.den(R)), keeps_go(a, b, 0n, 0n, b, add_zero(b))))))

def reduce_pow.fix(+a: Nat, +b: Nat, +n: Nat, w: &k: Nat -> {1n+k == Nat.pow(1n+b, n) : Nat}) -> Frac.eq(Frac.reduce(Frac.pow(Frac{a, 1n+b}, n)), Frac.pow(Frac.reduce(Frac{a, 1n+b}), n)):
  (+k, e) = w
  reduce_pow.go(a, b, n, k, e)

def reduce_pow(a, b, n):
  reduce_pow.fix(a, b, n, pow_den(b, n))
