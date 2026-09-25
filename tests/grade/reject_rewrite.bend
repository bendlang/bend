type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a grade equation is a legal type, and dead code inhabits it, but a
# rewrite of Kind(&1) into Kind(&2) yields a value nobody can use: the
# cast type never reduces to a function type while e is stuck
law cheat:
  for -e: {&1 == &2 : Quant}
  for +f: {(%e : Kind(_); (Nat -> Nat)) : Data}
  Nat

def cheat(e, f):
  f(f(Zero{}))

#|Error:
#|- expected : a function type
#|- observed : %e : Kind(_); @_:Nat -> Nat
#|Context:
#|- e : {&1 == &2 : Quant}
#|- f : %e : Kind(_); @_:Nat -> Nat
#|Location: cheat
#|22 | def cheat(e, f):
#|23>|   f(f(Zero{}))
#|   |   ^^^^^^^^^^^^
#|24 |
#|exit 1
