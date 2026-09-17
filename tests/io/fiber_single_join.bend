# io (io_fiber_single_join): bend3's Task<A> was a LINEAR handle, so a
# second join was refused by linearity. bend's fork answers a Chan,
# a Data handle any code may copy, so the second join is well typed
# and fails at run time instead: IO.join closed the channel after the
# first value, the second recv answers None, and IO.join dies with
# its message, exit 1.
import Base

law main.go:
  for t: Chan(U32)
  IO(U32)

def main.go(t):
  +c = t
  do IO<U32>:
    a : U32 <- IO.join(U32, c)
    b : U32 <- IO.join(U32, c)
    return (a + b : U32)

law main:
  IO(U32)

def main():
  IO.bind(Chan(U32), U32, IO.fork(U32, IO.pure(U32, 1)), main.go)

#|IO.join: the channel was closed
#|exit 1
