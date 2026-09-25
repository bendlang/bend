# io pin (io_http_request_roundtrip): bend3's HTTP pure layer --
# request/response head reading, serialization roundtrip, the
# case-insensitive header lookup and tolerant line handling. bend has
# no HTTP library -- req_score dies first on the missing get_header (a
# Request respells as its method & path & headers & length tuple).
import Base

law Mb.default:
  for -a: Quant
  for -A: Kind(a)
  for m: Maybe<a, A>
  for d: A
  A

def Mb.default(a, A, m, d):
  match m:
    case None{}:
      d
    case Some{x}:
      x

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law req_score:
  for req: String & String & List<&1, (String & String)> & U32
  U32

def req_score(req):
  (m, p, hs, b) = req
  (b2u(String.eq(m, "GET")) + b2u(String.eq(p, "/a")) + b2u(String.eq(HTTP.get_header("", "Host", hs), "x")) + b2u(String.eq(HTTP.get_header("", "ACCEPT", hs), "*/*")) : U32)

law chk_parse:
  U32

law chk_parse.rd:
  for r: Result<&1, &1, (U32 & String), String & String & List<&1, (String & String)> & U32>
  U32

def chk_parse.rd(r):
  match r:
    case Done{req}:
      req_score(req)
    case Fail{(c, e)}:
      0

def chk_parse():
  chk_parse.rd(HTTP.read_request("GET /a HTTP/1.1\r\nhOsT: x\r\nAccept:  */*  \r\n"))

law rt_score:
  for req: String & String & List<&1, (String & String)> & U32
  U32

def rt_score(req):
  (m, p, hs, b) = req
  (b2u(String.eq(m, "POST")) + b2u(String.eq(p, "/echo")) + b2u(U32.is_eq(Mb.default(&2, U32, 0, U32.read(HTTP.get_header("", "content-length", hs))), 5)) : U32)

law chk_roundtrip:
  U32

law chk_roundtrip.rd:
  for r: Result<&1, &1, (U32 & String), String & String & List<&1, (String & String)> & U32>
  U32

def chk_roundtrip.rd(r):
  match r:
    case Done{req}:
      rt_score(req)
    case Fail{(c, e)}:
      0

def chk_roundtrip():
  chk_roundtrip.rd(HTTP.read_request(HTTP.show_request("POST", "/echo", [("Host", "h")], 5)))

law chk_response:
  U32

law chk_response.rd:
  for r: Result<&1, &1, (U32 & String), U32 & List<&1, (String & String)> & U32>
  U32

def chk_response.rd(r):
  match r:
    case Done{resp}:
      resp_status_is(resp, 404)
    case Fail{(c, e)}:
      0

def chk_response():
  chk_response.rd(HTTP.read_response(HTTP.show_response(404, [], 0)))

law resp_status_is:
  for resp: U32 & List<&1, (String & String)> & U32
  for want: U32
  U32

def resp_status_is(resp, want):
  (s, hs, b) = resp
  b2u(U32.is_eq(s, want))

law chk_bad:
  U32

law chk_bad.rd:
  for r: Result<&1, &1, (U32 & String), String & String & List<&1, (String & String)> & U32>
  U32

def chk_bad.rd(r):
  match r:
    case Done{req}:
      0
    case Fail{(c, e)}:
      b2u(U32.is_eq(c, 400))

def chk_bad():
  chk_bad.rd(HTTP.read_request("GARBAGE\r\n"))

law main:
  U32

def main():
  (chk_parse() * 1000 + chk_roundtrip() * 100 + chk_response() * 10 + chk_bad() : U32)

#|Error:
#|- expected : a defined name
#|- observed : HTTP.get_header
#|Context:
#|- m  : String
#|- p  : String
#|- hs : List<&1, Sigma<&1, &1, String, _ => String>>
#|- b  : U32
#|Location: req_score
#|38 |   (m, p, hs, b) = req
#|39>|   (b2u(String.eq(m, "GET")) + b2u(String.eq(p, "/a")) + b2u(String.eq(HTTP.get_header("", "Host", hs), "x")) + b2u(String.eq(HTTP.get_header("", "ACCEPT", hs), "*/*")) : U32)
#|   |                                                                       ^^^^^^^^^^^^^^^
#|40 |
#|exit 1
