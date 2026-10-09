# File.read_into lands bytes little-endian in an Array<U32>'s own slots: a
# short tail keeps its slot's high bytes, a read stops at the array's end and
# at the file's, and a failed read keeps the handle and the array and leaves
# no error behind for the next read.
import Base

law bytes:
  for n: Nat
  for +at: U32
  List<&2, U32>

def bytes(n, at):
  match n:
    case 0n: Nil{}
    case 1n+p: at <> bytes(p, U32.add(at, 1))

law check:
  for name: String
  for ok: Bool
  IO(Unit)

def check(name, ok):
  match ok:
    case True{}: IO.print(name)
    case False{}: IO.die(Unit, 1, "FAIL " ++ name)

law wrote:
  for pair: File & Result<&1, &1, U32 & String, Unit>
  IO(Unit)

def wrote(pair):
  (file, result) = pair
  do IO<Unit>:
    IO.pass(Unit, result)
    File.close(file)

law write:
  IO(Unit)

def write():
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_read_into", "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, bytes(10n, 1))
    wrote(p)

law slot_at:
  for r: Array<U32> & U32
  for want: U32
  for name: String
  IO(Array<U32>)

def slot_at(r, want, name):
  (a, got) = r
  do IO<Array<U32>>:
    check(name, U32.is_eq(got, want))
    return a

law slot:
  for a: Array<U32>
  for +i: U32
  for want: U32
  for name: String
  IO(Array<U32>)

def slot(a, i, want, name):
  slot_at(Array.get(U32, a, i), want, name)

law count:
  for r: Array<U32> & Result<&1, &1, U32 & String, U32>
  for want: U32
  for name: String
  IO(Array<U32>)

def count(r, want, name):
  (a, result) = r
  do IO<Array<U32>>:
    n : U32 <- IO.pass(U32, result)
    check(name, U32.is_eq(n, want))
    return a

law failed:
  for r: Array<U32> & Result<&1, &1, U32 & String, U32>
  for want: U32
  for name: String
  IO(Array<U32>)

def failed(r, want, name):
  (a, result) = r
  match result:
    case Done{value}: IO.die(Array<U32>, 1, "unexpected success: " ++ name)
    case Fail{error}:
      (code, message) = error
      do IO<Array<U32>>:
        check(name, U32.is_eq(code, want))
        return a

law into:
  for pair: File & (Array<U32> & Result<&1, &1, U32 & String, U32>)
  for want: U32
  for name: String
  IO(File & Array<U32>)

def into(pair, want, name):
  (file, r) = pair
  do IO<File & Array<U32>>:
    a : Array<U32> <- count(r, want, name)
    return (file, a)

law bad:
  for pair: File & (Array<U32> & Result<&1, &1, U32 & String, U32>)
  IO(Array<U32>)

def bad(pair):
  (file, r) = pair
  do IO<Array<U32>>:
    a : Array<U32> <- failed(r, 9, "read on write-only handle")
    File.close(file)
    return a

law last:
  for fa: File & Array<U32>
  IO(Unit)

def last(fa):
  (f, a) = fa
  do IO<Unit>:
    a : Array<U32> <- slot(a, 0, 67305985, "empty reads leave the array")
    File.close(f)

law eof:
  for fa: File & Array<U32>
  IO(Unit)

def eof(fa):
  (f, a) = fa
  do IO<Unit>:
    p : File & (Array<U32> & Result<&1, &1, U32 & String, U32>) <-
      File.read_into(f, 10, 4, a, 0)
    fa : File & Array<U32> <- into(p, 0, "read at the file's end")
    last(fa)

law ends:
  for fa: File & Array<U32>
  IO(Unit)

def ends(fa):
  (f, a) = fa
  do IO<Unit>:
    a : Array<U32> <- slot(a, 3, 100992003, "offset read lands at its slot")
    p : File & (Array<U32> & Result<&1, &1, U32 & String, U32>) <-
      File.read_into(f, 0, 4, a, 4)
    fa : File & Array<U32> <- into(p, 0, "read at the array's end")
    eof(fa)

law tail:
  for fa: File & Array<U32>
  IO(Unit)

def tail(fa):
  (f, a) = fa
  do IO<Unit>:
    a : Array<U32> <- slot(a, 0, 67305985, "bytes 1..4 little-endian")
    a : Array<U32> <- slot(a, 1, 134678021, "bytes 5..8 little-endian")
    a : Array<U32> <- slot(a, 2, 4294904329, "short tail keeps high bytes")
    a : Array<U32> <- slot(a, 3, 4294967295, "slot past the bytes untouched")
    p : File & (Array<U32> & Result<&1, &1, U32 & String, U32>) <-
      File.read_into(f, 2, 100, a, 3)
    fa : File & Array<U32> <- into(p, 4, "read stops at the array's end")
    ends(fa)

law after:
  for f: File
  for pair: File & (Array<U32> & Result<&1, &1, U32 & String, U32>)
  IO(Unit)

def after(f, pair):
  do IO<Unit>:
    q : File & (Array<U32> & Result<&1, &1, U32 & String, U32>) <-
      File.read_into(f, 0, 100, Array.new(U32, 2n, 4294967295), 0)
    a : Array<U32> <- bad(pair)
    a : Array<U32> <- slot(a, 0, 7, "failed read leaves the array")
    fa : File & Array<U32> <- into(q, 10, "read stops at the file's end")
    tail(fa)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    write()
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_read_into", "r"))
    w : File <- IO.try(File, File.open("/tmp/bend_io_file_read_into", "a"))
    p : File & (Array<U32> & Result<&1, &1, U32 & String, U32>) <-
      File.read_into(w, 0, 4, Array.new(U32, 2n, 7), 0)
    after(f, p)

#|read on write-only handle
#|failed read leaves the array
#|read stops at the file's end
#|bytes 1..4 little-endian
#|bytes 5..8 little-endian
#|short tail keeps high bytes
#|slot past the bytes untouched
#|read stops at the array's end
#|offset read lands at its slot
#|read at the array's end
#|read at the file's end
#|empty reads leave the array
