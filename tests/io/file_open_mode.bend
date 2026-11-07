# io (io_file_open_mode): File.open speaks "r", "r+", "w", "a" and "x"
# in every backend; any other mode answers Fail(EINVAL). The JS kit
# once took fs.openSync's wider vocabulary, so "w+" opened where C
# refused it; it and Node's own "wx" stay refused. "x" creates a new
# path and refuses one that exists, leaving its bytes alone. Its path
# is random, like every test file's, so it is new on every run.
import Base

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_mode_" ++ U32.show(salt)

law answer:
  for r: Result<&1, &1, (U32 & String), File>
  IO(Unit)

def answer(r):
  match r:
    case Done{value}:
      do IO<Unit>:
        u : Unit <- File.close(value)
        IO.print("opened")
    case Fail{error}:
      (code, message) = error
      IO.print(message)

law probe:
  for +salt: U32
  for mode: String
  IO(Unit)

def probe(salt, mode):
  do IO<Unit>:
    r : Result<&1, &1, (U32 & String), File> <- File.open(tmp(salt), mode)
    answer(r)

law wrote:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def wrote(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law keep:
  for r: Result<&1, &1, (U32 & String), File>
  IO(Unit)

def keep(r):
  match r:
    case Done{value}:
      do IO<Unit>:
        w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(value, "keep")
        u : Unit <- wrote(w)
        IO.print("created")
    case Fail{error}:
      (code, message) = error
      IO.print(message)

law show:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(Unit)

def show(m):
  (f, r) = m
  do IO<Unit>:
    data : String <- IO.pass(String, r)
    p    : Unit <- IO.print(data)
    File.close(f)

def excl(+salt: U32) -> IO(Unit):
  do IO<Unit>:
    a : Result<&1, &1, (U32 & String), File> <- File.open(tmp(salt) ++ "_excl", "x")
    b : Unit <- keep(a)
    c : Result<&1, &1, (U32 & String), File> <- File.open(tmp(salt) ++ "_excl", "x")
    d : Unit <- answer(c)
    f : File <- IO.try(File, File.open(tmp(salt) ++ "_excl", "r"))
    m : File & Result<&1, &1, (U32 & String), String> <- File.read(f, 64)
    show(m)

law main:
  IO(U32)

def main():
  do IO<U32>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    a : Unit <- probe(salt, "w")
    b : Unit <- probe(salt, "r")
    c : Unit <- probe(salt, "r+")
    d : Unit <- probe(salt, "w+")
    e : Unit <- probe(salt, "wx")
    x : Unit <- excl(salt)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/rm", ["-f", tmp(salt), tmp(salt) ++ "_excl"], "", 128, 1000)
    return 0

#|opened
#|opened
#|opened
#|Invalid argument
#|Invalid argument
#|created
#|File exists
#|keep
