# io (io_marshal_u32_integer): the seam has ONE value model -- a U32
# is the effect's JS number, trusted inbound in every lane. This
# golden pinned the dead two-model refusal ('an unsigned 32-bit U32
# answer'): the interpreter coerced then refused numbers the compiled
# JS ran raw, and one program printed 'eq eq 4294967293' interpreted
# and 'ne ne -' compiled. With one model that divergence class cannot
# exist; the hazard is UNIFORM and observable: the boundary integers
# (0, 4294967295) cross exact, a fractional answer lands raw, and
# U32.show reads it through the word ops -- both lanes print the same
# three lines byte-identically, which is the law this golden guards.
import Base

law zero:
  IO(U32)

def zero():
  import "./marshal_u32_integer.js"

law full:
  IO(U32)

def full():
  import "./marshal_u32_integer.js"

law frac:
  IO(U32)

def frac():
  import "./marshal_u32_integer.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : U32 <- zero()
    b : U32 <- full()
    c : U32 <- frac()
    u : Unit <- IO.print(U32.show(a))
    v : Unit <- IO.print(U32.show(b))
    w : Unit <- IO.print(U32.show(c))
    return 0

#|0
#|4294967295
#|4
