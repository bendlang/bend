# io (io_read_leading_bom): File.read keeps a leading byte-order mark on
# every lane: the bytes that arrive are the bytes the program sees.
import Base

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
    text : String <- IO.pass(String, r)
    p    : Unit <- IO.print(Bool.show(String.eq(text, "\u{feff}\u{feff}bend")))
    x    : Unit <- File.close(f)
    return 0

law main:
  IO(U32)

def main():
  do IO<U32>:
    salt : U32 <- IO.try(U32, IO.random_u32())
    +path : String = "/tmp/bend_t_io_read_leading_bom_" ++ U32.show(salt)
    f : File <- IO.try(File, File.open(path, "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <-
      File.write(f, "\u{feff}\u{feff}bend")
    x : Unit <- write_go(w)
    g : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, (U32 & String), String> <- File.read(g, 64)
    done : U32 <- read_go(m)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/rm", ["-f", path], "", 128, 1000)
    return done

#|True
