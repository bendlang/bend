# the Ford trick (parameters + equation fields recover GADTs): Even(n)
# evidence is built with {==} fields, and eliminated by matching -- each
# arm's eq field specializes, refuted via motive transport + succ_inj.
# ported from bend3: transport motives flip to bend's right-into-left
# fold; the lambda motives become _-bound motive terms
type Uni is Data:
  U{}
type Emp is Data:

type N is Data:
  Z{}
  S{p: N}

type Even<-n: N> is Data:
  EZ{eq: {n == Z{} : N}}
  ESS{p: N, e: Even<p>, eq: {n == S{S{p}} : N}}

law NatD:
  for x  : N
  for zc : Type
  for sc : Type
  Type

def NatD(x, zc, sc):
  match x:
    case Z{}:
      zc
    case S{p}:
      sc

law z_ne_s:
  for -p: N
  for  e: {Z{} == S{p} : N}
  Emp

def z_ne_s(p, e):
  %e : NatD(_, Uni, Emp)
  U{}

law s_ne_z:
  for -p: N
  for  e: {S{p} == Z{} : N}
  Emp

def s_ne_z(p, e):
  %e : NatD(_, Emp, Uni)
  U{}

law pred:
  for n: N
  N

def pred(n):
  match n:
    case Z{}:
      Z{}
    case S{p}:
      p

law s_inj:
  for -a: N
  for -b: N
  for  e: {S{a} == S{b} : N}
  {a == b : N}

def s_inj(a, b, e):
  %e : {a == pred(_) : N}
  {==}

law two_even:
  Even<S{S{Z{}}}>

def two_even(): ESS{Z{}, EZ{{==}}, {==}}

law one_odd:
  for ev: Even<S{Z{}}>
  Emp

def one_odd(ev):
  match ev:
    case EZ{eq}:
      s_ne_z(Z{}, eq)
    case ESS{p, e, eq}:
      z_ne_s(p, s_inj(Z{}, S{p}, eq))

#|All terms check.
