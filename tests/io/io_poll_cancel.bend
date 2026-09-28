# io (io_poll_cancel): IO.cancel on a socket's effect answers (handle,
# Fail{ECANCELED}), so the handle comes back to be closed: an accept with
# no peer and a recv with nothing sent. A rest composed with more work,
# IO.poll(IO.resume(rest) then f), holds f too: resumed, f runs once the
# value comes; cancelled, f runs on the cancelled answer.
import Base

def fail_code(-A: Type, r: Result<&1, &1, U32 & String, A>) -> String:
  match r:
    case Done{x}:
      "done"
    case Fail{(code, message)}:
      String.append("fail: ", message)

def gone_s(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    Unit <- IO.print(String.append("recv cancelled: ", fail_code(String, r)))
    Socket.close(s)

def gone_l(m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener):
  (l, r) = m
  do IO<Listener>:
    Unit <- IO.print(String.append("accept cancelled: ", fail_code(Socket, r)))
    return l

def recv_or_cancel(s: IO.Step<(Socket & Result<&1, &1, U32 & String, String>)>) ->
  IO(Socket & Result<&1, &1, U32 & String, String>):
  match s:
    case Ready{value}:
      IO.pure(Socket & Result<&1, &1, U32 & String, String>, value)
    case Wait{rest}:
      IO.cancel(Socket & Result<&1, &1, U32 & String, String>, rest)

def accept_or_cancel(s: IO.Step<(Listener & Result<&1, &1, U32 & String, Socket>)>) ->
  IO(Listener & Result<&1, &1, U32 & String, Socket>):
  match s:
    case Ready{value}:
      IO.pure(Listener & Result<&1, &1, U32 & String, Socket>, value)
    case Wait{rest}:
      IO.cancel(Listener & Result<&1, &1, U32 & String, Socket>, rest)

def talk(c: Socket, p: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, ar) = p
  do IO<Unit>:
    a : Socket <- IO.pass(Socket, ar)
    r : IO.Step<(Socket & Result<&1, &1, U32 & String, String>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, String>, 20, TCP.recv(a, 16))
    m : Socket & Result<&1, &1, U32 & String, String> <- recv_or_cancel(r)
    Unit <- gone_s(m)
    Unit <- Socket.close(c)
    Listener.close(l)

def sockets(b: Listener & U32) -> IO(Unit):
  (l, port) = b
  do IO<Unit>:
    p0 : IO.Step<(Listener & Result<&1, &1, U32 & String, Socket>)> <-
      IO.poll(Listener & Result<&1, &1, U32 & String, Socket>, 0, TCP.accept(l))
    q0 : Listener & Result<&1, &1, U32 & String, Socket> <- accept_or_cancel(p0)
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

def more(-A: Type, s: IO.Step<Maybe<&1, U32>>, f: Maybe<&1, U32> -> IO(A)) ->
  IO(IO.Step<A>):
  match s:
    case Ready{value}:
      IO.bind(A, IO.Step<A>, f(value), x => IO.pure(IO.Step<A>, Ready{x}))
    case Wait{rest}:
      IO.poll(A, 0, IO.bind(Maybe<&1, U32>, A, IO.resume(Maybe<&1, U32>, rest), f))

def finish(s: IO.Step<String>, cancel: Bool) -> IO(String):
  match s:
    case Ready{value}:
      IO.pure(String, value)
    case Wait{rest}:
      match cancel:
        case True{}:
          IO.cancel(String, rest)
        case False{}:
          IO.resume(String, rest)

def composed(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    r1 : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    r2 : IO.Step<String> <- more(String, r1, then)
    Unit <- IO.spawn(Bool, Chan.send(U32, ch, 4))
    x : String <- finish(r2, False{})
    Unit <- IO.print(String.append("resumed: ", x))
    s1 : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    s2 : IO.Step<String> <- more(String, s1, then)
    y : String <- finish(s2, True{})
    Unit <- IO.print(String.append("cancelled: ", y))
    return Unit{}

def main() -> IO(Unit):
  do IO<Unit>:
    c : Chan(U32) <- Chan.new(U32, 0)
    Unit <- composed(c)
    b : Listener & U32 <- tcp_listen_any(32n, 19987)
    sockets(b)

#|  then ran
#|resumed: 4
#|  then ran
#|cancelled: none
#|accept cancelled: fail: Operation canceled
#|recv cancelled: fail: Operation canceled
