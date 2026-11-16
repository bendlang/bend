# io (io_file_read_line_rest): File.read_line takes one line and nothing
# past it, so the next read answers the rest of the file: after a whole
# line, after a 300-byte line cut at 280 and finished by the next call,
# after a whole 300-byte line, and after a line cut at max.
import Base
import ./file_binary.bend as T

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_read_line_rest_" ++ U32.show(salt)

def line(m: File & Result<&1, &1, U32 & String, String>) -> IO(File):
  (f, r) = m
  do IO<File>:
    s : String <- IO.pass(String, r)
    u : Unit <- IO.print("[" ++ s ++ "]")
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    f : File <- IO.try(File, File.open(tmp(salt), "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write(f,
      "ab\n" ++ String.repeat("0123456789", 30n) ++ "\n"
      ++ String.repeat("abcdefghij", 30n) ++ "\nlonger\nend\nlast")
    f : File <- T.wrote(w)
    File.close(f)
    g : File <- IO.try(File, File.open(tmp(salt), "r"))
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    g : File <- line(m)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 280)
    g : File <- line(m)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    g : File <- line(m)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 512)
    g : File <- line(m)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 3)
    g : File <- line(m)
    m : File & Result<&1, &1, U32 & String, String> <- File.read(g, 64)
    g : File <- line(m)
    done : Unit <- File.close(g)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("rm", ["-f", tmp(salt)], "", 128, 1000)
    return done

#|[ab
#|]
#|[0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#|[01234567890123456789
#|]
#|[abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij
#|]
#|[lon]
#|[ger
#|end
#|last]
