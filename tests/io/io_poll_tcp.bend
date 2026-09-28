# io (io_poll_tcp): IO.poll over a socket. An accept with no peer and a
# recv with nothing sent answer Wait; polled again once the peer connects
# or sends, the rest answers Ready with what arrived.
import Base

def tell(-A: Type, name: String, s: IO.Step<A>) -> IO(IO.Step<A>):
  match s:
    case Ready{value}:
      IO.bind(Unit, IO.Step<A>, IO.print(String.append(name, ": ready")),
        u => IO.pure(IO.Step<A>, Ready{value}))
    case Wait{rest}:
      IO.bind(Unit, IO.Step<A>, IO.print(String.append(name, ": wait")),
        u => IO.pure(IO.Step<A>, Wait{rest}))

def get(-A: Type, s: IO.Step<A>) -> IO(A):
  match s:
    case Ready{value}:
      IO.pure(A, value)
    case Wait{rest}:
      IO.resume(A, rest)

def recv_go(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Socket):
  (s, r) = m
  do IO<Socket>:
    t : String <- IO.pass(String, r)
    u : Unit <- IO.print(String.append("got ", t))
    return s

def send_go(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Socket):
  (s, r) = m
  do IO<Socket>:
    u : Unit <- IO.pass(Unit, r)
    return s

def talk(c: Socket, p: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l2, ar) = p
  do IO<Unit>:
    a  : Socket <- IO.pass(Socket, ar)
    p1 : IO.Step<(Socket & Result<&1, &1, U32 & String, String>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, String>, 0, TCP.recv(a, 16))
    q1 : IO.Step<(Socket & Result<&1, &1, U32 & String, String>)> <-
      tell(Socket & Result<&1, &1, U32 & String, String>, "recv, nothing sent", p1)
    s1 : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(c, "hi")
    c1 : Socket <- send_go(s1)
    Unit <- IO.sleep(50)
    p2 : IO.Step<(Socket & Result<&1, &1, U32 & String, String>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, String>, 0,
        get(Socket & Result<&1, &1, U32 & String, String>, q1))
    q2 : IO.Step<(Socket & Result<&1, &1, U32 & String, String>)> <-
      tell(Socket & Result<&1, &1, U32 & String, String>, "rest, once sent", p2)
    m  : Socket & Result<&1, &1, U32 & String, String> <-
      get(Socket & Result<&1, &1, U32 & String, String>, q2)
    a2 : Socket <- recv_go(m)
    x  : Unit <- Socket.close(a2)
    y  : Unit <- Socket.close(c1)
    Listener.close(l2)

def main_go(b: Listener & U32) -> IO(Unit):
  (l, port) = b
  do IO<Unit>:
    p0 : IO.Step<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      IO.poll(Listener & Result<&1, &1, U32 & String, Socket>, 0, TCP.accept(l))
    q0 : IO.Step<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      tell(Listener & Result<&1, &1, U32 & String, Socket>, "accept, no peer", p0)
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    Unit <- IO.sleep(50)
    p1 : IO.Step<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      IO.poll(Listener & Result<&1, &1, U32 & String, Socket>, 0,
        get(Listener & Result<&1, &1, U32 & String, Socket>, q0))
    q1 : IO.Step<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      tell(Listener & Result<&1, &1, U32 & String, Socket>, "rest, once connected", p1)
    p : Listener & Result<&1, &1, U32 & String, Socket> <-
      get(Listener & Result<&1, &1, U32 & String, Socket>, q1)
    talk(c, p)

def tcp_retry(port: U32, r: Result<&1, &1, U32 & String, Listener>, rest: IO(Listener & U32)) ->
  IO(Listener & U32):
  match r:
    case Done{l}:
      IO.pure(Listener & U32, (l, port))
    case Fail{e}:
      rest

def tcp_listen_any(tries: Nat, +port: U32) -> IO(Listener & U32):
  match tries:
    case 0n:
      IO.die(Listener & U32, 1, "no free tcp port")
    case 1n+t:
      rest = tcp_listen_any(t, (port + 1 : U32))
      do IO<Listener & U32>:
        r : Result<&1, &1, U32 & String, Listener> <- TCP.listen("127.0.0.1", port)
        tcp_retry(port, r, rest)

def main() -> IO(Unit):
  do IO<Unit>:
    b : Listener & U32 <- tcp_listen_any(32n, 19957)
    main_go(b)

#|accept, no peer: wait
#|rest, once connected: ready
#|recv, nothing sent: wait
#|rest, once sent: ready
#|got hi
