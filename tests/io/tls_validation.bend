# Invalid TLS addresses and deadlines fail before a connection is attempted.
import Base

def invalid(result: Result<&1, &1, U32 & String, TLS>) -> IO(Unit):
  match result:
    case Fail{(code, message)}:
      IO.print(Bool.show(U32.is_eq(code, 22)))
    case Done{socket}:
      do IO<Unit>:
        closed : Unit <- TLS.close(socket)
        IO.print("False")

def main() -> IO(Unit):
  do IO<Unit>:
    host : Result<&1, &1, U32 & String, TLS> <- TLS.connect("bad/host", 443, "", 1000)
    a : Unit <- invalid(host)
    port : Result<&1, &1, U32 & String, TLS> <- TLS.connect("localhost", 0, "", 1000)
    b : Unit <- invalid(port)
    time : Result<&1, &1, U32 & String, TLS> <- TLS.connect("localhost", 443, "", 0)
    invalid(time)

#|True
#|True
#|True
