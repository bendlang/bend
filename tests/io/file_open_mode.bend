# io (io_file_open_mode): File.open speaks "r", "w" and "a" in
# every backend; any other mode answers Fail(EINVAL). The JS kit
# once took fs.openSync's wider vocabulary, so "r+" and "w+" opened
# where C refused them.
import Base

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
  for mode: String
  IO(Unit)

def probe(mode):
  do IO<Unit>:
    r : Result<&1, &1, (U32 & String), File> <- File.open("/tmp/bend_io_mode.txt", mode)
    answer(r)

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Unit <- probe("w")
    b : Unit <- probe("r")
    c : Unit <- probe("r+")
    d : Unit <- probe("w+")
    return 0

#|opened
#|opened
#|Invalid argument
#|Invalid argument
