# File.write_bytes, then File.read -> native decoding -> code points. The
# bytes carry a BOM, NUL, a 4-byte scalar, ill-formed sequences and a
# truncated one at the end; each maximal subpart becomes one U+FFFD
# (WHATWG): C0|80, ED|A0|80, F4|90|80|80, E2 82.
import Base

def codes(cs: List<&2, Char>) -> List<&2, String>:
  match cs:
    case Nil{}:
      []
    case h <> t:
      U32.show(Char.to_u32(h)) <> codes(t)

def finish(read: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, result) = read
  do IO<Unit>:
    s : String <- IO.pass(String, result)
    File.close(f)
    IO.print(String.join(codes(String.to_list(s)), ","))

def wrote(w: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (f, r) = w
  do IO<Unit>:
    IO.pass(Unit, r)
    File.close(f)

def main() -> IO(Unit):
  do IO<Unit>:
    g : File <- IO.try(File, File.open("/tmp/bend_strings_utf8.bin", "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(g,
      [239, 187, 191, 65, 0, 240, 159, 152, 128, 192, 128, 237, 160, 128,
       244, 144, 128, 128, 226, 130])
    wrote(w)
    f : File <- IO.try(File, File.open("/tmp/bend_strings_utf8.bin", "r"))
    read : File & Result<&1, &1, U32 & String, String> <- File.read(f, 128)
    finish(read)

#|65279,65,0,128512,65533,65533,65533,65533,65533,65533,65533,65533,65533,65533
