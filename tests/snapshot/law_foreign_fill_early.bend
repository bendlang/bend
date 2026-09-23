# a law filled by a foreign def: the fill's import lands on the law's own
# record before validation, so live code between the law and its fill may
# use it (checked alone, the law's part is rejected: an unfilled law)
import Base

law f:
  IO(Unit)

def g() -> IO(Unit):
  f

def f():
  import "./law_fill_eff.js"

#|All terms check, but 2 defs rely on unsafe or foreign code:
#|- f
#|- g
