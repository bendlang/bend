# an LE compare meets the class an EQ compare built: {==} proves A == B,
# which links their cells, and x => x then checks A against B in LE.
# both are shared graphs, each level t -> t of the level below, so
# walking the 16 levels as a tree would take 2^16 steps. the class check
# runs in either mode, since EQ implies LE; when it ran in EQ alone, LE
# walked the tree. the separate fa/fb make the rigid pass fail; 16, not
# more, because BendTT doesn't share cells yet, so --verdict doubles per
# level (1 s at 16, 21 s at 20) and soon passes the safe gate's 30 s (#1555)
import Base

def fa(-t: Type) -> Type:
  t -> t

def fb(-t: Type) -> Type:
  t -> t

def P(-X: Type) -> Type:
  -a0 = X
  -a1 = fa(a0)
  -a2 = fa(a1)
  -a3 = fa(a2)
  -a4 = fa(a3)
  -a5 = fa(a4)
  -a6 = fa(a5)
  -a7 = fa(a6)
  -a8 = fa(a7)
  -a9 = fa(a8)
  -a10 = fa(a9)
  -a11 = fa(a10)
  -a12 = fa(a11)
  -a13 = fa(a12)
  -a14 = fa(a13)
  -a15 = fa(a14)
  -b0 = X
  -b1 = fb(b0)
  -b2 = fb(b1)
  -b3 = fb(b2)
  -b4 = fb(b3)
  -b5 = fb(b4)
  -b6 = fb(b5)
  -b7 = fb(b6)
  -b8 = fb(b7)
  -b9 = fb(b8)
  -b10 = fb(b9)
  -b11 = fb(b10)
  -b12 = fb(b11)
  -b13 = fb(b12)
  -b14 = fb(b13)
  -b15 = fb(b14)
  -A = fa(a15)
  -B = fb(b15)
  {A == B : Type} & (A -> B)

def p(-X: Type) -> P(X):
  ({==}, x => x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
