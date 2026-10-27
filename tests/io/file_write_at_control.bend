# Fault injection distinguishes retrying EINTR, advancing after a short
# write, and returning an error when progress stops or the host fails.
# EINTR is injected on C; JS keeps the host's writeSync retry behavior.
import Base
import ./file_binary.bend as T

def Control.arm(file: File, mode: U32) -> IO(File):
  import "./file_write_at_control.c"
  import "./file_write_at_control.js"

def Control.check(file: File) -> IO(File):
  import "./file_write_at_control.c"
  import "./file_write_at_control.js"

def outcome(p: File & Result<&1, &1, U32 & String, Unit>, want: U32) -> IO(File):
  match want:
    case 0: T.wrote(p)
    case n: T.bad_write(p, n, "controlled failure")

def trial(mode: U32, want: U32, bytes: List<&2, U32>) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_write_at_control", "w"))
    f : File <- Control.arm(f, mode)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 17, [0, 255, 13, 10, 65, 0, 255])
    f : File <- outcome(p, want)
    f : File <- Control.check(f)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_at(f, 0, [88])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, [89])
    f : File <- T.wrote(p)
    File.close(f)
    f : File <- IO.try(File, File.open("/tmp/bend_io_write_at_control", "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, 17, 8)
    f : File <- T.read(p, bytes, "controlled bytes match")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 1)
    f : File <- T.read(p, [89], "controlled write preserved cursor")
    File.close(f)


def main() -> IO(Unit):
  do IO<Unit>:
    trial(0, 0, [0, 255, 13, 10, 65, 0, 255])
    trial(1, 5, [0, 255])
    trial(2, 13, [0, 255])

#|controlled bytes match
#|controlled write preserved cursor
#|controlled failure
#|controlled bytes match
#|controlled write preserved cursor
#|controlled failure
#|controlled bytes match
#|controlled write preserved cursor
