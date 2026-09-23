# using does: a def that names the module's @unsafe def relies on unsafe,
# and the verdict lists it (the module's own def is not this file's claim)
import Base
import ./unsafe_lib.bend as L

def innocent() -> Empty:
  L.boom()

def keep(n: Nat) -> Nat:
  L.safe(n)

#|All terms check, but 1 def relies on unsafe or foreign code:
#|- innocent
#|exit 1
