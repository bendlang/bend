# A bounded slice for write_bytes/read_at and preserved sequential position.
import Base

def line(xs: List<&2, U32>) -> String:
  match xs:
    case Nil{}: ""
    case Con{n, rest}: U32.show(n) ++ ";" ++ line(rest)

def wrote(p: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (f, r) = p
  do IO<Unit>:
    Unit <- IO.pass(Unit, r)
    File.close(f)

def write_file() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_phase8_native_offsets", "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, [0, 128, 255, 10])
    wrote(p)

def read(p: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(File):
  (f, r) = p
  do IO<File>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    Unit <- IO.print(line(xs))
    return f

def read_file() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_phase8_native_offsets", "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, 1, 2)
    f : File <- read(p)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 2)
    f : File <- read(p)
    File.close(f)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- write_file()
    read_file()

#|128;255;
#|0;128;
