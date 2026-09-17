# constructor discrimination from scratch: a Type-computing predicate and
# the explicit-motive transport turn {T2{} == F2{}} into Emp.
# ported from bend3: bend's rewrite folds right into left, so the raw
# hypothesis transports directly (no sym hop); sym stays as a lemma; the
# != sugar bend dropped is spelled as the refuting arrow
type Uni is Data:
  U{}
type Emp is Data:

type Bit is Data:
  T2{}
  F2{}

law TF:
  for b: Bit
  Type

def TF(b):
  match b:
    case T2{}:
      Uni
    case F2{}:
      Emp

law sym:
  for -A: Type
  for -a: A
  for -b: A
  for  e: {a == b : A}
  {b == a : A}

def sym(A, a, b, e):
  %e : {_ == a : A}
  {==}

law t_ne_f:
  for e: {T2{} == F2{} : Bit}
  Emp

def t_ne_f(e):
  %e : TF(_)
  U{}

law ne:
  {T2{} == F2{} : Bit} -> Emp

def ne(): e => t_ne_f(e)

#|All terms check.
