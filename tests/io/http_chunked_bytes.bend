# io pin (io_http_chunked_bytes): bend3's HTTP byte layer -- chunked
# decoding (hex sizes, extensions skipped) and the Bytes encode/decode
# roundtrip. bend has no HTTP library, and Bytes is ruled to a plain
# Array of U32 with no module -- the decode helper dies first on the
# missing surface (a Bytes value respells as its length & data pair).
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

law dec_eq:
  for r: Result<&1, &1, (U32 & String), List<&2, U32>>
  for out: String
  U32

def dec_eq(r, out):
  match r:
    case Done{bs}:
      b2u(String.eq(Bytes.decode(bs), out))
    case Fail{(c, e)}:
      0

law dec_bad:
  for r: Result<&1, &1, (U32 & String), List<&2, U32>>
  U32

def dec_bad(r):
  match r:
    case Done{bs}:
      0
    case Fail{(c, e)}:
      b2u(U32.is_eq(c, 400))

law chk_chunked:
  U32

def chk_chunked():
  dec_eq(HTTP.unchunk(Bytes.encode("4\r\nWiki\r\n5;ext=1\r\npedia\r\n0\r\n\r\n")), "Wikipedia")

law chk_chunked_bad:
  U32

def chk_chunked_bad():
  dec_bad(HTTP.unchunk(Bytes.encode("4\r\nWi")))

law chk_pack:
  U32

law chk_pack.rd:
  for r: U32 & List<&2, U32>
  U32

def chk_pack.rd(r):
  (n, data) = r
  (b2u(U32.is_eq(n, 10)) + b2u(String.eq(Bytes.decode(data), "héllo ✓")) : U32)

def chk_pack():
  chk_pack.rd(Bytes.from_string("héllo ✓"))

law main:
  U32

def main():
  (chk_chunked() * 100 + chk_chunked_bad() * 10 + chk_pack() : U32)

#|Error:
#|- expected : a defined name
#|- observed : Bytes.decode
#|Context:
#|- bs  : List<&2, U32>
#|- out : String
#|Location: dec_eq
#|26 |     case Done{bs}:
#|27>|       b2u(String.eq(Bytes.decode(bs), out))
#|   |                     ^^^^^^^^^^^^
#|28 |     case Fail{(c, e)}:
#|exit 1
