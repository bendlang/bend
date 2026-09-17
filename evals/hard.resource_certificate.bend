# A workshop assigns natural-number certificates to binary resource trees.
# Triangular diagonals pack both child certificates into one number.
# Prove that equal certificates identify exactly the same tree.
import Base

type Resource is Data:
  Leaf{}
  Fork{left: Resource, right: Resource}

def triangle(+n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: 1n+Nat.add(p, triangle(p))

def diagonal(+a: Nat, +b: Nat) -> Nat:
  Nat.add(b, triangle(Nat.add(a, b)))

def certificate(t: Resource) -> Nat:
  match t:
    case Leaf{}: 0n
    case Fork{l, r}: 1n+diagonal(certificate(l), certificate(r))

law certificate_unique:
  for t: Resource
  for u: Resource
  for e: {certificate(t) == certificate(u) : Nat}
  {t == u : Resource}

# solution

def le(a: Nat, b: Nat) -> Data:
  match a b:
    case 0n _: Unit
    case 1n+p 0n: Empty
    case 1n+p 1n+q: le(p, q)

def pred(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: p

def successor_inj(+a: Nat, +b: Nat, e: {1n+a == 1n+b : Nat}) -> {a == b : Nat}:
  %e : {a == pred(_) : Nat}
  {==}

def zero_clash(-T: Type, +n: Nat, e: {1n+n == 0n : Nat}) -> T:
  Empty.absurd(T, (%e : le(1n, _); Unit{}))

def add_zero(+a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n: {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ(+a: Nat, +b: Nat) -> {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}:
  match a:
    case 0n: {==}
    case 1n+p:
      %add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

def add_cancel(+a: Nat, +b: Nat, +c: Nat, e: {Nat.add(a, b) == Nat.add(a, c) : Nat}) -> {b == c : Nat}:
  match a:
    case 0n: e
    case 1n+p: add_cancel(p, b, c, successor_inj(Nat.add(p, b), Nat.add(p, c), e))

def le_trans(+a: Nat, +b: Nat, +c: Nat, ab: le(a, b), bc: le(b, c)) -> le(a, c):
  match a b c:
    case 0n _ _: Unit{}
    case 1n+p 0n _: Empty.absurd(le(1n+p, c), ab)
    case 1n+p 1n+q 0n: Empty.absurd(le(1n+p, 0n), bc)
    case 1n+p 1n+q 1n+r: le_trans(p, q, r, ab, bc)

def le_prefix(+a: Nat, +b: Nat) -> le(b, Nat.add(a, b)):
  match b:
    case 0n: Unit{}
    case 1n+p:
      %Equal.sym(Nat, Nat.add(a, 1n+p), 1n+Nat.add(a, p), add_succ(a, p)) : le(1n+p, _)
      le_prefix(a, p)

def add_comm(+a: Nat, +b: Nat) -> {Nat.add(a, b) == Nat.add(b, a) : Nat}:
  match a:
    case 0n: Equal.sym(Nat, Nat.add(b, 0n), b, add_zero(b))
    case 1n+p:
      %Equal.sym(Nat, Nat.add(b, 1n+p), 1n+Nat.add(b, p), add_succ(b, p)) : {1n+Nat.add(p, b) == _ : Nat}
      %add_comm(p, b) : {1n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def le_add_left(+a: Nat, +b: Nat, +c: Nat, bc: le(b, c)) -> le(Nat.add(a, b), Nat.add(a, c)):
  match a:
    case 0n: bc
    case 1n+p: le_add_left(p, b, c, bc)

def le_add_right(+a: Nat, +b: Nat, +c: Nat, ab: le(a, b)) -> le(Nat.add(a, c), Nat.add(b, c)):
  %add_comm(c, a) : le(_, Nat.add(b, c))
  %add_comm(c, b) : le(Nat.add(c, a), _)
  le_add_left(c, a, b, ab)

def no_self_lt(+a: Nat, e: le(1n+a, a)) -> Empty:
  match a:
    case 0n: e
    case 1n+p: no_self_lt(p, e)

def triangle_mono(+a: Nat, +b: Nat, +ab: le(a, b)) -> le(triangle(a), triangle(b)):
  match a b:
    case 0n _: Unit{}
    case 1n+p 0n: Empty.absurd(le(triangle(1n+p), triangle(0n)), ab)
    case 1n+p 1n+q:
      +tp = triangle(p)
      +tq = triangle(q)
      le_trans(Nat.add(p, tp), Nat.add(q, tp), Nat.add(q, tq),
        le_add_right(p, q, tp, ab),
        le_add_left(q, tp, tq, triangle_mono(p, q, ab)))

def compare_elim(-R: Type, +a: Nat, +b: Nat,
  same: {a == b : Nat} -> R,
  less: le(1n+a, b) -> R,
  more: le(1n+b, a) -> R) -> R:
  match a b:
    case 0n 0n: same({==})
    case 0n 1n+q: less(Unit{})
    case 1n+p 0n: more(Unit{})
    case 1n+p 1n+q:
      compare_elim(R, p, q,
        e => same(%e : {1n+p == 1n+_ : Nat}; {==}), less, more)

def interval_lt(+n: Nat, +m: Nat, +b: Nat, +d: Nat, bn: le(b, n), nm: le(1n+n, m)) -> le(1n+Nat.add(b, triangle(n)), Nat.add(d, triangle(m))):
  +x = {1n+Nat.add(b, triangle(n)) : Nat}
  +tm = triangle(m)
  le_trans(x, tm, Nat.add(d, tm),
    le_trans(x, triangle(1n+n), tm,
      le_add_right(b, n, triangle(n), bn), triangle_mono(1n+n, m, nm)),
    le_prefix(d, tm))

def reject_lt(+a: Nat, +b: Nat, ab: le(1n+a, b), e: {a == b : Nat}) -> Empty:
  no_self_lt(a, (%Equal.sym(Nat, a, b, e) : le(1n+a, _); ab))

def interval_inj(+n: Nat, +m: Nat, +b: Nat, +d: Nat, bn: le(b, n), dm: le(d, m), +e: {Nat.add(b, triangle(n)) == Nat.add(d, triangle(m)) : Nat}) -> {n == m : Nat}:
  +x = Nat.add(b, triangle(n))
  +y = Nat.add(d, triangle(m))
  compare_elim({n == m : Nat}, n, m, same => same,
    less => Empty.absurd({n == m : Nat},
      reject_lt(x, y, interval_lt(n, m, b, d, bn, less), e)),
    more => Empty.absurd({n == m : Nat},
      reject_lt(y, x, interval_lt(m, n, d, b, dm, more),
        Equal.sym(Nat, x, y, e))))

def cancel_right(+a: Nat, +b: Nat, +c: Nat, e: {Nat.add(a, c) == Nat.add(b, c) : Nat}) -> {a == b : Nat}:
  add_cancel(c, a, b,
    (%add_comm(a, c) : {_ == Nat.add(c, b) : Nat};
      %add_comm(b, c) : {Nat.add(a, c) == _ : Nat}; e))

def diagonal_inj(-R: Type, +a: Nat, +b: Nat, +c: Nat, +d: Nat,
  +e: {diagonal(a, b) == diagonal(c, d) : Nat},
  done: {a == c : Nat} -> {b == d : Nat} -> R) -> R:
  +s = interval_inj(Nat.add(a, b), Nat.add(c, d), b, d, le_prefix(a, b), le_prefix(c, d), e)
  +bd = cancel_right(b, d, triangle(Nat.add(c, d)),
    (%s : {Nat.add(b, triangle(_)) == diagonal(c, d) : Nat}; e))
  done(cancel_right(a, c, d, (%bd : {Nat.add(a, _) == Nat.add(c, d) : Nat}; s)), bd)

def fork_proof(+l: Resource, +r: Resource, +v: Resource, +w: Resource,
  left: {l == v : Resource}, right: {r == w : Resource}) -> {Fork{l, r} == Fork{v, w} : Resource}:
  %left : {Fork{l, r} == Fork{_, w} : Resource}
  %right : {Fork{l, r} == Fork{l, _} : Resource}
  {==}

def certificate_unique(t, u, e):
  match t:
    case Leaf{}:
      match u:
        case Leaf{}: {==}
        case Fork{l, r}:
          +d = diagonal(certificate(l), certificate(r))
          zero_clash({Leaf{} == Fork{l, r} : Resource}, d,
            Equal.sym(Nat, 0n, 1n+d, e))
    case Fork{+l, +r}:
      match u:
        case Leaf{}:
          zero_clash({Fork{l, r} == Leaf{} : Resource}, diagonal(certificate(l), certificate(r)), e)
        case Fork{+v, +w}:
          +a = certificate(l)
          +b = certificate(r)
          +c = certificate(v)
          +d = certificate(w)
          diagonal_inj({Fork{l, r} == Fork{v, w} : Resource}, a, b, c, d,
            successor_inj(diagonal(a, b), diagonal(c, d), e),
            lv => rw => fork_proof(l, r, v, w, certificate_unique(l, v, lv), certificate_unique(r, w, rw)))
