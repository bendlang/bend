# proof_numerics: the proofs. A law is a def whose type is the claim: a
# match is the case analysis, the self-call is the induction hypothesis,
# and %e : P rewrites the goal with the equation e.

import Base
import ./main.bend as Num
import ./LAWS.bend as Laws

# Addition
# --------

def add_zero(a: Nat) -> {a == Num.add(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, -b: Nat) -> {1n+Num.add(a, b) == Num.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Num.add(p, b) == 1n+_ : Nat}
      {==}

def Laws.add_comm(a, b):
  match a:
    case 0n:
      %add_zero(b) : {b == _ : Nat}
      {==}
    case 1n+p:
      %add_succ(b, p) : {1n+Num.add(p, b) == _ : Nat}
      %Laws.add_comm(p, b) : {1n+Num.add(p, b) == 1n+_ : Nat}
      {==}

def Laws.add_assoc(a, b, c):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %Laws.add_assoc(p, b, c) : {1n+Num.add(p, Num.add(b, c)) == 1n+_ : Nat}
      {==}

# Multiplication
# --------------

# the middle terms of a triple sum swap
def add_swap(x: Nat, +y: Nat, +z: Nat) -> {Num.add(x, Num.add(y, z)) == Num.add(y, Num.add(x, z)) : Nat}:
  match x:
    case 0n:
      {==}
    case 1n+q:
      %add_succ(y, Num.add(q, z)) : {1n+Num.add(q, Num.add(y, z)) == _ : Nat}
      %add_swap(q, y, z) : {1n+Num.add(q, Num.add(y, z)) == 1n+_ : Nat}
      {==}

def mul_zero(a: Nat) -> {Num.mul(a, 0n) == 0n : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      mul_zero(p)

def mul_succ(+a: Nat, +b: Nat) -> {Num.add(a, Num.mul(a, b)) == Num.mul(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n++p:
      %mul_succ(p, b) : {1n+Num.add(p, Num.add(b, Num.mul(p, b))) == 1n+Num.add(b, _) : Nat}
      %add_swap(p, b, Num.mul(p, b)) : {1n+Num.add(p, Num.add(b, Num.mul(p, b))) == 1n+_ : Nat}
      {==}

def Laws.mul_comm(a, b):
  match a:
    case 0n:
      %mul_zero(b) : {_ == Num.mul(b, 0n) : Nat}
      {==}
    case 1n++p:
      %mul_succ(b, p) : {Num.add(b, Num.mul(p, b)) == _ : Nat}
      %Laws.mul_comm(p, b) : {Num.add(b, Num.mul(p, b)) == Num.add(b, _) : Nat}
      {==}

def Laws.mul_dist(a, b, c):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %Laws.mul_dist(p, b, c) : {Num.add(Num.add(c, Num.mul(p, c)), Num.mul(b, c)) == Num.add(c, _) : Nat}
      %Laws.add_assoc(c, Num.mul(p, c), Num.mul(b, c)) : {_ == Num.add(c, Num.add(Num.mul(p, c), Num.mul(b, c))) : Nat}
      {==}

# Division
# --------

# a type picked by a Bool: a rewrite through it refutes True{} == False{}
def BD(b: Bool, t: Type, f: Type) -> Type:
  match b:
    case True{}:
      t
    case False{}:
      f

# a remainder at most m that is not below m is m
def le_eq(r: Nat, m: Nat, le: {True{} == (r < 1n+m) : Bool}, e: {False{} == (r < m) : Bool}) -> {r == m : Nat}:
  match r m:
    case 0n 0n:
      {==}
    case 0n 1n+b:
      %e : BD(_, {0n == 1n+b : Nat}, Unit)
      Unit{}
    case 1n 0n:
      %le : BD(_, Unit, {1n == 0n : Nat})
      Unit{}
    case 2n+a 0n:
      %le : BD(_, Unit, {2n+a == 0n : Nat})
      Unit{}
    case 1n+a 1n+b:
      %le_eq(a, b, le, e) : {1n+a == 1n+_ : Nat}
      {==}

# Ok(n, m, qr): qr is Euclid's quotient and remainder of n by 1n+m
def Ok(n: Nat, m: Nat, qr: Nat & Nat) -> Type:
  &q: Nat -> &r: Nat -> {(q, r) == qr : Nat & Nat} & {True{} == (r < 1n+m) : Bool} & {n == Num.add(r, Num.mul(q, 1n+m)) : Nat}

# the wrap arm: r has reached m, so 1n+q and 0n rebuild 1n+p
def wrap_eq(-p: Nat, m: Nat, -q: Nat, r: Nat, le: {True{} == (r < 1n+m) : Bool}, e: {False{} == (r < m) : Bool}, eq: {p == Num.add(r, Num.mul(q, 1n+m)) : Nat})
  -> {1n+p == Num.add(0n, Num.mul(1n+q, 1n+m)) : Nat}:
  %le_eq(r, m, le, e) : {1n+p == 1n+Num.add(_, Num.mul(q, 1n+m)) : Nat}
  %eq : {1n+p == 1n+_ : Nat}
  {==}

# the step keeps Ok, decided on the verdict b of r < m
def wrap_ok(-p: Nat, m: Nat, q: Nat, +r: Nat, le: {True{} == (r < 1n+m) : Bool}, eq: {p == Num.add(r, Num.mul(q, 1n+m)) : Nat}, b: Bool, e: {b == (r < m) : Bool})
  -> Ok(1n+p, m, Num.divmod.wrap(b, q, r)):
  match b:
    case True{}:
      (q, 1n+r, {==}, e, Equal.cong(Nat, Nat, k => 1n+k, p, Num.add(r, Num.mul(q, 1n+m)), eq))
    case False{}:
      (1n+q, 0n, {==}, {==}, wrap_eq(p, m, q, r, le, e, eq))

# opens the certificate of divmod.go(p, m) and runs it through wrap_ok
def step_ok(-p: Nat, +m: Nat, w: Ok(p, m, Num.divmod.go(p, m))) -> Ok(1n+p, m, Num.divmod.step(m, Num.divmod.go(p, m))):
  (q, r0, dq, le, eq) = w
  +r = r0
  %dq : Ok(1n+p, m, Num.divmod.step(m, _))
  wrap_ok(p, m, q, r, le, eq, (r < m), {==})

def Laws.divmod_ok(n, m):
  match n:
    case 0n:
      (0n, 0n, {==}, {==}, {==})
    case 1n+p:
      step_ok(p, m, Laws.divmod_ok(p, m))
