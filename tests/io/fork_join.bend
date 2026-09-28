# io (io_fork_join): IO.fork starts an action and answers the channel
# its value will arrive on; IO.join takes the value and closes the
# channel. Three workers sleep for different spans, so they finish in
# the order 2, 3, 1 while main joins them in the order 1, 2, 3: a
# join on a finished worker answers at once, one on a running worker
# parks main until it answers.
import Base

law work:
  for ms: U32
  for +n: U32
  IO(U32)

def work(ms, n):
  do IO<U32>:
    Unit <- IO.sleep(ms)
    Unit <- IO.print(String.append("done ", U32.show(n)))
    return n

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Chan(U32) <- IO.fork(U32, work(17, 1))
    b : Chan(U32) <- IO.fork(U32, work(1, 2))
    c : Chan(U32) <- IO.fork(U32, work(9, 3))
    x : U32 <- IO.join(U32, a)
    y : U32 <- IO.join(U32, b)
    z : U32 <- IO.join(U32, c)
    Unit <- IO.print(U32.show((x + (y + z : U32) : U32)))
    return 0

#|done 2
#|done 3
#|done 1
#|6
