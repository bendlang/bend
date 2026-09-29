# io (io_poll_cancel): a cancelled effect on a socket answers (handle,
# Fail{ECANCELED}), so the handle comes back to be closed: an accept with
# no peer and a recv with nothing sent. A composite act goes on after a
# cancel with the cancelled answer: a recv then f answers Ready with f run
# on the value that came in time, or Late with f run on None.
import Base

def fail_code(-A: Type, r: Result<&1, &1, U32 & String, A>) -> String:
  match r:
    case Done{x}:
      "done"
    case Fail{(code, message)}:
      "fail: " ++ message

def value(-A: Type, p: IO.Poll<A>) -> IO(A):
  match p:
    case Ready{value}:
      IO.pure(A, value)
    case Late{value}:
      IO.pure(A, value)

def gone_s(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    Unit <- IO.print("recv cancelled: " ++ fail_code(String, r))
    Socket.close(s)

def gone_l(m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener):
  (l, r) = m
  do IO<Listener>:
    Unit <- IO.print("accept cancelled: " ++ fail_code(Socket, r))
    return l

def talk(c: Socket, p: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, ar) = p
  do IO<Unit>:
    a : Socket <- IO.pass(Socket, ar)
    r : IO.Poll<(Socket & Result<&1, &1, U32 & String, String>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, String>, 20, TCP.recv(a, 16))
    m : Socket & Result<&1, &1, U32 & String, String> <-
      value(Socket & Result<&1, &1, U32 & String, String>, r)
    Unit <- gone_s(m)
    Unit <- Socket.close(c)
    Listener.close(l)

def sockets(b: Listener & U32) -> IO(Unit):
  (l, port) = b
  do IO<Unit>:
    p0 : IO.Poll<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      IO.poll(Listener & Result<&1, &1, U32 & String, Socket>, 0, TCP.accept(l))
    q0 : Listener & Result<&1, &1, U32 & String, Socket> <-
      value(Listener & Result<&1, &1, U32 & String, Socket>, p0)
    l1 : Listener <- gone_l(q0)
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    p : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l1)
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
def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      U32.show(value)

def then(m: Maybe<&1, U32>) -> IO(String):
  IO.bind(Unit, String, IO.print("  then ran"), u => IO.pure(String, got(m)))

def tell(name: String, p: IO.Poll<String>) -> IO(Unit):
  match p:
    case Ready{value}:
      IO.print(name ++ ": ready " ++ value)
    case Late{value}:
      IO.print(name ++ ": late " ++ value)

def later(ch: Chan(U32)) -> IO(Bool):
  IO.bind(Unit, Bool, IO.sleep(20), u => Chan.send(U32, ch, 4))

def composed(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Bool, later(ch))
    p1 : IO.Poll<String> <- IO.poll(String, 1000,
      IO.bind(Maybe<&1, U32>, String, Chan.recv(U32, ch), then))
    Unit <- tell("recv then f, sent in time", p1)
    p2 : IO.Poll<String> <- IO.poll(String, 0,
      IO.bind(Maybe<&1, U32>, String, Chan.recv(U32, ch), then))
    tell("recv then f, nothing sent", p2)

def main() -> IO(Unit):
  do IO<Unit>:
    c : Chan(U32) <- Chan.new(U32, 0)
    Unit <- composed(c)
    b : Listener & U32 <- tcp_listen_any(32n, 19987)
    sockets(b)

#|  then ran
#|recv then f, sent in time: ready 4
#|  then ran
#|recv then f, nothing sent: late none
#|accept cancelled: fail: Operation canceled
#|recv cancelled: fail: Operation canceled
