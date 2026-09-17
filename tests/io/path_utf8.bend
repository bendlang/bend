# io (io_path_utf8): a path reaches the OS as UTF-8, and a file's bytes
# come back as code points, in every lane -- the inbound twin of
# io_text_utf8's write law. The path below ends in Chr{233}: under the
# old byte law C opened the lone byte E9 (EILSEQ on APFS) while the JS
# lanes opened a two-byte name, so the lanes disagreed on which file
# exists; now every lane opens "Ã©". The text written through the
# file is read back and printed, so a lane that decoded bytes as chars
# would print "OlÃ¡" where the law prints what was written.
import Base

law good:
  String

def good():
  String.append("/tmp/bend_io_path_", SCon{Chr{233}, SNil{}})

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(U32)

def read_go(m):
  (f, r) = m
  do IO<U32>:
    data : String <- IO.pass(String, r)
    p    : Unit <- IO.print(data)
    x    : Unit <- File.close(f)
    return 0

law main:
  IO(U32)

def main():
  do IO<U32>:
    f : File <- IO.try(File, File.open(good(), "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "Olá 日本 🙂")
    x : Unit <- write_go(w)
    g : File <- IO.try(File, File.open(good(), "r"))
    m : File & Result<&1, &1, (U32 & String), String> <- File.read(g, 64)
    read_go(m)

#|Olá 日本 🙂
