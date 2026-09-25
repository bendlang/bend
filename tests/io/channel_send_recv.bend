# io pin (io_channel_send_recv): bend3's Chan<A> was a plain copyable
# id, send/recv/close wrappers over the Chan* Op rows. bend dropped
# the channel protocol whole -- fibers and channels wait for V2 --
# so Chan<A> respells as the Sender & Receiver pair and the do block
# dies on the missing types.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    c : Sender<U32> & Receiver<U32> <- Chan.new(U32, 8)
    s : Result<U32, Sender<U32>> <- Chan.send(U32, c, 42)
    r : Result<Unit, U32 & Receiver<U32>> <- Chan.recv(U32, c)
    x : Unit <- Chan.close(U32, c)
    return 0

#|Error:
#|- message  : a declared datatype (unknown: Sender)
#|Location: main
#|12 |   do IO<U32>:
#|13>|     c : Sender<U32> & Receiver<U32> <- Chan.new(U32, 8)
#|   |         ^^^^^^^^^^
#|14 |     s : Result<U32, Sender<U32>> <- Chan.send(U32, c, 42)
#|exit 1
