# io (io_marshal_closure): a function crosses the effect seam as a
# curried JS callback -- the compiled closure form is one-argument
# functions run to completion, so the effect applies it one argument
# at a time, any number of times, and a function it answers is
# applied by the program the same way. The pin drives all three
# doors: a two-argument callback the effect calls twice (123), a
# callback riding a ctor field out (42), and a function answer
# riding a ctor field in, applied by the program (107). Both lanes
# run the same compiled text and print byte-identically.
import Base

law fold2:
  for f: U32 -> U32 -> U32
  IO(U32)

def fold2(f):
  import "./marshal_closure.js"

law pick_fn:
  for m: Maybe<&1, (U32 -> U32)>
  IO(U32)

def pick_fn(m):
  import "./marshal_closure.js"

law stepper:
  IO(Maybe<&1, (U32 -> U32)>)

def stepper():
  import "./marshal_closure.js"

law app7:
  for m: Maybe<&1, (U32 -> U32)>
  U32

def app7(m):
  match m:
    case None{}:
      0
    case Some{g}:
      g(7)

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : U32 <- fold2(x => y => U32.add(U32.mul(x, 10), y))
    u : Unit <- IO.print(U32.show(a))
    b : U32 <- pick_fn(Some{x => U32.add(x, 2)})
    v : Unit <- IO.print(U32.show(b))
    m : Maybe<&1, (U32 -> U32)> <- stepper()
    w : Unit <- IO.print(U32.show(app7(m)))
    return 0

#|123
#|42
#|107
