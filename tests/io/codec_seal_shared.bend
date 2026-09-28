# io (io_codec_seal_shared): a string built ON THE SEAM and handed to
# a program that refcounts String must arrive SEALED. This book keeps
# a + String binder (String is Data), so SCon is hot and its hot bit in
# CID_T is 1: the kit's io_str codec (the file leg shares
# File.read's answer) rfc_seals the tail it stores. Unsealed, a shared
# take meets a raw non-trivial field and span_fade posts error 8.
import Base

law twice:
  for +s: String
  String

def twice(s):
  String.append(s, s)

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(U32)

def read_go(m):
  (f, r) = m
  do IO<U32>:
    data : String <- IO.pass(String, r)
    p    : Unit <- IO.print(twice(data))
    x    : Unit <- File.close(f)
    return 0

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Unit <- IO.print(twice(U32.show(41)))
    f : File <- IO.try(File, File.open("/tmp/bend_io_hots.tmp", "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "abc")
    x : Unit <- write_go(w)
    g : File <- IO.try(File, File.open("/tmp/bend_io_hots.tmp", "r"))
    m : File & Result<&1, &1, (U32 & String), String> <- File.read(g, 64)
    read_go(m)

#|4141
#|abcabc
