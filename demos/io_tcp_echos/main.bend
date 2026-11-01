# Echo server: binds port 7777 and sends every connection back what
# it says. Each accepted socket goes to a computation of its own
# (IO.spawn) that echoes each recv until the peer closes. The accept
# loop and each handler count down a fuel of 4294967295 (connections,
# recvs), so every def here checks; in practice the server runs until
# killed. Try it:
#
#   bend demos/io_tcp_echos/main.bend -o echos && ./echos
#   nc 127.0.0.1 7777
import Base

# the move on a recv: the data sent back, or nothing: the connection
# closes at the peer's end (None{}) or on a failed recv
def echo_step(r: Result<&1, &1, U32 & String, Maybe<&1, String>>) -> Maybe<String>:
  match r:
    case Done{m}:
      m
    case Fail{e}:
      None{}

def echo_sent(m: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, next: Socket -> IO(Unit)) -> IO(Unit):
  (s, r) = m
  match r:
    case Done{u}:
      next(s)
    case Fail{e}:
      Socket.close(s)

# the move made: the data sent and the handler goes on, or the close
def echo_move(s: Socket, m: Maybe<String>, next: Socket -> IO(Unit)) -> IO(Unit):
  match m:
    case None{}:
      Socket.close(s)
    case Some{d}:
      do IO<Unit>:
        sm : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(s, d)
        echo_sent(sm, next)

def echo_back(m: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>, next: Socket -> IO(Unit)) -> IO(Unit):
  (s, r) = m
  echo_move(s, echo_step(r), next)

def echo_conn(fuel: Nat, s: Socket) -> IO(Unit):
  match fuel:
    case 0n:
      Socket.close(s)
    case 1n+fuel2:
      do IO<Unit>:
        rm : Socket & Result<&1, &1, U32 & String, Maybe<&1, String>> <- TCP.recv(s, 4096)
        echo_back(rm, s2 => echo_conn(fuel2, s2))

def serve_next(m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener):
  (l, r) = m
  do IO<Listener>:
    s : Socket <- IO.pass(Socket, r)
    IO.spawn(Unit, echo_conn(4294967295n, s))
    return l

def serve(fuel: Nat, l: Listener) -> IO(Unit):
  match fuel:
    case 0n:
      Listener.close(l)
    case 1n+fuel2:
      do IO<Unit>:
        m  : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
        l2 : Listener <- serve_next(m)
        serve(fuel2, l2)

def main() -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 7777))
    IO.print("echoing on 127.0.0.1:7777")
    serve(4294967295n, l)
