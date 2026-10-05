# HTTP client: a GET to ip-api.com (208.95.112.1: the TCP kit has no
# DNS) that prints the body of the answer: the status, country, city
# and IP of the caller. The response is read until EOF (Connection:
# close), up to 65536 decoded characters. Try it:
#
#   bend demos/io_http_fetch/main.bend
import Base

# the text after the first blank line; e says whether the window w,
# the last 4 characters as a big-endian word, is "\r\n\r\n" (218762506)
def http_body.go(s: String, e: Bool, w: U32) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{a}, t}:
      match e:
        case True{}:
          SCon{Chr{a}, t}
        case False{}:
          +w2 = (w * 256 + a : U32)
          http_body.go(t, U32.is_eq(w2, 218762506), w2)

# the body of a response: the text after the status line and headers
def http_body(s: String) -> String:
  http_body.go(s, False{}, 0)

# chunks are newest-first; foldl prepends each once without recursive concat
def fetch_end(
  m: Socket & Result<&1, &1, U32 & String, String>,
  chunks: List<&2, String>
) -> IO(String):
  (s, r) = m
  match r:
    case Fail{(code, message)}:
      do IO<String>:
        Socket.close(s)
        IO.die(String, code, message)
    case Done{chunk}:
      match chunk:
        case SNil{}:
          do IO<String>:
            Socket.close(s)
            return List.foldl(~&2, ~String, ~String,
              ~(acc => chunk => String.append(chunk, acc)), chunks, "")
        case SCon{h, t}:
          do IO<String>:
            Socket.close(s)
            IO.die(String, 1, "HTTP response exceeds 65536 characters")

def fetch_read(
  fuel: Nat,
  cap: Bool,
  m: Socket & Result<&1, &1, U32 & String, String>,
  chunks: List<&2, String>,
  remaining: U32
) -> IO(String):
  match fuel:
    case 0n:
      fetch_end(m, chunks)
    case 1n+fuel2:
      match cap:
        case True{}:
          fetch_end(m, chunks)
        case False{}:
          (s, r) = m
          match r:
            case Fail{(code, message)}:
              do IO<String>:
                Socket.close(s)
                IO.die(String, code, message)
            case Done{chunk}:
              match chunk:
                case SNil{}:
                  do IO<String>:
                    Socket.close(s)
                    return List.foldl(~&2, ~String, ~String,
                      ~(acc => chunk => String.append(chunk, acc)), chunks, "")
                case SCon{+h, +t}:
                  +size = String.length(chunk)
                  +left = U32.sub(remaining, U32.from_nat(size))
                  do IO<String>:
                    next : Socket & Result<&1, &1, U32 & String, String> <-
                      TCP.recv(s, U32.max(U32.min(left, 8192), 1))
                    fetch_read(
                      fuel2, U32.is_zero(left), next, chunk <> chunks, left
                    )

def fetch_sent(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(String):
  (s, r) = m
  match r:
    case Fail{(code, message)}:
      do IO<String>:
        Socket.close(s)
        IO.die(String, code, message)
    case Done{u}:
      do IO<String>:
        first : Socket & Result<&1, &1, U32 & String, String> <-
          TCP.recv(s, 8192)
        fetch_read(65536n, False{}, first, Nil{}, 65536)

def main() -> IO(Unit):
  do IO<Unit>:
    c    : Socket <- IO.try(Socket, TCP.connect("208.95.112.1", 80))
    sent : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(c, "GET /line/?fields=status,country,city,query HTTP/1.1\r\nHost: ip-api.com\r\nConnection: close\r\n\r\n")
    resp : String <- fetch_sent(sent)
    IO.print(http_body(resp))
