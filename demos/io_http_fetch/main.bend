# HTTP client: a GET to ip-api.com (208.95.112.1: the TCP kit has no
# DNS) that prints the body of the answer: the status, country, city
# and IP of the caller. The response is read in two recvs, the second
# the tail or the EOF of Connection: close. Try it:
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

def fetch_tail(head: String, m: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>) -> IO(String):
  (s, r) = m
  do IO<String>:
    tail : Maybe<&1, String> <- IO.pass(Maybe<&1, String>, r)
    Socket.close(s)
    return head ++ Maybe.default(&1, String, tail, "")

def fetch_head(m: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>) -> IO(String):
  (s, r) = m
  do IO<String>:
    head : Maybe<&1, String> <- IO.pass(Maybe<&1, String>, r)
    rest : Socket & Result<&1, &1, U32 & String, Maybe<&1, String>> <- TCP.recv(s, 8192)
    fetch_tail(Maybe.default(&1, String, head, ""), rest)

def fetch_sent(m: Socket & Result<&1, &1, (U32 & String) & String, Unit>) -> IO(String):
  (s, r) = m
  match r:
    case Done{u}:
      IO.bind(Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>, String,
        TCP.recv(s, 8192), fetch_head)
    case Fail{((code, message), rest)}:
      do IO<String>:
        Socket.close(s)
        IO.die(String, code, message)

def main() -> IO(Unit):
  do IO<Unit>:
    c    : Socket <- IO.try(Socket, TCP.connect("208.95.112.1", 80))
    sent : Socket & Result<&1, &1, (U32 & String) & String, Unit> <- TCP.send(c, "GET /line/?fields=status,country,city,query HTTP/1.1\r\nHost: ip-api.com\r\nConnection: close\r\n\r\n")
    resp : String <- fetch_sent(sent)
    IO.print(http_body(resp))
