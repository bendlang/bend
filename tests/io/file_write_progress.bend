# A short write followed by zero progress must fail, not retry forever.
# The returned handle remains usable and the file contains only the prefix
# actually written, followed by a recovery write.
import Base

def Progress.open() -> IO(Result<&1, &1, U32 & String, File>):
  import "./file_write_progress.c"
  import "./file_write_progress.js"

def Progress.resume() -> IO(Unit):
  import "./file_write_progress.c"
  import "./file_write_progress.js"

def Progress.release() -> IO(Unit):
  import "./file_write_progress.c"
  import "./file_write_progress.js"

def check(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}: IO.print(name)
    case False{}: IO.die(Unit, 1, "FAIL " ++ name)

def same(xs: List<&2, U32>, ys: List<&2, U32>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case x <> xt y <> yt: Bool.and(U32.is_eq(x, y), same(xt, yt))
    case _ _: False{}

def failed(kind: String, result: Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  match result:
    case Done{value}:
      IO.die(Unit, 1, kind ++ " zero-progress write unexpectedly succeeded")
    case Fail{error}:
      (code, message) = error
      check(kind ++ " zero progress is EIO", U32.is_eq(code, 5))

def recover(kind: String,
            pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    failed(kind, result)
    return file

def written(pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    IO.pass(Unit, result)
    return file

def verified(kind: String, expected: List<&2, U32>,
             pair: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    got : List<&2, U32> <- IO.pass(List<&2, U32>, result)
    check(kind ++ " prefix and recovery bytes preserved", same(got, expected))
    return file

def main() -> IO(Unit):
  do IO<Unit>:
    file : File <- IO.try(File, Progress.open())
    pair : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(file, [])
    file : File <- written(pair)
    pair : File & Result<&1, &1, U32 & String, Unit> <- File.write(file, "")
    file : File <- written(pair)
    pair : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(file,
        [0, 1, 255, 128, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    file : File <- recover("binary", pair)
    Progress.resume()
    pair : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(file, [97, 98, 99, 100, 101, 102, 103, 104])
    file : File <- written(pair)
    pair : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(file, 0, 32)
    file : File <-
      verified("binary", [0, 1, 255, 128, 2, 3, 4, 97, 98, 99, 100, 101,
        102, 103, 104], pair)
    File.close(file)
    Progress.release()
    file : File <- IO.try(File, Progress.open())
    pair : File & Result<&1, &1, U32 & String, Unit> <-
      File.write(file, "é🙂ABCD")
    file : File <- recover("text", pair)
    Progress.resume()
    pair : File & Result<&1, &1, U32 & String, Unit> <-
      File.write(file, "abcdefgh")
    file : File <- written(pair)
    pair : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(file, 0, 32)
    file : File <-
      verified("text", [195, 169, 240, 159, 153, 130, 65, 97, 98, 99, 100,
        101, 102, 103, 104], pair)
    File.close(file)
    Progress.release()

#|binary zero progress is EIO
#|binary prefix and recovery bytes preserved
#|text zero progress is EIO
#|text prefix and recovery bytes preserved
