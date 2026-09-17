# io (io_fiber_boxed_join): bend3's boxed twin of hello -- a forked
# computation answers a String, a boxed value, which rides the
# channel to the join and prints.
import Base

law child:
  IO(String)

def child():
  IO.pure(String, "boxed")

law main:
  IO(U32)

def main():
  do IO<U32>:
    t : Chan(String) <- IO.fork(String, child())
    s : String <- IO.join(String, t)
    x : Unit <- IO.print(s)
    return 0

#|boxed
