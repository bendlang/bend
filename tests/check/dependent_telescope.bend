# a wide constructor telescope may be dependent: the 8th field's type
# mentions the 1st; construction and match destructure both ride.
# ported from bend3: U32 fields become a local Nat (affine: the
# projection returns the pinned first field)
type Nq is Data:
  Zq{}
  Sq{p: Nq}

type Rq is Data:
  Mq{a: Nq, b: Nq, c: Nq, d: Nq, e2: Nq, f: Nq, g: Nq, p: {a == Sq{Zq{}} : Nq}}

law total:
  for r: Rq
  Nq

def total(r):
  match r:
    case Mq{a, b, c, d, e2, f, g, p}:
      a

law main:
  Nq

def main(): total(Mq{Sq{Zq{}}, Zq{}, Zq{}, Zq{}, Zq{}, Zq{}, Zq{}, {==}})

#|Sq{Zq{}}
