# File.fold_text: a fold over a file's File.read_text chunks answers the
# whole file's fold at every chunk size (the bytes decode to 14 scalars,
# as io_stream's "14 chars"), wherever a chunk cuts a scalar.
import Base

def count(n: U32, s: String) -> U32:
  (n + U32.from_nat(String.length(s)) : U32)

def run(max: U32) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_strings_io_fold", "r"))
    n : U32 <- File.fold_text(~U32, ~count, 4000n, f, Utf8.Dec.new(), max, 0)
    IO.print(U32.show(n))

def wrote(w: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (f, r) = w
  do IO<Unit>:
    IO.pass(Unit, r)
    File.close(f)

def main() -> IO(Unit):
  do IO<Unit>:
    g : File <- IO.try(File, File.open("/tmp/bend_strings_io_fold", "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(g,
      [239, 187, 191, 65, 0, 240, 159, 152, 128, 192, 128, 237, 160, 128,
       244, 144, 128, 128, 226, 130])
    wrote(w)
    run(1)
    run(3)
    run(4096)

#|14
#|14
#|14
