# io (io_reenter_closure): a host function that calls a Bend closure
# enters the JS runtime again while an outer run awaits the host's
# value. twice applies its function outside tail position, so each
# run keeps its rest pending across the host call; the inner run must
# not clobber the outer run's state, or the outer run adds 1 to the
# inner run's 11 and prints 12 instead of 112.
import Base

law wrap:
  for g: U32 -> U32
  IO(U32 -> U32)

def wrap(g):
  import "./reenter_closure.js"

law twice:
  for f: U32 -> U32
  for x: U32
  U32

def twice(f, x):
  U32.add(f(x), 1)

law main:
  IO(U32)

def main():
  do IO<U32>:
    h : (U32 -> U32) <- wrap(y => twice(z => U32.mul(z, 2), y))
    u : Unit <- IO.print(U32.show(twice(h, 5)))
    return 0

#|112
