# Parallel sort -- the proofs: inductions on the depth, where a node's four
# half-sums regroup into the induction hypotheses; a leaf is add_comm.
import Base
import ./main.bend as Sort
import ./SPEC.bend as Spec
import ./LAWS.bend as Laws

def add_zero(a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def add_comm(a: Nat, +b: Nat) -> {Nat.add(a, b) == Nat.add(b, a) : Nat}:
  match a:
    case 0n:
      add_zero(b)
    case 1n+p:
      %add_succ(b, p) : {1n+Nat.add(p, b) == _ : Nat}
      %add_comm(p, b) : {1n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def add_swap(x: Nat, +y: Nat, +z: Nat) -> {Nat.add(x, Nat.add(y, z)) == Nat.add(y, Nat.add(x, z)) : Nat}:
  match x:
    case 0n:
      {==}
    case 1n+q:
      %add_succ(y, Nat.add(q, z)) : {1n+Nat.add(q, Nat.add(y, z)) == _ : Nat}
      %add_swap(q, y, z) : {1n+Nat.add(q, Nat.add(y, z)) == 1n+_ : Nat}
      {==}

def add_regroup(a: Nat, b: Nat, c: Nat, d: Nat)
  -> {Nat.add(Nat.add(a, b), Nat.add(c, d)) == Nat.add(Nat.add(a, c), Nat.add(b, d)) : Nat}:
  match a:
    case 0n:
      add_swap(b, c, d)
    case 1n+p:
      %add_regroup(p, b, c, d) : {1n+Nat.add(Nat.add(p, b), Nat.add(c, d)) == 1n+_ : Nat}
      {==}

def mix_leaf(s: Bool, c: Bool, +x: Nat, +y: Nat)
  -> {Nat.add(x, y) == Nat.add(Sort.pick(Nat, Bool.xor(s, c), x, y), Sort.pick(Nat, Bool.xor(Bool.not(s), c), x, y)) : Nat}:
  match s c:
    case True{} True{}:
      add_comm(x, y)
    case True{} False{}:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      add_comm(x, y)

def Laws.mix_leaves(d, s, x, y):
  match d:
    case 0n:
      mix_leaf(s, Nat.is_lt(y, x), x, y)
    case 1n++p:
      (+xl, +xr) = x
      (+yl, +yr) = y
      +a = Spec.sum(p, Sort.mix(p, s, xl, yl))
      +b = Spec.sum(p, Sort.mix(p, s, xr, yr))
      +c = Spec.sum(p, Sort.mix(p, Bool.not(s), xl, yl))
      +d = Spec.sum(p, Sort.mix(p, Bool.not(s), xr, yr))
      +e = Spec.sum(p, xl)
      +f = Spec.sum(p, xr)
      +g = Spec.sum(p, yl)
      +h = Spec.sum(p, yr)
      %add_regroup(e, g, f, h) : {_ == Nat.add(Nat.add(a, b), Nat.add(c, d)) : Nat}
      %add_regroup(a, c, b, d) : {Nat.add(Nat.add(e, g), Nat.add(f, h)) == _ : Nat}
      %Laws.mix_leaves(p, s, xl, yl) : {Nat.add(Nat.add(e, g), Nat.add(f, h)) == Nat.add(_, Nat.add(b, d)) : Nat}
      %Laws.mix_leaves(p, s, xr, yr) : {Nat.add(Nat.add(e, g), Nat.add(f, h)) == Nat.add(Nat.add(e, g), _) : Nat}
      {==}

def sum_flow(+d: Nat, +s: Bool, +t: Sort.Tree(d)) -> {Spec.sum(d, t) == Spec.sum(d, Sort.flow(d, s, t)) : Nat}:
  match d:
    case 0n:
      {==}
    case 1n++p:
      (+x, +y) = t
      %sum_flow(p, s, Sort.mix(p, s, x, y)) : {Nat.add(Spec.sum(p, x), Spec.sum(p, y)) == Nat.add(_, Spec.sum(p, Sort.flow(p, s, Sort.mix(p, Bool.not(s), x, y)))) : Nat}
      %sum_flow(p, s, Sort.mix(p, Bool.not(s), x, y)) : {Nat.add(Spec.sum(p, x), Spec.sum(p, y)) == Nat.add(Spec.sum(p, Sort.mix(p, s, x, y)), _) : Nat}
      Laws.mix_leaves(p, s, x, y)

def Laws.sort_leaves(d, s, t):
  match d:
    case 0n:
      {==}
    case 1n++p:
      (+x, +y) = t
      %sum_flow(1n+p, s, (Sort.sort(p, True{}, x), Sort.sort(p, False{}, y))) : {Nat.add(Spec.sum(p, x), Spec.sum(p, y)) == _ : Nat}
      %Laws.sort_leaves(p, True{}, x) : {Nat.add(Spec.sum(p, x), Spec.sum(p, y)) == Nat.add(_, Spec.sum(p, Sort.sort(p, False{}, y))) : Nat}
      %Laws.sort_leaves(p, False{}, y) : {Nat.add(Spec.sum(p, x), Spec.sum(p, y)) == Nat.add(Spec.sum(p, x), _) : Nat}
      {==}
