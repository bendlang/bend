# bend3's phantom-param narrowing demanded every TYPE argument of a
# saturated datatype be Data at a copy site, rejecting use(s) + use(s)
# over Box(Wrap(U32 -> U32)). the grade kernel reads declared kinds
# only: Tag2 and Wrap2 declare Data whatever their phantom -T: Type is
# instantiated with, so Box4<Wrap2<(U32 -> U32)>> forms at Box4's Data
# bound, +s is licensed and the double use answers 2 -- the phantom
# closure never poisons.
# ported from bend3: ctor names bare and unique; the nested matches
# route through helper defs, declared first (names resolve upward)
import Base

type Tag2<-T: Type> is Data:
  MkTag2{}
type Wrap2<-T: Type> is Data:
  MkWrap2{g: Tag2<T>}
type Box4<-T: Data> is Data:
  MkBox4{v: T}

law use.fin:
  for g: Tag2<(U32 -> U32)>
  U32

def use.fin(g):
  match g:
    case MkTag2{}:
      1

law use.go:
  for w: Wrap2<(U32 -> U32)>
  U32

def use.go(w):
  match w:
    case MkWrap2{g}:
      use.fin(g)

law use:
  for x: Box4<Wrap2<(U32 -> U32)>>
  U32

def use(x):
  match x:
    case MkBox4{w}:
      use.go(w)

law main:
  U32

def main():
  +s = {MkBox4{MkWrap2{MkTag2{}}} : Box4<Wrap2<(U32 -> U32)>>}
  (use(s) + use(s) : U32)

#|2
