type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# the Leak exploit: a constructor-local grade L is never assumed &2,
# so value : A with A : Kind(L) cannot sit in a Data datatype; the
# whole clone/boom program below is refused at its first line
type Leak<-R: Type> is Data:
  MkLeak{L, -A: Kind(L), same: {A == R : Type}, value: A}

law seal:
  for -R: Type
  for  x: R
  Leak<R>

def seal(R, x):
  MkLeak{&1, R, {==}, x}

law unseal:
  for -R: Type
  for  z: Leak<R>
  R

def unseal(R, z):
  match z:
    case MkLeak{K, A, same, value}:
      %same : _
      value

law clone:
  for -R: Type
  for  x: R
  Sigma<&1, &1, R, _ => R>

def clone(R, x):
  +z = seal(R, x)
  Tuple{unseal(R, z), unseal(R, z)}

type Knot is Type:
  KRoll{run: Knot -> Empty}

law fire:
  for k  : Knot
  for k2 : Knot
  Empty

def fire(k, k2):
  match k:
    case KRoll{run}:
      run(k2)

law delta.go:
  for p: Sigma<&1, &1, Knot, _ => Knot>
  Empty

law delta:
  for k: Knot
  Empty

def delta(k):
  delta.go(clone(Knot, k))

def delta.go(p):
  match p:
    case Tuple{a, b}:
      fire(a, b)

law boom:
  Empty

def boom():
  delta(KRoll{delta})

#|Error:
#|- expected : Data
#|- observed : Kind(L)
#|Context:
#|- R    : Type
#|- L    : Quant
#|- A    : Kind(L)
#|- same : {A == R : Type}
#|Location: MkLeak
#|17 | type Leak<-R: Type> is Data:
#|18>|   MkLeak{L, -A: Kind(L), same: {A == R : Type}, value: A}
#|   |                                                        ^
#|19 |
#|exit 1
