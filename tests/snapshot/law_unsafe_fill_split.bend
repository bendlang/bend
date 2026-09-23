# a law whose statement puts a + binder over a Type-kinded domain checks
# only because its @unsafe fill, in the importing file, marks the law's
# record before validation reads it (the law's file alone is rejected:
# expected Data)
import Base
import ./law-split/laws.bend as L

@unsafe
def L.dup(x):
  0

#|All terms check, but 1 def relies on unsafe or foreign code:
#|- law-split/laws.dup
