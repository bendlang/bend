# theorems: length-append over a local list -- structural induction on
# one ADT proving an equation whose carrier is another (N).
# ported from bend3: local Nat/Lst renamed off base's ctor namespace;
# the IH rewrite carries its explicit motive
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
      %len_app(t, ys) : {S{len(app(t, ys))} == S{_} : N}
      {==}

law main:
  {len(app(LCon{1, LNil{}}, LCon{2, LCon{3, LNil{}}})) == S{S{S{Z{}}}} : N}

def main(): len_app(LCon{1, LNil{}}, LCon{2, LCon{3, LNil{}}})

#|{==}
