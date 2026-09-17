# io (io_shared_module_state): two foreign defs filled by ONE .js
# module share that module's state, in the interpreter exactly as in
# the compiled program. A compiled program splices every effect
# source once into one scope; before this pin the interpreter
# evaluated the module fresh per foreign def (and its `//! use`
# companions with it), so Tick.peek read a second count, frozen at 0,
# while the compiled JS answered the count Tick.bump had moved -- an
# output divergence between backends. Now the interpreter builds the
# book's one effect scope once per run, and both lanes print the
# bumped count: 1, 2, then 2 again through the other def.
import Base

law Tick.bump:
  IO(U32)

def Tick.bump():
  import "./shared_module_state.js"

law Tick.peek:
  IO(U32)

def Tick.peek():
  import "./shared_module_state.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : U32 <- Tick.bump()
    b : U32 <- Tick.bump()
    c : U32 <- Tick.peek()
    u : Unit <- IO.print(U32.show(a))
    v : Unit <- IO.print(U32.show(b))
    w : Unit <- IO.print(U32.show(c))
    return 0

#|1
#|2
#|2
