# io (io_tcp_bytes_split): TCP.send_bytes and TCP.recv_bytes carry the
# bytes as they are, so two things TCP.recv cannot do work here. First, a
# character split across two reads: "café" is 63 61 66 C3 A9, and the
# network may deliver C3 in one read and A9 in the next -- TCP.recv
# decodes each read on its own, so both halves come back as U+FFFD
# (65533) and the character is gone. Second, a byte that is not text at
# all (FF 00 80), which no String can spell. Both are sent and read back
# here byte for byte. The listener retries upward from a base port on
# Fail, as tcp_loopback does, and every op threads its handle back.
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

law sent:
  for m: Socket & Result<&1, &1, (U32 & String), Unit>
  IO(Socket)

def sent(m):
  (s, r) = m
  do IO<Socket>:
    u : Unit <- IO.pass(Unit, r)
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

law last_leg:
  for l: Listener
  for c: Socket
  for a: Socket
  IO(U32)

def last_leg(l, c, a):
  do IO<U32>:
    sm : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send_bytes(c, 255 <> (0 <> (128 <> [])))
    c2 : Socket <- sent(sm)
    rm : Socket & Result<&1, &1, (U32 & String), List<&2, U32>> <- TCP.recv_bytes(a, 64)
    a2 : Socket <- got("not text: ", rm)
    x  : Unit <- Socket.close(a2)
    y  : Unit <- Socket.close(c2)
    z  : Unit <- Listener.close(l)
    return 0

law second_half:
  for l: Listener
  for c: Socket
  for a: Socket
  IO(U32)

def second_half(l, c, a):
  do IO<U32>:
    sm : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send_bytes(c, 169 <> [])
    c2 : Socket <- sent(sm)
    rm : Socket & Result<&1, &1, (U32 & String), List<&2, U32>> <- TCP.recv_bytes(a, 64)
    a2 : Socket <- got("second read: ", rm)
    last_leg(l, c2, a2)

law first_half:
  for l: Listener
  for c: Socket
  for a: Socket
  IO(U32)

def first_half(l, c, a):
  do IO<U32>:
    sm : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send_bytes(c, 99 <> (97 <> (102 <> (195 <> []))))
    c2 : Socket <- sent(sm)
    rm : Socket & Result<&1, &1, (U32 & String), List<&2, U32>> <- TCP.recv_bytes(a, 64)
    a2 : Socket <- got("first read: ", rm)
    second_half(l, c2, a2)

law accepted:
  for c: Socket
  for p: Listener & Result<&1, &1, (U32 & String), Socket>
  IO(U32)

def accepted(c, p):
  (l, ar) = p
  do IO<U32>:
    a : Socket <- IO.pass(Socket, ar)
    first_half(l, c, a)

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
    b : Listener & U32 <- tcp_listen_any(32n, 19613)
    main_go(b)

#|first read: 99 97 102 195
#|second read: 169
#|not text: 255 0 128
