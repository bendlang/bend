# io (io_marshal_deep_value): a value of ANY depth crosses the effect
# seam. Nothing marshals -- the interpreter runs the compiled JS, so
# a 50000-element list is one flat JS structure handed to the effect
# and back (the dead interp-side marshalers once died on a raw
# RangeError past ~13k elements, and went quadratic handing a deep
# list out). The round trip rides 4x past that old threshold, in and
# out, and both lanes print the same sum byte-identically.
import Base

law list_new:
  for k: U32
  IO(List<&2, U32>)

def list_new(k):
  import "./marshal_deep_value.js"

law list_sum:
  for xs: List<&2, U32>
  IO(U32)

def list_sum(xs):
  import "./marshal_deep_value.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    xs : List<&2, U32> <- list_new(50000)
    s  : U32 <- list_sum(xs)
    u  : Unit <- IO.print(U32.show(s))
    return 0

#|6367960
