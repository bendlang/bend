# io (io_marshal_nat_bigint): the seam has ONE value model -- a Nat
# is the effect's BigInt, trusted inbound in every lane. This golden
# pinned the dead two-model refusal ('a non-negative Nat answer'):
# the interpreter refused -3n where compiled JS ran the raw negative
# on. Now both lanes run the same text, so the hazard is UNIFORM and
# observable: the boundary answers (0, 5) land canonically (zero,
# succ), and a negative BigInt lands raw and matches as Succ -- both
# lanes print the same three tags byte-identically, which is the law
# this golden guards.
import Base

law zero:
  IO(Nat)

def zero():
  import "./marshal_nat_bigint.js"

law five:
  IO(Nat)

def five():
  import "./marshal_nat_bigint.js"

law neg:
  IO(Nat)

def neg():
  import "./marshal_nat_bigint.js"

law tag_of:
  for n: Nat
  String

def tag_of(n):
  match n:
    case 0n:
      "zero"
    case 1n+p:
      "succ"

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Nat <- zero()
    b : Nat <- five()
    c : Nat <- neg()
    u : Unit <- IO.print(tag_of(a))
    v : Unit <- IO.print(tag_of(b))
    w : Unit <- IO.print(tag_of(c))
    return 0

#|zero
#|succ
#|succ
