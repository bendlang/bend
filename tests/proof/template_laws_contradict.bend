# ~ laws no le satisfies, r and ir, prove Empty: bend2 checks bad, as a
# template holds at every argument, but no models of le, r and ir hold
# together, so --verdict leaves it out of scope rather than give the
# kernel a closed def of type Empty
import Base

def absurd_ft(e: {False{} == True{} : Bool}) -> Empty:
  %e : Bool.pick(Type, _, Empty, Unit)
  Unit{}

def bad(~A: Data, ~le: A -> A -> Bool, ~r: @x: A -> {le(x, x) == True{} : Bool}, ~ir: @x: A -> {le(x, x) == False{} : Bool}, +a: A) -> Empty:
  absurd_ft(Equal.trans(Bool, False{}, le(a, a), True{}, Equal.sym(Bool, le(a, a), False{}, ir(a)), r(a)))

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
