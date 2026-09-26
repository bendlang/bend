# io (io_tcp_listen_backlog): the listener's accept queue holds 512
# connections (capped by the system's own limit), not 16. Thirty-two
# clients connect in a row and nobody accepts: every connect completes at
# once because the queue holds them all. With a backlog of 16 the
# eighteenth SYN is dropped and that connect stalls on retransmits instead
# of failing -- so a regression shows here as a hang, never as a wrong
# line. The listener retries upward from a base port on Fail, as
# tcp_loopback does; each client socket is closed as soon as it connects
# (a closed-by-peer connection still holds its slot in the accept queue
# until accepted).
import Base

law connected:
  for r: Result<&1, &1, (U32 & String), Socket>
  for rest: IO(Unit)
  IO(Unit)

def connected(r, rest):
  match r:
    case Done{c}:
      do IO<Unit>:
        u : Unit <- Socket.close(c)
        rest
    case Fail{e}:
      (code, message) = e
      IO.print(message)

law connect_n:
  for n: Nat
  for +port: U32
  IO(Unit)

def connect_n(n, port):
  match n:
    case 0n:
      IO.print("32 connected, none accepted")
    case 1n+p:
      rest = connect_n(p, port)
      do IO<Unit>:
        r : Result<&1, &1, (U32 & String), Socket> <- TCP.connect("127.0.0.1", port)
        connected(r, rest)

law main_go:
  for b: Listener & U32
  IO(U32)

def main_go(b):
  (l, port) = b
  do IO<U32>:
    u : Unit <- connect_n(32n, port)
    z : Unit <- Listener.close(l)
    return 0

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
    b : Listener & U32 <- tcp_listen_any(8n, 8731)
    main_go(b)

#|32 connected, none accepted
