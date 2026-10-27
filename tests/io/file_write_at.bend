# Positioned writes preserve the sequential cursor and all bytes outside
# their range. Invalid bytes are rejected before the first write.
import Base
import ./file_binary.bend as T

def patch(f: File) -> IO(File):
  do IO<File>:
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 3)
    f : File <- T.read(p, [0, 1, 2], "sequential prefix")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 10, [0, 255, 128])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 2)
    f : File <- T.read(p, [3, 4], "write_at preserves read cursor")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, [77])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 254, [1, 2, 3, 4])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 0, [99, 256, 2])
    f : File <- T.bad_write(p, 22, "invalid byte rejected")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 1000, [])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    f : File <- T.sized(p, 258, "empty write does not extend")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 9, 5)
    f : File <- T.read(p, [9, 0, 255, 128, 13], "overwrite preserves neighbors")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 253, 8)
    f : File <- T.read(p, [253, 1, 2, 3, 4], "write extends past EOF")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 8192, [0, 255])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 8190, 4)
    f : File <- T.read(p, [0, 0, 0, 255], "sparse extension")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 2)
    f : File <- T.read(p, [6, 7], "all positioned operations preserve cursor")
    return f

def readonly() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_write_at", "r"))
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at(f, 0, [88])
    f : File <- T.bad_write(p, 9, "read-only write fails and retains handle")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 3)
    f : File <- T.read(p, [0, 1, 2], "invalid and failed writes preserve bytes")
    File.close(f)

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_write_at", "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, T.bytes(256n, 0))
    f : File <- T.wrote(p)
    File.close(f)
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_write_at", "r+"))
    f : File <- patch(f)
    File.close(f)
    readonly()

#|sequential prefix
#|write_at preserves read cursor
#|invalid byte rejected
#|empty write does not extend
#|overwrite preserves neighbors
#|write extends past EOF
#|sparse extension
#|all positioned operations preserve cursor
#|read-only write fails and retains handle
#|invalid and failed writes preserve bytes
