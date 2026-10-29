# An interrupted send retries the same whole datagram in every send API.
import Base
import ./udp_bytes.bend as UDPTest

def Interrupted.port(socket: Socket) -> IO(Socket & U32):
  import "./udp_send_interrupted.c"
  import "./udp_send_interrupted.js"

def Interrupted.arm(socket: Socket) -> IO(Socket):
  import "./udp_send_interrupted.c"
  import "./udp_send_interrupted.js"

def Interrupted.check(socket: Socket) -> IO(Socket):
  import "./udp_send_interrupted.c"
  import "./udp_send_interrupted.js"

def ready_text(pair: Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & String, Unit>, String>) -> IO(Socket):
  (s, r) = pair
  match r:
    case Ready{x}: UDPTest.text_go((s, x))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def ready_bytes(pair: Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, List<&2, U32>>) -> IO(Socket):
  (s, r) = pair
  match r:
    case Ready{x}: UDPTest.send_go((s, x))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def run(pair: Socket & U32) -> IO(Unit):
  (s, +port) = pair
  do IO<Unit>:
    s : Socket <- Interrupted.arm(s)
    p : Socket & Result<&1, &1, (U32 & String) & String, Unit> <-
      UDP.send_to(s, "127.0.0.1", port, "aéλz")
    s : Socket <- UDPTest.text_go(p)
    s : Socket <- Interrupted.check(s)
    IO.print("text sent once")
    s : Socket <- Interrupted.arm(s)
    p : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <-
      UDP.send_bytes_to(s, "127.0.0.1", port, [97, 195, 169, 206, 187, 122])
    s : Socket <- UDPTest.send_go(p)
    s : Socket <- Interrupted.check(s)
    IO.print("bytes sent once")
    s : Socket <- Interrupted.arm(s)
    p : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & String, Unit>, String> <-
      UDP.try_send_to(s, "127.0.0.1", port, "aéλz", 1000)
    s : Socket <- ready_text(p)
    s : Socket <- Interrupted.check(s)
    IO.print("try text sent once")
    s : Socket <- Interrupted.arm(s)
    p : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, List<&2, U32>> <-
      UDP.try_send_bytes_to(s, "127.0.0.1", port, [97, 195, 169, 206, 187, 122], 1000)
    s : Socket <- ready_bytes(p)
    s : Socket <- Interrupted.check(s)
    IO.print("try bytes sent once")
    Socket.close(s)

def main() -> IO(Unit):
  do IO<Unit>:
    s : Socket <- IO.try(Socket, UDP.bind("127.0.0.1", 0))
    pair : Socket & U32 <- Interrupted.port(s)
    run(pair)

#|text sent once
#|bytes sent once
#|try text sent once
#|try bytes sent once
