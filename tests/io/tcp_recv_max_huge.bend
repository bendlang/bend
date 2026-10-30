# io (io_tcp_recv_max_huge): a receive's max past INT32_MAX is capped, as
# the C lane caps it, so it answers what waits instead of failing. The peer
# sends "hello", then "world": recv with max 4294967295 reads "hello",
# recv_bytes with max 2147483648 (the first value past INT32_MAX) reads
# "world", and after it sends "again", try_recv with max 4294967295 reads it.
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
  for r: Result<&1, &1, (U32 & String), Maybe<&1, String>>
  String

def show_text(r):
  match r:
    case Done{Some{s}}:
      "done: " ++ s
    case Done{None{}}:
      "ended"
    case Fail{e}:
      show_fail(e)

law show_list:
  for r: Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>>
  String

def show_list(r):
  match r:
    case Done{Some{xs}}:
      "done: " ++ show_bytes(xs)
    case Done{None{}}:
      "ended"
    case Fail{e}:
      show_fail(e)

law show_poll:
  for r: Poll<&1, &1, Result<&1, &1, (U32 & String), Maybe<&1, String>>, Unit>
  String

def show_poll(r):
  match r:
    case Ready{t}:
      show_text(t)
    case Wait{u}:
      "wait"

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
  for m: Socket & Result<&1, &1, (U32 & String), Maybe<&1, String>>
  Socket & String

def text(m):
  (s, r) = m
  (s, show_text(r))

law list:
  for m: Socket & Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>>
  Socket & String

def list(m):
  (s, r) = m
  (s, show_list(r))

law poll:
  for m: Socket & Poll<&1, &1, Result<&1, &1, (U32 & String), Maybe<&1, String>>, Unit>
  Socket & String

def poll(m):
  (s, r) = m
  (s, show_poll(r))

law sent:
  for m: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>
  IO(Socket)

def sent(m):
  (s, r) = m
  match r:
    case Done{u}:
      IO.pure(Socket, s)
    case Fail{((code, message), rest)}:
      do IO<Socket>:
        u : Unit <- IO.die(Unit, code, message)
        return s

law run:
  for l: Listener
  for c: Socket
  for a: Socket
  IO(U32)

def run(l, c, a):
  do IO<U32>:
    s0 : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(c, "hello")
    c1 : Socket <- sent(s0)
    r0 : Socket & Result<&1, &1, (U32 & String), Maybe<&1, String>> <- TCP.recv(a, 4294967295)
    a1 : Socket <- told("recv 4294967295: ", text(r0))
    s1 : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(c1, "world")
    c2 : Socket <- sent(s1)
    r1 : Socket & Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>> <- TCP.recv_bytes(a1, 2147483648)
    a2 : Socket <- told("recv_bytes 2147483648: ", list(r1))
    s2 : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(c2, "again")
    c3 : Socket <- sent(s2)
    p0 : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String), Maybe<&1, String>>, Unit> <- TCP.try_recv(a2, 4294967295, 5000)
    a3 : Socket <- told("try_recv 4294967295: ", poll(p0))
    x  : Unit <- Socket.close(c3)
    y  : Unit <- Socket.close(a3)
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
    b : Listener & U32 <- tcp_listen_any(32n, 23117)
    main_go(b)

#|recv 4294967295: done: hello
#|recv_bytes 2147483648: done: 119 111 114 108 100
#|try_recv 4294967295: done: again
