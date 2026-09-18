# A positional read on a pipe must fail, preserving the handle and its data.
import Base
import ./file_binary.bend as B

def Pipe.open() -> IO(Result<&1, &1, U32 & String, File>):
  import "./file_pipe.c"
  import "./file_pipe.js"

law recover:
  for pair: File & Result<&1, &1, U32 & String, List<&2, U32>>
  IO(Unit)

def recover(pair):
  (file, result) = pair
  do IO<Unit>:
    B.failed(List<&2, U32>, result, 29, "pipe positional read fails with ESPIPE")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(file, 3)
    f : File <- B.read(p, [97, 98, 99], "pipe handle and bytes preserved")
    File.close(f)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    file : File <- IO.try(File, Pipe.open())
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(file, 1n, 3)
    recover(p)

#|pipe positional read fails with ESPIPE
#|pipe handle and bytes preserved
