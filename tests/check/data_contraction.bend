# THE PROOF IDIOM: an arm's field feeds the IH, a lemma premise and the
# goal -- the one-field-many-premises shape bend3's Data contraction
# existed to type. bend core is affine for every type, so the many
# spends ride a + scrutinee (N is Data). The value
# block runs the program.
# ported from bend3: rewrites carry explicit motives and fold right into
# left, so plus_succ is stated with the eliminated term on the right;
# the numeric nat(n) match becomes U32.to_nat + Nat recursion
import Base

type N is Data:
  Z{}
  S{p: N}

law plus:
  for a: N
  for b: N
  N

def plus(a, b):
  match a:
    case Z{}:
      b
    case S{ap}:
      S{plus(ap, b)}

law double:
  for n: N
  N

def double(n):
  match n:
    case Z{}:
      Z{}
    case S{p}:
      S{S{double(p)}}

law plus_succ:
  for  a: N
  for -b: N
  {S{plus(a, b)} == plus(a, S{b}) : N}

def plus_succ(a, b):
  match a:
    case Z{}:
      {==}
    case S{ap}:
      %plus_succ(ap, b) : {S{S{plus(ap, b)}} == S{_} : N}
      {==}

law double_plus:
  for +n: N
  {double(n) == plus(n, n) : N}

def double_plus(n):
  match n:
    case Z{}:
      {==}
    case S{p}:
      %plus_succ(p, p) : {S{S{double(p)}} == S{_} : N}
      %double_plus(p) : {S{S{double(p)}} == S{S{_}} : N}
      {==}

law nat.go:
  for m: Nat
  N

def nat.go(m):
  match m:
    case Zero{}:
      Z{}
    case Succ{q}:
      S{nat.go(q)}

law nat:
  for k: U32
  N

def nat(k):
  nat.go(U32.to_nat(k))

law val:
  for x: N
  U32

def val(x):
  match x:
    case Z{}:
      0
    case S{p}:
      (1 + val(p) : U32)

law main.out:
  U32

def main.out():
  val(double(nat(10)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|20
