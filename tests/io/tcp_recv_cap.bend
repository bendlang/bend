# io (io_tcp_recv_cap): a JS TCP.recv's max is a cap, not its buffer
# size, as File.read's is (#1983). 1000 rounds send 8 bytes over
# loopback and receive them with a 1 GiB max; the byte count prints.
# Before, every receive on the JS lane committed the whole max: this
# test took 9 s and 8 GB there, past the gate's 5 s alarm.
import Base
import ./tcp_bytes.bend as TCPTest

def take(m: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>) -> IO(Socket & Nat):
  (a, r) = m
  do IO<Socket & Nat>:
    data : Maybe<&1, String> <- IO.pass(Maybe<&1, String>, r)
    return (a, String.length(Maybe.default(&1, String, data, "")))

def rounds(n: Nat, c: Socket, t: Socket & Nat, acc: Nat) -> IO(Unit):
  match n:
    case 0n:
      (a, k) = t
      do IO<Unit>:
        IO.print(Nat.show(Nat.add(acc, k)))
        Socket.close(a)
        Socket.close(c)
    case 1n+p:
      (a, k) = t
      do IO<Unit>:
        s : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(c, "bend-tcp")
        c : Socket <- TCPTest.send_go(s)
        r : Socket & Result<&1, &1, U32 & String, Maybe<&1, String>> <- TCP.recv(a, 1073741824)
        t : Socket & Nat <- take(r)
        rounds(p, c, t, Nat.add(acc, k))

def accepted(c: Socket, m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, r) = m
  do IO<Unit>:
    a : Socket <- IO.pass(Socket, r)
    Listener.close(l)
    rounds(1000n, c, (a, 0n), 0n)

def main_go(b: Listener & U32) -> IO(Unit):
  (l, port) = b
  do IO<Unit>:
    c : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    m : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    accepted(c, m)

def main() -> IO(Unit):
  do IO<Unit>:
    b : Listener & U32 <- TCPTest.tcp_listen_any(32n, 21417)
    main_go(b)

#|8000
