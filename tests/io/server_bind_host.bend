# Both server effects use the requested IPv4 address rather than ignoring it.
# Invalid addresses fail before opening a socket; the loopback and wildcard
# spellings remain available explicitly.
import Base

def tcp_error(r: Result<&1, &1, U32 & String, Listener>) -> IO(Unit):
  match r:
    case Fail{error}:
      (code, message) = error
      IO.print(U32.show(code))
    case Done{listener}:
      do IO<Unit>:
        u : Unit <- Listener.close(listener)
        IO.print("unexpected tcp bind")

def udp_error(r: Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  match r:
    case Fail{error}:
      (code, message) = error
      IO.print(U32.show(code))
    case Done{socket}:
      do IO<Unit>:
        u : Unit <- Socket.close(socket)
        IO.print("unexpected udp bind")

def main() -> IO(Unit):
  do IO<Unit>:
    t : Result<&1, &1, U32 & String, Listener> <- TCP.listen("127.0.0.256", 0)
    a : Unit <- tcp_error(t)
    u : Result<&1, &1, U32 & String, Socket> <- UDP.bind("127.0.0.256", 0)
    b : Unit <- udp_error(u)
    listener : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 0))
    c : Unit <- Listener.close(listener)
    socket : Socket <- IO.try(Socket, UDP.bind("0.0.0.0", 0))
    d : Unit <- Socket.close(socket)
    IO.print("bound")

#|22
#|22
#|bound
