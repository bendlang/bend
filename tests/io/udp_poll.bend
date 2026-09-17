# io (io_udp_poll): UDP.poll is recv_from without the wait: it answers
# None at once when no datagram waits (the socket is never parked on
# the poller), and Some{(host, port, data)} when one does. A socket is
# polled empty, a datagram is sent to it, and it is polled again (a
# few 1 ms sleeps cover the loopback's delivery); every op threads its
# handle back OUTSIDE the Result.
import Base

law send_go:
  for m: Socket & Result<&1, &1, (U32 & String), Unit>
  IO(Socket)

def send_go(m):
  (s, r) = m
  do IO<Socket>:
    u : Unit <- IO.pass(Unit, r)
    return s

law again:
  for s2   : Socket
  for got  : Maybe<&1, String & U32 & String>
  for rest : Socket -> IO(U32)
  IO(U32)

def again(s2, got, rest):
  match got:
    case Some{(host, from, data)}:
      do IO<U32>:
        w : Unit <- IO.print(data)
        x : Unit <- Socket.close(s2)
        return 0
    case None{}:
      do IO<U32>:
        u : Unit <- IO.sleep(1)
        rest(s2)

law poll_got:
  for m    : Socket & Result<&1, &1, (U32 & String), Maybe<&1, String & U32 & String>>
  for rest : Socket -> IO(U32)
  IO(U32)

def poll_got(m, rest):
  (s2, r) = m
  do IO<U32>:
    got : Maybe<&1, String & U32 & String> <-
      IO.pass(Maybe<&1, String & U32 & String>, r)
    again(s2, got, rest)

law poll_until:
  for tries : Nat
  for s2    : Socket
  IO(U32)

def poll_until(tries, s2):
  match tries:
    case 0n:
      IO.die(U32, 1, "the datagram never arrived")
    case 1n+t:
      do IO<U32>:
        m : Socket & Result<&1, &1, (U32 & String), Maybe<&1, String & U32 & String>> <-
          UDP.poll(s2, 64)
        poll_got(m, s3 => poll_until(t, s3))

law empty_go:
  for s1  : Socket
  for p2  : U32
  for got : Maybe<&1, String & U32 & String>
  for s2  : Socket
  IO(U32)

def empty_go(s1, p2, got, s2):
  match got:
    case Some{p}:
      IO.die(U32, 1, "a datagram out of nowhere")
    case None{}:
      do IO<U32>:
        w  : Unit <- IO.print("none")
        sm : Socket & Result<&1, &1, (U32 & String), Unit> <-
          UDP.send_to(s1, "127.0.0.1", p2, "bend-poll")
        s1b : Socket <- send_go(sm)
        x  : Unit <- Socket.close(s1b)
        poll_until(100n, s2)

law empty:
  for s1 : Socket
  for p2 : U32
  for m  : Socket & Result<&1, &1, (U32 & String), Maybe<&1, String & U32 & String>>
  IO(U32)

def empty(s1, p2, m):
  (s2, r) = m
  do IO<U32>:
    got : Maybe<&1, String & U32 & String> <-
      IO.pass(Maybe<&1, String & U32 & String>, r)
    empty_go(s1, p2, got, s2)

law main_go:
  for a: Socket & U32
  for b: Socket & U32
  IO(U32)

def main_go(a, b):
  (s1, p1) = a
  (s2, p2) = b
  do IO<U32>:
    m : Socket & Result<&1, &1, (U32 & String), Maybe<&1, String & U32 & String>> <-
      UDP.poll(s2, 64)
    empty(s1, p2, m)

law udp_retry:
  for port : U32
  for r    : Result<&1, &1, (U32 & String), Socket>
  for rest : IO(Socket & U32)
  IO(Socket & U32)

def udp_retry(port, r, rest):
  match r:
    case Done{s}:
      IO.pure(Socket & U32, (s, port))
    case Fail{e}:
      rest

law udp_bind_any:
  for tries : Nat
  for +port : U32
  IO(Socket & U32)

def udp_bind_any(tries, port):
  match tries:
    case 0n:
      IO.die(Socket & U32, 1, "no free udp port")
    case 1n+t:
      rest = udp_bind_any(t, (port + 1 : U32))
      do IO<Socket & U32>:
        r : Result<&1, &1, (U32 & String), Socket> <- UDP.bind(port)
        udp_retry(port, r, rest)

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Socket & U32 <- udp_bind_any(32n, 19153)
    b : Socket & U32 <- udp_bind_any(32n, 19173)
    main_go(a, b)

#|none
#|bend-poll
