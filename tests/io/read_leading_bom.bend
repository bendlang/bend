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
    f : File <- IO.try(File, File.open("/tmp/bend_io_read_leading_bom", "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <-
      File.write(f, "\u{feff}\u{feff}bend")
    x : Unit <- write_go(w)
    g : File <- IO.try(File, File.open("/tmp/bend_io_read_leading_bom", "r"))
    m : File & Result<&1, &1, (U32 & String), String> <- File.read(g, 64)
    read_go(m)

#|True
