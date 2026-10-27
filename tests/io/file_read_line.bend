# io (io_file_read_line): File.read_line answers one line at a time with
# its "\n", cuts a longer line at max, and answers "" only at the end of
# the file. The last line has no "\n".
import Base

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law line:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(File)

def line(m):
  (f, r) = m
  do IO<File>:
    s : String <- IO.pass(String, r)
    u : Unit <- IO.print("[" ++ s ++ "]")
    return f

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_read_line.tmp", "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "ab\n\nlonger\nend")
    x : Unit <- write_go(w)
    g0 : File <- IO.try(File, File.open("/tmp/bend_io_read_line.tmp", "r"))
    m1 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g0, 64)
    g1 : File <- line(m1)
    m2 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g1, 64)
    g2 : File <- line(m2)
    m3 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g2, 3)
    g3 : File <- line(m3)
    m4 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g3, 64)
    g4 : File <- line(m4)
    m5 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g4, 64)
    g5 : File <- line(m5)
    m6 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g5, 64)
    g6 : File <- line(m6)
    File.close(g6)

#|[ab
#|]
#|[
#|]
#|[lon]
#|[ger
#|]
#|[end]
#|[]
