# io (io_fiber_fork_join): bend3's fiber protocol on bend's surface:
# a fork of a sleep, its join, a detached spawn. There is no race:
# a race is a channel two forks send to, in user code.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    t : Chan(Unit) <- IO.fork(Unit, IO.sleep(1))
    a : Unit <- IO.join(Unit, t)
    u : Unit <- IO.spawn(Unit, IO.pure(Unit, Unit{}))
    b : Unit <- IO.print("joined")
    return 9

#|joined
