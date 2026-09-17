# regression witness (fefd150): a single-field record survives the
# record fuse -- the producer arm once wrote the WHOLE constructor into
# the lone field local, rebuilding a second constructor around it
# (a raw term encoding read back as a Nat, or a SIGKILL when shared).
import Base

type Box is Data:
  Box{v: Nat}

type Dir is Data:
  Lft{}
  Rgt{}

type DBox is Data:
  DBox{d: Dir}

law mkbox:
  for n: Nat
  Box

def mkbox(n):
  match n:
    case 0n:
      Box{7n}
    case 1n+p:
      mkbox(p)

law mkd:
  for n: Nat
  DBox

def mkd(n):
  match n:
    case 0n:
      DBox{Rgt{}}
    case 1n+p:
      mkd(p)

law unbox:
  for b: Box
  Nat

def unbox(b):
  match b:
    case Box{v}:
      v

law twice:
  for +b: Box
  Nat

def twice(b):
  Nat.add(unbox(b), unbox(b))

law dval:
  for b: DBox
  Nat

def dval(b):
  match b:
    case DBox{Lft{}}:
      1n
    case DBox{Rgt{}}:
      2n

law main.out:
  Nat

def main.out():
  Nat.add(unbox(mkbox(3n)), Nat.add(twice(mkbox(5n)), dval(mkd(4n))))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|23n
