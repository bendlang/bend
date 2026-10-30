# Invalid UDP send addresses return EINVAL when FFI setup fails.
# All four send forms must keep the socket and the datagram.
import Base
import ./udp_bytes.bend as UDPTest

def UdpNoFfi.arm(socket: Socket) -> IO(Socket):
  import "./udp_send_no_ffi.c"
  import "./udp_send_no_ffi.js"

def text(pair: Socket & Result<&1, &1, (U32 & String) & String, Unit>) -> IO(Socket):
  (s, r) = pair
  match r:
    case Done{value}:
      IO.die(Socket, 1, "unexpected success")
    case Fail{((code, message), data)}:
      do IO<Socket>:
        IO.print(U32.show(code) ++ ", kept " ++ data)
        return s

def ready_text(pair: Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & String, Unit>, String>) -> IO(Socket):
  (s, r) = pair
  match r:
    case Ready{x}: text((s, x))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def main() -> IO(Unit):
  do IO<Unit>:
    s : Socket <- IO.try(Socket, UDP.bind("127.0.0.1", 0))
    s : Socket <- UdpNoFfi.arm(s)
    p : Socket & Result<&1, &1, (U32 & String) & String, Unit> <-
      UDP.send_to(s, "127.0.0.256", 9, "text")
    s : Socket <- text(p)
    s : Socket <- UdpNoFfi.arm(s)
    p : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <-
      UDP.send_bytes_to(s, "1.2.3.", 9, [0, 255])
    s : Socket <- UDPTest.send_go(p)
    s : Socket <- UdpNoFfi.arm(s)
    p : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & String, Unit>, String> <-
      UDP.try_send_to(s, "127.0.0.1", 65536, "try text", 0)
    s : Socket <- ready_text(p)
    s : Socket <- UdpNoFfi.arm(s)
    p : Socket & Poll<&1, &1, Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, List<&2, U32>> <-
      UDP.try_send_bytes_to(s, "127.0.0.1", 65536, [128, 1], 0)
    s : Socket <- UDPTest.show_try_send(p)
    p : Socket & Result<&1, &1, (U32 & String) & String, Unit> <-
      UDP.send_to(s, "127.0.0.1", 9, "socket kept")
    s : Socket <- UDPTest.text_go(p)
    Socket.close(s)

#|22, kept text
#|22, kept 0 255
#|22, kept try text
#|ready 22, kept 128 1
