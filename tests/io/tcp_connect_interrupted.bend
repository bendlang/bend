# EINTR on a connect must wait for the connect to finish, not fail it.
import Base
import ./tcp_bytes.bend as TCPTest
import ./file_binary.bend as T

def Interrupted.port(listener: Listener) -> IO(Listener & U32):
  import "./tcp_connect_interrupted.c"
  import "./tcp_connect_interrupted.js"

def Interrupted.arm(listener: Listener) -> IO(Listener):
  import "./tcp_connect_interrupted.c"
  import "./tcp_connect_interrupted.js"

def Interrupted.check(listener: Listener) -> IO(Listener):
  import "./tcp_connect_interrupted.c"
  import "./tcp_connect_interrupted.js"

def got_value(s: Socket, m: Maybe<&1, String>) -> IO(Socket):
  match m:
    case None{}: IO.die(Socket, 1, "unexpected EOF")
    case Some{t}:
      do IO<Socket>:
        T.check("connected once", String.eq(t, "hi"))
        return s

def got(pair: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>) -> IO(Socket):
  (s, r) = pair
  do IO<Socket>:
    m : Maybe<&1, String> <- IO.pass(Maybe<&1, String>, r)
    got_value(s, m)

def accepted(pair: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener & Socket):
  (l, r) = pair
  do IO<Listener & Socket>:
    s : Socket <- IO.pass(Socket, r)
    return (l, s)

def talk(c: Socket, ls: Listener & Socket) -> IO(Unit):
  (l, s) = ls
  do IO<Unit>:
    p : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(c, "hi")
    c : Socket <- TCPTest.send_go(p)
    r : Socket & Result<&1, &1, U32 & String, Maybe<&1, String>> <- TCP.recv(s, 64)
    s : Socket <- got(r)
    l : Listener <- Interrupted.check(l)
    Socket.close(c)
    Socket.close(s)
    Listener.close(l)

def run(pair: Listener & U32) -> IO(Unit):
  (l, +port) = pair
  do IO<Unit>:
    l : Listener <- Interrupted.arm(l)
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    p : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    ls : Listener & Socket <- accepted(p)
    talk(c, ls)

def main() -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 0))
    pair : Listener & U32 <- Interrupted.port(l)
    run(pair)

#|connected once
