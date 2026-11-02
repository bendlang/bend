# EINTR on a recv must retry the read, not fail it.
import Base
import ./tcp_bytes.bend as TCPTest
import ./file_binary.bend as T

def Interrupted.pair() -> IO(Socket & Socket):
  import "./tcp_recv_interrupted.c"
  import "./tcp_recv_interrupted.js"

def Interrupted.arm(socket: Socket) -> IO(Socket):
  import "./tcp_recv_interrupted.c"
  import "./tcp_recv_interrupted.js"

def Interrupted.check(socket: Socket) -> IO(Socket):
  import "./tcp_recv_interrupted.c"
  import "./tcp_recv_interrupted.js"

def text_value(s: Socket, m: Maybe<&1, String>) -> IO(Socket):
  match m:
    case None{}: IO.die(Socket, 1, "unexpected EOF")
    case Some{t}:
      do IO<Socket>:
        T.check("text read once", String.eq(t, "aéλz"))
        return s

def text(pair: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>) -> IO(Socket):
  (s, r) = pair
  do IO<Socket>:
    m : Maybe<&1, String> <- IO.pass(Maybe<&1, String>, r)
    text_value(s, m)

def bytes_value(s: Socket, m: Maybe<&1, List<&2, U32>>) -> IO(Socket):
  match m:
    case None{}: IO.die(Socket, 1, "unexpected EOF")
    case Some{xs}:
      do IO<Socket>:
        T.check("bytes read once", T.same(xs, [97, 195, 169, 206, 187, 122]))
        return s

def bytes(pair: Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>>) -> IO(Socket):
  (s, r) = pair
  do IO<Socket>:
    m : Maybe<&1, List<&2, U32>> <- IO.pass(Maybe<&1, List<&2, U32>>, r)
    bytes_value(s, m)

def try_text(pair: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit>) -> IO(Socket):
  (s, p) = pair
  match p:
    case Ready{r}: text((s, r))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def try_bytes(pair: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>>, Unit>) -> IO(Socket):
  (s, p) = pair
  match p:
    case Ready{r}: bytes((s, r))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def send(a: Socket) -> IO(Socket):
  do IO<Socket>:
    p : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(a, "aéλz")
    TCPTest.send_go(p)

def run(pair: Socket & Socket) -> IO(Unit):
  (a, b) = pair
  do IO<Unit>:
    a : Socket <- send(a)
    b : Socket <- Interrupted.arm(b)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, String>> <- TCP.recv(b, 64)
    b : Socket <- text(r)
    b : Socket <- Interrupted.check(b)
    a : Socket <- send(a)
    b : Socket <- Interrupted.arm(b)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>> <- TCP.recv_bytes(b, 64)
    b : Socket <- bytes(r)
    b : Socket <- Interrupted.check(b)
    a : Socket <- send(a)
    b : Socket <- Interrupted.arm(b)
    p : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit> <- TCP.try_recv(b, 64, 1000)
    b : Socket <- try_text(p)
    b : Socket <- Interrupted.check(b)
    a : Socket <- send(a)
    b : Socket <- Interrupted.arm(b)
    p : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, List<&2, U32>>>, Unit> <- TCP.try_recv_bytes(b, 64, 1000)
    b : Socket <- try_bytes(p)
    b : Socket <- Interrupted.check(b)
    Socket.close(a)
    Socket.close(b)

def main() -> IO(Unit):
  do IO<Unit>:
    pair : Socket & Socket <- Interrupted.pair()
    run(pair)

#|text read once
#|bytes read once
#|text read once
#|bytes read once
