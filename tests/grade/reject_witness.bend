type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a user-written Copiable(T) is just a type: a dead hypothesis of it
# licenses nothing, a + binder needs a Data-kinded type
law Copiable:
  for -T: Type
  Type

def Copiable(T):
  @x: T -> Sigma<&1, &1, T, _ => T>

law dup:
  for -T: Type
  for -c: Copiable(T)
  for +x: T
  Sigma<&1, &1, T, _ => T>

def dup(T, c, x):
  Tuple{x, x}

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- T : Type
#|- c : @x:T -> Sigma<&1, &1, T, _ => T>
#|Location: dup
#|25 |   for -c: Copiable(T)
#|26>|   for +x: T
#|   |           ^
#|27 |   Sigma<&1, &1, T, _ => T>
#|exit 1
