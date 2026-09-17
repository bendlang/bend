# an accumulator: rev walks the two known cells into acc and sticks
# on the open tail, so the goal is rev(xs, Con{x, Con{1n, Nil{}}}),
# with the accumulator built and the call kept.
import Base

law rev:
  for l: List<Nat>
  for acc: List<Nat>
  List<Nat>

def rev(l, acc):
  match l:
    case Nil{}:
      acc
    case h <> t:
      rev(t, h <> acc)

law main:
  @x:Nat -> @xs:List<Nat> -> List<Nat>

def main():
  x => xs => rev(1n <> x <> xs, Nil{})

#|x => xs => rev(xs, [x, 1n])
