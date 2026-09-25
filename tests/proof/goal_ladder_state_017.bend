# goal ladder, len_app cons-arm state 0: both sides step under S.
# ported from bend3: the ladder rides the ported bend development, so
# the pinned page is bend's own goal at the same proof state
import Base

type N is Data:
  Z{}
  S{p: N}

type Lst is Data:
  LNil{}
  LCon{h: U32, t: Lst}

law add:
  for a: N
  for b: N
  N

def add(a, b):
  match a:
    case Z{}:
      b
    case S{p}:
      S{add(p, b)}

law len:
  for xs: Lst
  N

def len(xs):
  match xs:
    case LNil{}:
      Z{}
    case LCon{h, t}:
      S{len(t)}

law app:
  for xs: Lst
  for ys: Lst
  Lst

def app(xs, ys):
  match xs:
    case LNil{}:
      ys
    case LCon{h, t}:
      LCon{h, app(t, ys)}

law len_app:
  for xs: Lst
  for ys: Lst
  {len(app(xs, ys)) == add(len(xs), len(ys)) : N}

def len_app(xs, ys):
  match xs:
    case LNil{}:
      {==}
    case LCon{h, t}:
      Type

#|Error:
#|- expected : {S{len(app(t, ys))} == S{add(len(t), len(ys))} : N}
#|- observed : Type
#|Context:
#|- h  : U32
#|- t  : Lst
#|- ys : Lst
#|Location: len_app
#|58 |     case LCon{h, t}:
#|59>|       Type
#|   |       ^^^^
#|60 |
#|exit 1
