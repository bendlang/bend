# Python-shaped headers, nested matches, and `{E : T}` annotating a
# computed scrutinee's type
# ported from bend3: chars ride a Bool payload and words become ctor
# nats (bend has no number patterns); the literal-plus-default rows
# live in a helper def and the computed decision folds through band
# (an applied match-lambda is a banned form)
type Bl is Data:
  T{}
  F{}

type Ch is Data:
  Ch{c: Bl}

type Lst<-A: Type> is Data:
  Nl{}
  Cs{head: Ch, tail: Lst<A>}

type W is Data:
  Z{}
  S{p: W}

law neg:
  for b: Bl
  Bl

def neg(b):
  match b:
    case T{}:
      F{}
    case F{}:
      T{}

law beq:
  for a: Bl
  for b: Bl
  Bl

def beq(a, b):
  match a:
    case T{}:
      b
    case F{}:
      neg(b)

law band:
  for a: Bl
  for b: Bl
  Bl

def band(a, b):
  match a:
    case T{}:
      b
    case F{}:
      F{}

law str_eq:
  for a: Lst<Ch>
  for b: Lst<Ch>
  Bl

def str_eq(a, b):
  match a:
    case Nl{}:
      match b:
        case Nl{}:
          T{}
        case bb:
          F{}
    case Cs{Ch{cx}, xs}:
      match b:
        case Nl{}:
          F{}
        case Cs{Ch{cy}, ys}:
          band(beq(cx, cy), str_eq(xs, ys))

law str_len:
  for s: Lst<Ch>
  W

def str_len(s):
  match s:
    case Nl{}:
      Z{}
    case Cs{c, cs}:
      S{str_len(cs)}

law main:
  for n: W
  W

def main(n):
  match n:
    case Z{}:
      S{Z{}}
    case k:
      k

#|\{Z: S{Z{}}; (n => n)}
