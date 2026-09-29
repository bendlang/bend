# io (io_tcp_recv_max_zero): a receive of at most 0 bytes fails with
# EINVAL. recv(2) of 0 bytes answers 0 when data waits, the same 0 it
# answers at the peer's close, so "" (or []) there would read as EOF on a
# socket that is still open. The peer sends "hello" and stays open; poll,
# recv and recv_bytes with max 0 each fail with EINVAL and take nothing,
# so a recv of 64 after them still reads "hello". The listener retries
# upward from a base port on Fail, as tcp_loopback does.
import Base

law show_bytes:
  for xs: List<&2, U32>
  String

def show_bytes(xs):
  match xs:
    case Nil{}:
      ""
    case h <> t:
      U32.show(h) ++ (" " ++ show_bytes(t))

law show_fail:
  for e: U32 & String
  String

def show_fail(e):
  (code, message) = e
  U32.show(code) ++ (" " ++ message)

law show_text:
  for r: Result<&1, &1, (U32 & String), String>
  String

def show_text(r):
  match r:
    case Done{s}:
      "done: " ++ s
    case Fail{e}:
      show_fail(e)

law show_list:
  for r: Result<&1, &1, (U32 & String), List<&2, U32>>
  String

def show_list(r):
  match r:
    case Done{xs}:
      "done: " ++ show_bytes(xs)
    case Fail{e}:
      show_fail(e)

law show_some:
  for m: Maybe<&1, String>
  String

def show_some(m):
  match m:
    case None{}:
      "none"
    case Some{s}:
      "some: " ++ s

law show_poll:
  for r: Result<&1, &1, (U32 & String), Maybe<&1, String>>
  String

def show_poll(r):
  match r:
    case Done{m}:
      show_some(m)
    case Fail{e}:
      show_fail(e)

law told:
  for tag: String
  for m: Socket & String
  IO(Socket)

def told(tag, m):
  (s, line) = m
  do IO<Socket>:
    u : Unit <- IO.print(tag ++ line)
    return s

law text:
  for m: Socket & Result<&1, &1, (U32 & String), String>
  Socket & String

def text(m):
  (s, r) = m
  (s, show_text(r))

law list:
  for m: Socket & Result<&1, &1, (U32 & String), List<&2, U32>>
  Socket & String

def list(m):
  (s, r) = m
  (s, show_list(r))

law poll:
  for m: Socket & Result<&1, &1, (U32 & String), Maybe<&1, String>>
  Socket & String

def poll(m):
  (s, r) = m
  (s, show_poll(r))

law sent:
  for m: Socket & Result<&1, &1, (U32 & String), Unit>
  IO(Socket)

def sent(m):
  (s, r) = m
  do IO<Socket>:
    u : Unit <- IO.pass(Unit, r)
    return s

law run:
  for l: Listener
  for c: Socket
  for a: Socket
  IO(U32)

def run(l, c, a):
  do IO<U32>:
    s0 : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send(c, "hello")
    c1 : Socket <- sent(s0)
    p0 : Socket & Result<&1, &1, (U32 & String), Maybe<&1, String>> <- TCP.poll(a, 0, 100)
    a1 : Socket <- told("poll: ", poll(p0))
    r0 : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(a1, 0)
    a2 : Socket <- told("recv: ", text(r0))
    r1 : Socket & Result<&1, &1, (U32 & String), List<&2, U32>> <- TCP.recv_bytes(a2, 0)
    a3 : Socket <- told("recv_bytes: ", list(r1))
    r2 : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(a3, 64)
    a4 : Socket <- told("then recv 64: ", text(r2))
    x  : Unit <- Socket.close(c1)
    y  : Unit <- Socket.close(a4)
    z  : Unit <- Listener.close(l)
    return 0

law accepted:
  for c: Socket
  for p: Listener & Result<&1, &1, (U32 & String), Socket>
  IO(U32)

def accepted(c, p):
  (l, ar) = p
  do IO<U32>:
    a : Socket <- IO.pass(Socket, ar)
    run(l, c, a)

law main_go:
  for b: Listener & U32
  IO(U32)

def main_go(b):
  (l, port) = b
  do IO<U32>:
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    p : Listener & Result<&1, &1, (U32 & String), Socket> <- TCP.accept(l)
    accepted(c, p)

law tcp_retry:
  for port : U32
  for r    : Result<&1, &1, (U32 & String), Listener>
  for rest : IO(Listener & U32)
  IO(Listener & U32)

def tcp_retry(port, r, rest):
  match r:
    case Done{l}:
      IO.pure(Listener & U32, (l, port))
    case Fail{e}:
      rest

law tcp_listen_any:
  for tries : Nat
  for +port : U32
  IO(Listener & U32)

def tcp_listen_any(tries, port):
  match tries:
    case 0n:
      IO.die(Listener & U32, 1, "no free tcp port")
    case 1n+t:
      rest = tcp_listen_any(t, (port + 1 : U32))
      do IO<Listener & U32>:
        r : Result<&1, &1, (U32 & String), Listener> <- TCP.listen("127.0.0.1", port)
        tcp_retry(port, r, rest)

law main:
  IO(U32)

def main():
  do IO<U32>:
    b : Listener & U32 <- tcp_listen_any(32n, 23017)
    main_go(b)

#|poll: 22 Invalid argument
#|recv: 22 Invalid argument
#|recv_bytes: 22 Invalid argument
#|then recv 64: done: hello
