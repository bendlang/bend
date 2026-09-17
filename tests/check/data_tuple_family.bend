# bend3's Data-ness reached through a TUPLE-returning type family: a
# P2(U32) contracted freely by the sigma table's join. the grade kernel
# keeps the family transparent -- P2(U32) whnfs to a reusable Sigma and
# destructures -- and the over-use of a component rides +p: P2(U32),
# licensed because the family answers Data (the reusable pair
# Sigma<&2, &2, A, _ => A> over a Data A fits it); the + scrutinee's
# fields bind Many.
# ported from bend3: (a + b) + a spends a twice, so p binds +
import Base

law P2:
  for A: Data
  Data

def P2(A): Sigma<&2, &2, A, _ => A>

law use:
  for +p: P2(U32)
  U32

def use(p):
  (a, b) = p
  (a + b + a : U32)

law main.out:
  U32

def main.out(): use((3, 4))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|10
