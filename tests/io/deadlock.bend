# io (io_deadlock): a recv on a channel nobody will ever send to, with
# no other computation, timer or pending effect that could wake it,
# is a deadlock: the loop reports it on stderr and exits 1 instead of
# hanging (Go's "all goroutines are asleep").
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    c : Chan(U32) <- Chan.new(U32, 0)
    Unit <- IO.print("waiting")
    got : Maybe<&1, U32> <- Chan.recv(U32, c)
    return 0

#|waiting
#|bend: deadlock: every computation waits on a channel
#|exit 1
