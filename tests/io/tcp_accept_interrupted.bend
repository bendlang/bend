# EINTR on an accept must retry it, not fail the accept.
import Base

def Interrupted.port(listener: Listener) -> IO(Listener & U32):
  import "./tcp_accept_interrupted.c"
  import "./tcp_accept_interrupted.js"

def Interrupted.arm(listener: Listener) -> IO(Listener):
  import "./tcp_accept_interrupted.c"
  import "./tcp_accept_interrupted.js"

def Interrupted.check(listener: Listener) -> IO(Listener):
  import "./tcp_accept_interrupted.c"
  import "./tcp_accept_interrupted.js"

def accepted(pair: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener):
  (l, r) = pair
  do IO<Listener>:
    s : Socket <- IO.pass(Socket, r)
    Socket.close(s)
    IO.print("accepted once")
    return l

def try_accepted(pair: Listener & Poll<&1, &1, Result<&1, &1, U32 & String, Socket>, Unit>) -> IO(Listener):
  (l, p) = pair
  match p:
    case Ready{r}: accepted((l, r))
    case Wait{rest}: IO.die(Listener, 1, "unexpected timeout")

def run(pair: Listener & U32) -> IO(Unit):
  (l, +port) = pair
  do IO<Unit>:
    a : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    l : Listener <- Interrupted.arm(l)
    p : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    l : Listener <- accepted(p)
    l : Listener <- Interrupted.check(l)
    b : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    l : Listener <- Interrupted.arm(l)
    q : Listener & Poll<&1, &1, Result<&1, &1, U32 & String, Socket>, Unit> <- TCP.try_accept(l, 1000)
    l : Listener <- try_accepted(q)
    l : Listener <- Interrupted.check(l)
    Socket.close(a)
    Socket.close(b)
    Listener.close(l)

def main() -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 0))
    pair : Listener & U32 <- Interrupted.port(l)
    run(pair)

#|accepted once
#|accepted once
