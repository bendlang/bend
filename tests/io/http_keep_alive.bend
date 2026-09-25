# io pin (io_http_keep_alive): bend3's keep-alive pure layer -- the
# Connection/version decision, the stamped Connection header and
# read_head's version flag. bend has no HTTP library -- chk_keep dies
# first on the missing surface (a Header respells as a name & value
# tuple, a Response as its status & headers & body triple).
import Base

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law chk_keep:
  U32

def chk_keep():
  a = b2u(HTTP.keep_alive(True{}, []))
  b = b2u(HTTP.keep_alive(True{}, [("Connection", "close")]))
  c = b2u(HTTP.keep_alive(False{}, []))
  d = b2u(HTTP.keep_alive(False{}, [("cOnNeCtIoN", " Keep-Alive ")]))
  (a + b2u(U32.is_eq(b, 0)) + b2u(U32.is_eq(c, 0)) + d : U32)

law conn_of:
  for keep: Bool
  String

law conn_of.rd:
  for r: U32 & List<(String & String)> & String
  String

def conn_of.rd(r):
  (s, hs, bd) = r
  HTTP.get_header("", "Connection", hs)

def conn_of(keep):
  conn_of.rd(HTTP.with_connection(keep, HTTP.ok("x")))

law chk_stamp:
  U32

def chk_stamp():
  (b2u(String.eq(conn_of(True{}), "keep-alive")) + b2u(String.eq(conn_of(False{}), "close")) : U32)

law flag_of:
  for text: String
  U32

law flag_of.rd:
  for r: Result<&1, &1, (U32 & String), Bool & (String & String & List<(String & String)> & U32)>
  U32

def flag_of.rd(r):
  match r:
    case Done{h}:
      head_flag(h)
    case Fail{(cd, e)}:
      9

def flag_of(text):
  flag_of.rd(HTTP.read_head(text))

law head_flag:
  for h: Bool & (String & String & List<(String & String)> & U32)
  U32

def head_flag(h):
  (v, req) = h
  (m, p, hs, bd) = req
  (b2u(v) * b2u(String.eq(m, "GET")) : U32)

law chk_head:
  U32

def chk_head():
  (b2u(U32.is_eq(flag_of("GET / HTTP/1.1\r\nHost: x\r\n"), 1)) + b2u(U32.is_eq(flag_of("GET / HTTP/1.0\r\nHost: x\r\n"), 0)) : U32)

law main:
  U32

def main():
  (chk_keep() * 100 + chk_stamp() * 10 + chk_head() : U32)

#|Error:
#|- expected : a defined name
#|- observed : HTTP.keep_alive
#|Location: chk_keep
#|22 | def chk_keep():
#|23>|   a = b2u(HTTP.keep_alive(True{}, []))
#|   |           ^^^^^^^^^^^^^^^
#|24 |   b = b2u(HTTP.keep_alive(True{}, [("Connection", "close")]))
#|exit 1
