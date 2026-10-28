# A File owns a duplicate, not the global stdin descriptor or a fresh cursor.
import Base
import ./file_binary.bend as T

def Input.seed() -> IO(Unit):
  import "./process_stdin.c"
  import "./process_stdin.js"

def Input.close() -> IO(Unit):
  import "./process_stdin.c"
  import "./process_stdin.js"

def Input.restore() -> IO(Unit):
  import "./process_stdin.c"
  import "./process_stdin.js"

def read_text(pair: File & Result<&1, &1, U32 & String, String>,
  want: String, name: String) -> IO(File):
  (f, r) = pair
  do IO<File>:
    got : String <- IO.pass(String, r)
    T.check(name, String.eq(got, want))
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    Input.seed()
    f : File <- IO.try(File, File.stdin())
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 64)
    f : File <- read_text(p, "one\n", "stdin File reads current input")
    File.close(f)
    f : File <- IO.try(File, File.stdin())
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 64)
    f : File <- read_text(p, "two\n", "close preserves stdin and its cursor")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 1)
    f : File <- T.read(p, [], "stdin File observes EOF")
    File.close(f)
    Input.close()
    r : Result<&1, &1, U32 & String, File> <- File.stdin()
    T.failed(File, r, 9, "closed stdin reports EBADF")
    Input.restore()

#|stdin File reads current input
#|close preserves stdin and its cursor
#|stdin File observes EOF
#|closed stdin reports EBADF
