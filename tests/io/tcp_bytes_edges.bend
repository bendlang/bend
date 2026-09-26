# io (io_tcp_bytes_edges): the byte effects' edges. An empty send_bytes
# succeeds; a byte past 255 fails with EINVAL and sends nothing (the
# poll after it finds the socket empty); poll_bytes answers None{} when
# idle, Some{bytes} when data waits, and Some{[]} at EOF, as recv_bytes
# answers [] there. The listener retries upward from a base port on
# Fail, as tcp_loopback does.
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

law show_res:
  for r: Result<&1, &1, (U32 & String), Unit>
  String

def show_res(r):
  match r:
    case Done{u}:
      "sent"
    case Fail{e}:
      (code, message) = e
      U32.show(code) ++ (" " ++ message)

law show_poll:
  for m: Maybe<&1, List<&2, U32>>
  String

def show_poll(m):
  match m:
    case None{}:
      "none"
    case Some{v}:
      "some: " ++ show_bytes(v)

law said:
  for m: Socket & Result<&1, &1, (U32 & String), Unit>
  IO(Socket)

def said(m):
  (s, r) = m
  do IO<Socket>:
    u : Unit <- IO.print(show_res(r))
    return s

law polled:
  for tag: String
  for m: Socket & Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>>
  IO(Socket)

def polled(tag, m):
  (s, r) = m
  do IO<Socket>:
    v : Maybe<&1, List<&2, U32>> <- IO.pass(Maybe<&1, List<&2, U32>>, r)
    u : Unit <- IO.print(tag ++ show_poll(v))
    return s

law got:
  for tag: String
  for m: Socket & Result<&1, &1, (U32 & String), List<&2, U32>>
  IO(Socket)

def got(tag, m):
  (s, r) = m
  do IO<Socket>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    u  : Unit <- IO.print(tag ++ show_bytes(xs))
    return s

law run:
  for l: Listener
  for c: Socket
  for a: Socket
  IO(U32)

def run(l, c, a):
  do IO<U32>:
    s0 : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send_bytes(c, [])
    c1 : Socket <- said(s0)
    s1 : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send_bytes(c1, 7 <> (256 <> []))
    c2 : Socket <- said(s1)
    p0 : Socket & Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>> <- TCP.poll_bytes(a, 64, 100)
    a1 : Socket <- polled("empty: ", p0)
    s2 : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send_bytes(c2, 1 <> (2 <> (255 <> [])))
    c3 : Socket <- said(s2)
    p1 : Socket & Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>> <- TCP.poll_bytes(a1, 64, 1000)
    a2 : Socket <- polled("data: ", p1)
    x  : Unit <- Socket.close(c3)
    r0 : Socket & Result<&1, &1, (U32 & String), List<&2, U32>> <- TCP.recv_bytes(a2, 64)
    a3 : Socket <- got("eof: ", r0)
    p2 : Socket & Result<&1, &1, (U32 & String), Maybe<&1, List<&2, U32>>> <- TCP.poll_bytes(a3, 64, 1000)
    a4 : Socket <- polled("eof poll: ", p2)
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
        r : Result<&1, &1, (U32 & String), Listener> <- TCP.listen(port)
        tcp_retry(port, r, rest)

law main:
  IO(U32)

def main():
  do IO<U32>:
    b : Listener & U32 <- tcp_listen_any(32n, 21013)
    main_go(b)

#|sent
#|22 Invalid argument
#|empty: none
#|sent
#|data: some: 1 2 255
#|eof:
#|eof poll: some:
