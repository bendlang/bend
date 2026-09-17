# io (io_marshal_proof_null): a proof crosses the effect seam as null
# -- proofs compile to null, so the effect sees exactly what the
# compiled body sees (7, not 8), and a null answer at an equation
# type IS the working evidence: the rewrite it fires prints 9. The
# interpreter runs the compiled JS itself, so both lanes print the
# same lines byte-identically: the old interp-side refusal of a live
# proof argument cannot exist with one value model.
import Base

law keep:
  for e: {0 == 0 : U32}
  IO(U32)

def keep(e):
  import "./marshal_proof_null.js"

law give:
  IO({0 == 0 : U32})

def give():
  import "./marshal_proof_null.js"

law fire:
  for e: {0 == 0 : U32}
  U32

def fire(e):
  %e : U32; 9

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : U32 <- keep({==})
    u : Unit <- IO.print(U32.show(a))
    p : {0 == 0 : U32} <- give()
    v : Unit <- IO.print(U32.show(fire(p)))
    return 0

#|7
#|9
