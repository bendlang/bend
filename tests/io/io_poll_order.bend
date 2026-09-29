# io (io_poll_order): a poll runs its act in place on both lanes: a poll
# that answers at once, and the print after it, come before a computation
# spawned earlier that is only runnable (JS used to requeue every poll, so
# the lanes printed in different orders).
import Base

def main.go(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Unit, IO.print("B, spawned first"))
    p : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 1))
    IO.print("A, after its poll")

def main() -> IO(Unit):
  IO.bind(Chan(U32), Unit, Chan.new(U32, 1), main.go)

#|A, after its poll
#|B, spawned first
