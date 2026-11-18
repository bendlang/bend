# io (io_file_read_line): File.read_line answers one line at a time with
# its "\n", cuts a longer line at max, and answers "" at EOF or with
# a zero cap on a readable handle.
import Base

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_read_line_" ++ U32.show(salt)

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

def show_line(r: Result<&1, &1, U32 & String, String>) -> String:
  match r:
    case Done{s}:
      "[" ++ s ++ "]"
    case Fail{(code, msg)}:
      "fail " ++ U32.show(code)

law line:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(File)

def line(m):
  (f, r) = m
  do IO<File>:
    u : Unit <- IO.print(show_line(r))
    return f

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    f : File <- IO.try(File, File.open(tmp(salt), "w"))
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 0)
    f : File <- line(m)
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "ab\n\nlonger\nend")
    x : Unit <- write_go(w)
    g0 : File <- IO.try(File, File.open(tmp(salt), "r"))
    m1 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g0, 64)
    g1 : File <- line(m1)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g1, 0)
    g1 : File <- line(m)
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
    done : Unit <- File.close(g6)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("rm", ["-f", tmp(salt)], "", 128, 1000)
    return done

#|fail 9
#|[ab
#|]
#|[]
#|[
#|]
#|[lon]
#|[ger
#|]
#|[end]
#|[]
