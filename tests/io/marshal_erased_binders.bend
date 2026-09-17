# io (io_marshal_erased_binders): erased BINDERS vanish at the effect
# seam, on both sides of a call -- the def-parameter sibling of
# io_marshal_erased_fields (which pins erased ctor FIELDS). An erased
# effect parameter never reaches the .js body: it receives exactly
# the live arguments (scale takes one, not two). A callback at a
# function type with an erased binder crosses at its LIVE arity: the
# emitter drops erased layers, so the effect calls it with live
# arguments only. Gutting either law shifts an argument slot and
# this program's output moves. Both lanes must print
# byte-identically.
import Base

law scale:
  for -w: Nat
  for  x: U32
  IO(U32)

def scale(w, x):
  import "./marshal_erased_binders.js"

law apply7:
  for f: (@-n: Nat -> @x: U32 -> U32)
  IO(U32)

def apply7(f):
  import "./marshal_erased_binders.js"

law bump:
  for -n: Nat
  for  x: U32
  U32

def bump(n, x):
  U32.add(x, 1)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    a : U32 <- scale(3n, 21)
    u : Unit <- IO.print(U32.show(a))
    b : U32 <- apply7(bump)
    IO.print(U32.show(b))

#|121
#|8
