# EINTR before and after a short send must preserve the unsent offset.
import Base
import ./tcp_bytes.bend as TCPTest
import ./file_binary.bend as T

def Interrupted.pair() -> IO(Socket & Socket):
  import "./tcp_send_interrupted.c"
  import "./tcp_send_interrupted.js"

def Interrupted.arm(socket: Socket) -> IO(Socket):
  import "./tcp_send_interrupted.c"
  import "./tcp_send_interrupted.js"

def Interrupted.check(socket: Socket) -> IO(Socket):
  import "./tcp_send_interrupted.c"
  import "./tcp_send_interrupted.js"

def ready(pair: Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, List<&2, U32>>) -> IO(Socket):
  (s, r) = pair
  match r:
    case Ready{x}: TCPTest.send_go((s, x))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def received_value(s: Socket, m: Maybe<&1, List<&2, U32>>, want: List<&2, U32>) -> IO(Socket):
  match m:
    case None{}: IO.die(Socket, 1, "unexpected EOF")
    case Some{xs}:
      do IO<Socket>:
        T.check("sent exactly once", T.same(xs, want))
        return s

def received(pair: Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>>, want: List<&2, U32>) -> IO(Socket):
  (s, r) = pair
  do IO<Socket>:
    m : Maybe<&1, List<&2, U32>> <- IO.pass(Maybe<&1, List<&2, U32>>, r)
    received_value(s, m, want)

def run(pair: Socket & Socket) -> IO(Unit):
  (a, b) = pair
  do IO<Unit>:
    a : Socket <- Interrupted.arm(a)
    p : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(a, "aéλz")
    a : Socket <- TCPTest.send_go(p)
    a : Socket <- Interrupted.check(a)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>> <- TCP.recv_bytes(b, 64)
    b : Socket <- received(r, [97, 195, 169, 206, 187, 122])
    a : Socket <- Interrupted.arm(a)
    p : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send_bytes(a, [97, 195, 169, 206, 187, 122])
    a : Socket <- TCPTest.send_go(p)
    a : Socket <- Interrupted.check(a)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>> <- TCP.recv_bytes(b, 64)
    b : Socket <- received(r, [97, 195, 169, 206, 187, 122])
    a : Socket <- Interrupted.arm(a)
    p : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, List<&2, U32>> <- TCP.try_send(a, "aéλz", 1000)
    a : Socket <- ready(p)
    a : Socket <- Interrupted.check(a)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>> <- TCP.recv_bytes(b, 64)
    b : Socket <- received(r, [97, 195, 169, 206, 187, 122])
    a : Socket <- Interrupted.arm(a)
    p : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, List<&2, U32>> <- TCP.try_send_bytes(a, [97, 195, 169, 206, 187, 122], 1000)
    a : Socket <- ready(p)
    a : Socket <- Interrupted.check(a)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>> <- TCP.recv_bytes(b, 64)
    b : Socket <- received(r, [97, 195, 169, 206, 187, 122])
    Socket.close(a)
    Socket.close(b)

def main() -> IO(Unit):
  do IO<Unit>:
    pair : Socket & Socket <- Interrupted.pair()
    run(pair)

#|sent exactly once
#|sent exactly once
#|sent exactly once
#|sent exactly once
