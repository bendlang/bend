# io (io_file_open_read_write): "r+" reads and writes an existing file
# in place, with no truncation or append, through both File.open and
# File.open_bytes. A missing file fails with ENOENT and is not created.
import Base

def written(pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    IO.pass(Unit, result)
    return file

def read(pair: File & Result<&1, &1, U32 & String, String>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    text : String <- IO.pass(String, result)
    IO.print(text)
    return file

def missing_code(ok: Bool, message: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("ENOENT")
    case False{}: IO.die(Unit, 1, message)

def missing(result: Result<&1, &1, U32 & String, File>) -> IO(Unit):
  match result:
    case Done{file}:
      do IO<Unit>:
        File.close(file)
        IO.die(Unit, 1, "missing file was opened")
    case Fail{(code, message)}:
      missing_code(U32.is_eq(code, 2), message)

def ascii(s: String) -> List<&2, U32>:
  match s:
    case SNil{}: []
    case SCon{c, t}: Char.to_u32(c) <> ascii(t)

def update(+path: String) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "abcdef")
    f : File <- written(p)
    File.close(f)
    f : File <- IO.try(File, File.open(path, "r+"))
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 2)
    f : File <- read(p)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "XY")
    f : File <- written(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 8)
    f : File <- read(p)
    File.close(f)
    f : File <- IO.try(File, File.open_bytes(ascii(path), "r+"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "Z")
    f : File <- written(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 8)
    f : File <- read(p)
    File.close(f)
    f : File <- IO.try(File, File.open(path, "r"))
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 8)
    f : File <- read(p)
    File.close(f)

def absent(+path: String) -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32 & String, File> <- File.open(path, "r+")
    missing(r)
    r : Result<&1, &1, U32 & String, File> <- File.open_bytes(ascii(path), "r+")
    missing(r)
    r : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    missing(r)

def main() -> IO(Unit):
  do IO<Unit>:
    update("/tmp/bend_io_read_write")
    n : U32 <- IO.try(U32, IO.random_u32())
    absent("/tmp/bend_io_read_write_missing_" ++ U32.show(n))

#|ab
#|ef
#|bXYef
#|ZbXYef
#|ENOENT
#|ENOENT
#|ENOENT
