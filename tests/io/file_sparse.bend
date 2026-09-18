# Real size and payload above 4 GiB; a large EOF offset alone would not
# catch accidental truncation to U32. The fixture uses host IO independently.
import Base
import ./file_binary.bend as B

def Sparse.open() -> IO(Result<&1, &1, U32 & String, File>):
  import "./file_sparse.c"
  import "./file_sparse.js"

law offset:
  Nat

def offset():
  Nat.add(U32.to_nat(4294967295), 8n)

law tail:
  for f: File
  IO(Unit)

def tail(f):
  do IO<Unit>:
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, Nat.sub(offset(), 1n), 8)
    f : File <- B.read(p, [0, 128, 0, 255], "sparse tail")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, 7n, 3)
    f : File <- B.read(p, [0, 0, 0], "offset does not wrap to U32")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, Nat.add(Nat.mul(U32.to_nat(4294967295), U32.to_nat(65536)), U32.to_nat(65535)), 1)
    f : File <- B.read(p, [], "maximum Nat offset")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 1)
    f : File <- B.read(p, [0], "sparse cursor unchanged")
    File.close(f)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    f : File <- IO.try(File, Sparse.open())
    p : File & Result<&1, &1, U32 & String, Nat> <- File.size(f)
    f : File <- B.sized(p, Nat.add(offset(), 3n), "size above 4 GiB")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, offset(), 3)
    f : File <- B.read(p, [128, 0, 255], "bytes above 4 GiB")
    tail(f)

#|size above 4 GiB
#|bytes above 4 GiB
#|sparse tail
#|offset does not wrap to U32
#|maximum Nat offset
#|sparse cursor unchanged
