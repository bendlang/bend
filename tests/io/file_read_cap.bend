# io (io_file_read_cap): a read's max is a cap, not a buffer size (#1983).
# A 5-byte file is read a thousand times with File.read_bytes capped at
# 1 GiB; the JS lane once allocated the whole cap per read, about 8 s and
# 6 GB for this loop, past the 5 s alarm. /dev/zero has no size, so a read of
# 300000 bytes from it grows its buffer until the cap and answers them all.
# Positioned reads near the end of a large sparse file need only its tail,
# so their initial buffer must account for the offset too.
import Base

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law len:
  for xs: List<&2, U32>
  for acc: U32
  U32

def len(xs, acc):
  match xs:
    case Nil{}:
      acc
    case x <> rest:
      len(rest, U32.add(acc, 1))

law count_go:
  for m: File & Result<&1, &1, (U32 & String), List<&2, U32>>
  IO(U32)

def count_go(m):
  (f, r) = m
  do IO<U32>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    u  : Unit <- File.close(f)
    return len(xs, 0)

law count:
  for +p: String
  for max: U32
  IO(U32)

def count(p, max):
  do IO<U32>:
    g : File <- IO.try(File, File.open(p, "r"))
    m : File & Result<&1, &1, (U32 & String), List<&2, U32>> <-
      File.read_bytes(g, max)
    count_go(m)

law reads:
  for +path: String
  for n: Nat
  for acc: U32
  IO(U32)

def reads(path, n, acc):
  match n:
    case 0n:
      IO.pure(U32, acc)
    case 1n+k:
      do IO<U32>:
        c : U32 <- count(path, 1073741824)
        reads(path, k, U32.add(acc, c))

def reads_at(+path: String, n: Nat, acc: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, acc)
    case 1n+k:
      do IO<U32>:
        f : File <- IO.try(File, File.open(path, "r"))
        m : File & Result<&1, &1, (U32 & String), List<&2, U32>> <-
          File.read_at(f, 1073741824, 1073741824)
        c : U32 <- count_go(m)
        reads_at(path, k, U32.add(acc, c))

law main:
  IO(U32)

def main():
  do IO<U32>:
    salt : U32 <- IO.try(U32, IO.random_u32())
    +path : String = "/tmp/bend_io_file_read_cap_" ++ U32.show(salt)
    f : File <- IO.try(File, File.open(path, "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "Olá\n")
    x : Unit <- write_go(w)
    t : U32 <- reads(path, 1000n, 0)
    p : Unit <- IO.print(U32.show(t))
    f : File <- IO.try(File, File.open(path, "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <-
      File.write_at(f, 1073741824, [65, 66, 67, 68, 69])
    x : Unit <- write_go(w)
    t : U32 <- reads_at(path, 2000n, 0)
    p : Unit <- IO.print(U32.show(t))
    z : U32 <- count("/dev/zero", 300000)
    q : Unit <- IO.print(U32.show(z))
    return 0

#|5000
#|10000
#|300000
