# EINTR on a recvfrom must retry the read, not fail it, in every recv API.
import Base
import ./udp_bytes.bend as UDPTest
import ./file_binary.bend as T

def Interrupted.port(socket: Socket) -> IO(Socket & U32):
  import "./udp_recv_interrupted.c"
  import "./udp_recv_interrupted.js"

def Interrupted.arm(socket: Socket) -> IO(Socket):
  import "./udp_recv_interrupted.c"
  import "./udp_recv_interrupted.js"

def Interrupted.check(socket: Socket) -> IO(Socket):
  import "./udp_recv_interrupted.c"
  import "./udp_recv_interrupted.js"

def text_value(s: Socket, d: String & U32 & String) -> IO(Socket):
  (host, (+port, t)) = d
  do IO<Socket>:
    T.check("text read once", String.eq(t, "aéλz"))
    return s

def text(pair: Socket & Result<&1, &1, U32 & String, String & U32 & String>) -> IO(Socket):
  (s, r) = pair
  do IO<Socket>:
    d : String & U32 & String <- IO.pass(String & U32 & String, r)
    text_value(s, d)

def bytes_value(s: Socket, d: String & U32 & List<&2, U32>) -> IO(Socket):
  (host, (+port, xs)) = d
  do IO<Socket>:
    T.check("bytes read once", T.same(xs, [97, 195, 169, 206, 187, 122]))
    return s

def bytes(pair: Socket & Result<&1, &1, U32 & String, String & U32 & List<&2, U32>>) -> IO(Socket):
  (s, r) = pair
  do IO<Socket>:
    d : String & U32 & List<&2, U32> <- IO.pass(String & U32 & List<&2, U32>, r)
    bytes_value(s, d)

def try_text(pair: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, String & U32 & String>, Unit>) -> IO(Socket):
  (s, p) = pair
  match p:
    case Ready{r}: text((s, r))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

def try_bytes(pair: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, String & U32 & List<&2, U32>>, Unit>) -> IO(Socket):
  (s, p) = pair
  match p:
    case Ready{r}: bytes((s, r))
    case Wait{rest}: IO.die(Socket, 1, "unexpected timeout")

# The socket sends the datagram to itself, then reads it back.
def send(s: Socket, +port: U32) -> IO(Socket):
  do IO<Socket>:
    p : Socket & Result<&1, &1, (U32 & String) & String, Unit> <-
      UDP.send_to(s, "127.0.0.1", port, "aéλz")
    UDPTest.text_go(p)

def run(pair: Socket & U32) -> IO(Unit):
  (s, +port) = pair
  do IO<Unit>:
    s : Socket <- send(s, port)
    s : Socket <- Interrupted.arm(s)
    r : Socket & Result<&1, &1, U32 & String, String & U32 & String> <- UDP.recv_from(s, 64)
    s : Socket <- text(r)
    s : Socket <- Interrupted.check(s)
    s : Socket <- send(s, port)
    s : Socket <- Interrupted.arm(s)
    r : Socket & Result<&1, &1, U32 & String, String & U32 & List<&2, U32>> <- UDP.recv_bytes_from(s, 64)
    s : Socket <- bytes(r)
    s : Socket <- Interrupted.check(s)
    s : Socket <- send(s, port)
    s : Socket <- Interrupted.arm(s)
    p : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, String & U32 & String>, Unit> <- UDP.try_recv_from(s, 64, 1000)
    s : Socket <- try_text(p)
    s : Socket <- Interrupted.check(s)
    s : Socket <- send(s, port)
    s : Socket <- Interrupted.arm(s)
    p : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, String & U32 & List<&2, U32>>, Unit> <- UDP.try_recv_bytes_from(s, 64, 1000)
    s : Socket <- try_bytes(p)
    s : Socket <- Interrupted.check(s)
    Socket.close(s)

def main() -> IO(Unit):
  do IO<Unit>:
    s : Socket <- IO.try(Socket, UDP.bind("127.0.0.1", 0))
    pair : Socket & U32 <- Interrupted.port(s)
    run(pair)

#|text read once
#|bytes read once
#|text read once
#|bytes read once
