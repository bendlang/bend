# File.write_at refuses an append handle with EINVAL, even one File.open
# did not make: the twin opens the file with O_APPEND itself, as a shell's
# >> hands a program its stdout. On a host without bun:ffi (node) the set
# of File.open's "a" handles is all JS can ask, so with the FFI table gone
# (as in file_read_no_ffi.js) File.open's "a" must still be refused.
import Base
import ./file_binary.bend as T

def Fd.append(path: String) -> IO(File):
  import "./file_write_at_append_fd.c"
  import "./file_write_at_append_fd.js"

def ffi_absent() -> IO(Unit):
  import "./file_write_at_append_fd.c"
  import "./file_read_no_ffi.js"

def ffi_back() -> IO(Unit):
  import "./file_write_at_append_fd.c"
  import "./file_read_no_ffi.js"

def main() -> IO(Unit):
  do IO<Unit>:
    salt : U32 <- IO.try(U32, IO.random_u32())
    +path : String = "/tmp/bend_t_io_file_write_at_append_fd_" ++ U32.show(salt)
    f : File <- IO.try(File, File.open(path, "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "AAAA")
    f : File <- T.wrote(p)
    File.close(f)
    f : File <- Fd.append(path)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_at(f, 0, [66])
    f : File <- T.bad_write(p, 22, "write_at on an O_APPEND fd rejected")
    File.close(f)
    a : Unit <- ffi_absent()
    f : File <- IO.try(File, File.open(path, "a"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_at(f, 0, [66])
    f : File <- T.bad_write(p, 22, "write_at on an append handle rejected without ffi")
    File.close(f)
    b : Unit <- ffi_back()
    f : File <- IO.try(File, File.open(path, "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, 0, 8)
    f : File <- T.read(p, [65, 65, 65, 65], "rejected writes keep the bytes")
    done : Unit <- File.close(f)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/rm", ["-f", path], "", 128, 1000)
    return done

#|write_at on an O_APPEND fd rejected
#|write_at on an append handle rejected without ffi
#|rejected writes keep the bytes
