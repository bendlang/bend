# The demo reader over a real loopback socket: split the separator, body
# and UTF-8 character across writes, then close. At the byte limit the
# final character's bytes arrive separately; only the following EOF fits.
import Base
import ../../demos/io_http_fetch/main.bend as Fetch

def ascii(text: String) -> List<&2, U32>:
  match text:
    case SNil{}:
      Nil{}
    case SCon{Chr{byte}, rest}:
      byte <> ascii(rest)

def send_done(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Socket):
  (s, r) = m
  do IO<Socket>:
    IO.pass(Unit, r)
    return s

def serve(parts: List<&2, List<&2, U32>>, s: Socket) -> IO(Unit):
  match parts:
    case Nil{}:
      Socket.close(s)
    case part <> rest:
      do IO<Unit>:
        sent : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send_bytes(s, part)
        next : Socket <- send_done(sent)
        IO.sleep(30)
        serve(rest, next)

def listen_done(port: U32, r: Result<&1, &1, U32 & String, Listener>,
  rest: IO(Listener & U32)) -> IO(Listener & U32):
  match r:
    case Done{listener}:
      IO.pure(Listener & U32, (listener, port))
    case Fail{error}:
      rest

def listen_any(tries: Nat, +port: U32) -> IO(Listener & U32):
  match tries:
    case 0n:
      IO.die(Listener & U32, 1, "no free tcp port")
    case 1n+rest:
      later = listen_any(rest, (port + 1 : U32))
      do IO<Listener & U32>:
        r : Result<&1, &1, U32 & String, Listener> <- TCP.listen("127.0.0.1", port)
        listen_done(port, r, later)

def accepted(parts: List<&2, List<&2, U32>>, client: Socket,
  m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(String):
  (listener, r) = m
  do IO<String>:
    server : Socket <- IO.pass(Socket, r)
    Listener.close(listener)
    IO.spawn(Unit, serve(parts, server))
    first : Socket & Result<&1, &1, U32 & String, List<&2, U32>> <-
      TCP.recv_bytes(client, 8192)
    Fetch.fetch_read(65536n, 65536, first, Nil{})

def connected(parts: List<&2, List<&2, U32>>, bound: Listener & U32) -> IO(String):
  (listener, port) = bound
  do IO<String>:
    client : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", port))
    m : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(listener)
    accepted(parts, client, m)

def exchange(parts: List<&2, List<&2, U32>>) -> IO(String):
  do IO<String>:
    bound : Listener & U32 <- listen_any(32n, 19721)
    connected(parts, bound)

# The header is 19 bytes; ASCII padding plus the two bytes of é totals 65536.
# Seven 8191-byte chunks plus 8178 bytes avoid deep constructor recursion.
def limit_parts(extra: List<&2, U32>) -> List<&2, List<&2, U32>>:
  padding = List.replicate(List<&2, U32>, 7n, List.replicate(U32, 8191n, 97))
  ascii("HTTP/1.0 200 OK\r\n\r\n") <> List.append(&2, List<&2, U32>, padding,
    [List.replicate(U32, 8178n, 97), [195], List.append(&2, U32, [169], extra)])

def main() -> IO(Unit):
  do IO<Unit>:
    fragmented : String <- exchange([ascii("HTTP/1.0 200 OK\r"), ascii("\n\r"),
      ascii("\nA"), [195], [169], ascii("BC")])
    IO.print(Fetch.http_body(fragmented))
    +limit : String <- exchange(limit_parts(Nil{}))
    IO.print(Nat.show(String.length(Fetch.http_body(limit))))
    IO.print(String.drop(Fetch.http_body(limit), 65515n))
    empty : String <- exchange(Nil{})
    IO.print(String.append("empty:", Bool.show(String.is_empty(empty))))
    malformed : String <- exchange([ascii("no header separator")])
    IO.print(String.append("malformed:", Bool.show(String.is_empty(Fetch.http_body(malformed)))))

#|AéBC
#|65516
#|é
#|empty:True
#|malformed:True
