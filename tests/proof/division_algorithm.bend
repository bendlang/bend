# FLAGSHIP: the division algorithm. For every n and positive divisor
# 1n+d1 there are q and r with r <= d1 and n = q*(1n+d1) + r -- by
# induction on n, deciding r = d1 with the Bool-inspect idiom
# (div_step abstracting the goal over b with {eqn(r, d1) == b}).
# ported from bend3: the Base Nat kit (LE, eq, add/mul lemmas,
# true_ne_false) is local -- local add/mul keep the defining equations
# conversion; rewrites carry explicit motives stated with the term each
# eliminates on the right; where-evidence is its own exists clause
import Base

law LE:
  for a: Nat
  for b: Nat
  Type

def LE(a, b):
  match a:
    case 0n:
      Unit
    case 1n+a1:
      match b:
        case 0n:
          Empty
        case 1n+b1:
          LE(a1, b1)

law add:
  for a: Nat
  for b: Nat
  Nat

def add(a, b):
  match a:
    case 0n:
      b
    case 1n+p:
      1n+add(p, b)

law mul:
  for  a: Nat
  for +b: Nat
  Nat

def mul(a, b):
  match a:
    case 0n:
      0n
    case 1n+p:
      add(b, mul(p, b))

law eqn:
  for a: Nat
  for b: Nat
  Bool

def eqn(a, b):
  match a, b:
    case 0n, 0n:
      True{}
    case 0n, 1n+bp:
      False{}
    case 1n+ap, 0n:
      False{}
    case 1n+ap, 1n+bp:
      eqn(ap, bp)

law BD:
  for b  : Bool
  for tc : Type
  for fc : Type
  Type

def BD(b, tc, fc):
  match b:
    case True{}:
      tc
    case False{}:
      fc

law tf_ne:
  for e: {True{} == False{} : Bool}
  Empty

def tf_ne(e):
  %e : BD(_, Unit, Empty)
  Unit{}

law eq_means_eq:
  for r  : Nat
  for d1 : Nat
  for e  : {eqn(r, d1) == True{} : Bool}
  {r == d1 : Nat}

def eq_means_eq(r, d1, e):
  match r, d1:
    case 0n, 0n:
      {==}
    case 0n, 1n+b:
      %e : BD(_, {0n == 1n+b : Nat}, Unit)
      Unit{}
    case 1n+a, 0n:
      %e : BD(_, {1n+a == 0n : Nat}, Unit)
      Unit{}
    case 1n+a, 1n+b:
      %eq_means_eq(a, b, e) : {1n+a == 1n+_ : Nat}
      {==}

law add_zero:
  for a: Nat
  {a == add(a, 0n) : Nat}

def add_zero(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

law add_succ:
  for  a: Nat
  for -b: Nat
  {1n+add(a, b) == add(a, 1n+b) : Nat}

def add_succ(a, b):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+add(p, b) == 1n+_ : Nat}
      {==}

law add_comm:
  for  a: Nat
  for +b: Nat
  {add(a, b) == add(b, a) : Nat}

def add_comm(a, b):
  match a:
    case 0n:
      add_zero(b)
    case 1n+p:
      %add_succ(b, p) : {1n+add(p, b) == _ : Nat}
      %add_comm(p, b) : {1n+add(p, b) == 1n+_ : Nat}
      {==}

law le_bump:
  for r  : Nat
  for d1 : Nat
  for ev : LE(r, d1)
  for e  : {eqn(r, d1) == False{} : Bool}
  LE(1n+r, d1)

def le_bump(r, d1, ev, e):
  match r, d1:
    case 0n, 0n:
      tf_ne(e)
    case 0n, 1n+b:
      Unit{}
    case 1n+a, 0n:
      match ev:
    case 1n+a, 1n+b:
      le_bump(a, b, ev, e)

law div_t_eq:
  for -p  : Nat
  for +d1 : Nat
  for +q  : Nat
  for -r  : Nat
  for rd  : {r == d1 : Nat}
  for eq0 : {p == add(mul(q, 1n+d1), r) : Nat}
  {1n+p == add(mul(1n+q, 1n+d1), 0n) : Nat}

def div_t_eq(p, d1, q, r, rd, eq0):
  %add_zero(add(d1, mul(q, 1n+d1))) : {1n+p == 1n+_ : Nat}
  %add_comm(mul(q, 1n+d1), d1) : {1n+p == 1n+_ : Nat}
  %rd : {1n+p == 1n+add(mul(q, 1n+d1), _) : Nat}
  %eq0 : {1n+p == 1n+_ : Nat}
  {==}

law div_f_eq:
  for -p  : Nat
  for d1  : Nat
  for q   : Nat
  for -r  : Nat
  for eq0 : {p == add(mul(q, 1n+d1), r) : Nat}
  {1n+p == add(mul(q, 1n+d1), 1n+r) : Nat}

def div_f_eq(p, d1, q, r, eq0):
  %add_succ(mul(q, 1n+d1), r) : {1n+p == _ : Nat}
  %eq0 : {1n+p == 1n+_ : Nat}
  {==}

law div_step:
  for -p  : Nat
  for +d1 : Nat
  for +q  : Nat
  for +r  : Nat
  for ev  : LE(r, d1)
  for eq0 : {p == add(mul(q, 1n+d1), r) : Nat}
  for b   : Bool
  {eqn(r, d1) == b : Bool} -> &q2: Nat -> &r2: Nat -> &e2: LE(r2, d1) -> {1n+p == add(mul(q2, 1n+d1), r2) : Nat}

def div_step(p, d1, q, r, ev, eq0, b):
  match b:
    case True{}:
      e => (1n+q, 0n, Unit{}, div_t_eq(p, d1, q, r, eq_means_eq(r, d1, e), eq0))
    case False{}:
      e => (q, 1n+r, le_bump(r, d1, ev, e), div_f_eq(p, d1, q, r, eq0))

law div_spec:
  for n  : Nat
  for d1 : Nat
  exs q  : Nat
  exs r  : Nat
  exs e2 : LE(r, d1)
  {n == add(mul(q, 1n+d1), r) : Nat}

law div_spec.go:
  for -p : Nat
  for +d : Nat
  for w  : (&q: Nat -> &r: Nat -> &e2: LE(r, d) -> {p == add(mul(q, 1n+d), r) : Nat})
  exs q  : Nat
  exs r  : Nat
  exs e2 : LE(r, d)
  {1n+p == add(mul(q, 1n+d), r) : Nat}

def div_spec.go(p, d, w):
  (q, r0, ev, eq0) = w
  +r = {r0 : Nat}
  div_step(p, d, q, r, ev, eq0, eqn(r, d))({==})

def div_spec(n, d1):
  match n:
    case 0n:
      (0n, 0n, Unit{}, {==})
    case 1n+p:
      +d = {d1 : Nat}
      div_spec.go(p, d, div_spec(p, d))

law five_by_two:
  &q: Nat -> &r: Nat -> &e2: LE(r, 1n) -> {5n == add(mul(q, 2n), r) : Nat}

def five_by_two(): div_spec(5n, 1n)

law main:
  &q: Nat -> &r: Nat -> &e2: LE(r, 1n) -> {5n == add(mul(q, 2n), r) : Nat}

def main(): five_by_two()

#|(2n, 1n, Unit{}, {==})
