# io (io_poll_foreign): a foreign effect declared pollable as
# guide/EFFECTS.md says (its socket first, (socket, Result) back, IO_IN |
# IO_HAND in C, { fd: "in" } in JS) is held by IO.poll when nothing is
# sent, and IO.cancel hands its socket back (Fail{ECANCELED}) to be closed;
# once a byte is sent, the poll answers it.
import Base

# one byte from sock, or 256 at the peer's close
def recv1(sock: Socket) -> IO(Socket & Result<&1, &1, U32 & String, U32>):
  import "./io_poll_foreign.c"
  import "./io_poll_foreign.js"

def said(r: Result<&1, &1, U32 & String, U32>) -> String:
  match r:
    case Done{x}:
      String.append("byte ", U32.show(x))
    case Fail{(code, message)}:
      String.append("fail: ", message)

def step(s: IO.Step<(Socket & Result<&1, &1, U32 & String, U32>)>) ->
  IO(Socket & Result<&1, &1, U32 & String, U32>):
  match s:
    case Ready{value}:
      IO.bind(Unit, Socket & Result<&1, &1, U32 & String, U32>, IO.print("ready"),
        u => IO.pure(Socket & Result<&1, &1, U32 & String, U32>, value))
    case Wait{rest}:
      IO.bind(Unit, Socket & Result<&1, &1, U32 & String, U32>, IO.print("wait, cancelled"),
        u => IO.cancel(Socket & Result<&1, &1, U32 & String, U32>, rest))

def told(m: Socket & Result<&1, &1, U32 & String, U32>) -> IO(Socket):
  (s, r) = m
  IO.bind(Unit, Socket, IO.print(String.append("  ", said(r))), u => IO.pure(Socket, s))

def sent(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Socket):
  (s, r) = m
  IO.bind(Unit, Socket, IO.pass(Unit, r), u => IO.pure(Socket, s))

def talk(c: Socket, p: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, ar) = p
  do IO<Unit>:
    a : Socket <- IO.pass(Socket, ar)
    s1 : IO.Step<(Socket & Result<&1, &1, U32 & String, U32>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, U32>, 0, recv1(a))
    m1 : Socket & Result<&1, &1, U32 & String, U32> <- step(s1)
    a1 : Socket <- told(m1)
    w : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(c, "A")
    c1 : Socket <- sent(w)
    s2 : IO.Step<(Socket & Result<&1, &1, U32 & String, U32>)> <-
      IO.poll(Socket & Result<&1, &1, U32 & String, U32>, 1000, recv1(a1))
    m2 : Socket & Result<&1, &1, U32 & String, U32> <- step(s2)
    a2 : Socket <- told(m2)
    Unit <- Socket.close(a2)
    Unit <- Socket.close(c1)
    Listener.close(l)

def main_go(b: Listener & U32) -> IO(Unit):
  (l, port) = b
  do IO<Unit>:
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    p : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
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
    b : Listener & U32 <- tcp_listen_any(32n, 20017)
    main_go(b)

#|wait, cancelled
#|  fail: Operation canceled
#|ready
#|  byte 65
