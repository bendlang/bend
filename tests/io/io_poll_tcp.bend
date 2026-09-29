# io (io_poll_tcp): IO.poll over a socket. An accept with no peer and a
# recv with nothing sent answer Late, cancelled with their handle back;
# polled again once the peer connects or sends, they answer Ready with
# what arrived.
import Base

# says whether p is ready or late, and gives its value
def note(-A: Type, name: String, p: IO.Poll<A>) -> IO(A):
  match p:
    case Ready{value}:
      IO.bind(Unit, A, IO.print(name ++ ": ready"), u => IO.pure(A, value))
    case Late{value}:
      IO.bind(Unit, A, IO.print(name ++ ": late"), u => IO.pure(A, value))

def listener(m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener):
  (l, r) = m
  IO.pure(Listener, l)

def socket(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Socket):
  (s, r) = m
  IO.pure(Socket, s)

def recv_go(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Socket):
  (s, r) = m
  do IO<Socket>:
    t : String <- IO.pass(String, r)
    u : Unit <- IO.print("got " ++ t)
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
    p1 : IO.Poll<(Socket & Result<&1, &1, U32 & String, String>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, String>, 0, TCP.recv(a, 16))
    q1 : Socket & Result<&1, &1, U32 & String, String> <-
      note(Socket & Result<&1, &1, U32 & String, String>, "recv, nothing sent", p1)
    a1 : Socket <- socket(q1)
    s1 : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(c, "hi")
    c1 : Socket <- send_go(s1)
    p2 : IO.Poll<(Socket & Result<&1, &1, U32 & String, String>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, String>, 1000, TCP.recv(a1, 16))
    q2 : Socket & Result<&1, &1, U32 & String, String> <-
      note(Socket & Result<&1, &1, U32 & String, String>, "recv, once sent", p2)
    a2 : Socket <- recv_go(q2)
    x  : Unit <- Socket.close(a2)
    y  : Unit <- Socket.close(c1)
    Listener.close(l2)

def main_go(b: Listener & U32) -> IO(Unit):
  (l, port) = b
  do IO<Unit>:
    p0 : IO.Poll<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      IO.poll(Listener & Result<&1, &1, U32 & String, Socket>, 0, TCP.accept(l))
    q0 : Listener & Result<&1, &1, U32 & String, Socket> <-
      note(Listener & Result<&1, &1, U32 & String, Socket>, "accept, no peer", p0)
    l1 : Listener <- listener(q0)
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    p1 : IO.Poll<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      IO.poll(Listener & Result<&1, &1, U32 & String, Socket>, 1000, TCP.accept(l1))
    p : Listener & Result<&1, &1, U32 & String, Socket> <-
      note(Listener & Result<&1, &1, U32 & String, Socket>, "accept, once connected", p1)
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

#|accept, no peer: late
#|accept, once connected: ready
#|recv, nothing sent: late
#|recv, once sent: ready
#|got hi
