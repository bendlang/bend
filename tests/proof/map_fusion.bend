# map fusion, proved by induction: the function codes specialize inside
# the equation, the cons arm's stuck heads align, and the IH rewrite
# closes the tails -- specialization, computation and rewriting in one
# proof.
# ported from bend3: bend3's List module map becomes a local map over the
# base List (bend's base has no map); infix ops become U32.add/U32.mul;
# map spends f per element, so f is a + binder: a closure is never Data,
# so the mapped function is a Data code (Fn) applied by app, and the
# proof checks strict
import Base

type Fn is Data:
  AddOne{}
  MulTwo{}
  MulTwoAddOne{}

law app:
  for f: Fn
  for x: U32
  U32

def app(f, x):
  match f:
    case AddOne{}:
      U32.add(x, 1)
    case MulTwo{}:
      U32.mul(x, 2)
    case MulTwoAddOne{}:
      U32.add(U32.mul(x, 2), 1)

law map:
  for +f : Fn
  for xs : List<&2, U32>
  List<&2, U32>

def map(f, xs):
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      app(f, h) <> map(f, t)

law fuse:
  for xs: List<&2, U32>
  {map(AddOne{}, map(MulTwo{}, xs)) == map(MulTwoAddOne{}, xs) : List<&2, U32>}

def fuse(xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %fuse(t) : {U32.add(U32.mul(h, 2), 1) <> map(AddOne{}, map(MulTwo{}, t)) == U32.add(U32.mul(h, 2), 1) <> _ : List<&2, U32>}
      {==}

#|All terms check.
