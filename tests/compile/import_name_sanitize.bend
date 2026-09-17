# bend3's ':'-qualified canonical import names had to pass the C
# sanitizer; bend imports alias whole files and the corpus is flat
# single files, so no canonical name exists -- the value half carries:
# the same fold over string chars answers on every lane
import Base

law len6:
  for s: String
  U32

def len6(s):
  match s:
    case SCon{Chr{c}, t}:
      (1 + len6(t) : U32)
    case SNil{}:
      0

law main.out:
  Nat

def main.out():
  U32.to_nat((len6("hello") * 10 + len6("") : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|50n
