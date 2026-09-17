# bend3's gen_records miniature: a wide 8-field record built, rotated
# twice and read. Its checker counter is gone (no --stats); the record
# pipeline carries, mk's contracted seed rides a +U32 binder (U32 is
# Data), and every lane answers
import Base

type R8 is Data:
  Mk8{a: U32, b: U32, c: U32, d: U32, e2: U32, f: U32, g: U32, h: U32}

law mk:
  for +n: U32
  R8

def mk(n):
  Mk8{n, (n + 1 : U32), (n + 2 : U32), (n + 3 : U32), (n + 4 : U32), (n + 5 : U32), (n + 6 : U32), (n + 7 : U32)}

law rot:
  for r: R8
  R8

def rot(r):
  match r:
    case Mk8{a, b, c, d, e2, f, g, h}:
      Mk8{b, c, d, e2, f, g, h, (a + 1 : U32)}

law top:
  for r: R8
  U32

def top(r):
  match r:
    case Mk8{a, b, c, d, e2, f, g, h}:
      (a + h : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(top(rot(rot(mk(10)))))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|24n
