# bend3's literal-countdown peel (comp_loops C.unrl) pinned csrc
# shapes bend's tocl does not have (no peel pass, and the key
# dispatch's literal patterns are word views tocl refuses anyway);
# the loop's VALUE carries on a Nat countdown, interp and js
import Base

law key:
  for j: U32
  U32

def key(j):
  match j:
    case 0:
      13
    case 1:
      57
    case j:
      31

law mix:
  for  n: Nat
  for +j: U32
  for  x: U32
  U32

def mix(n, j, x):
  match n:
    case Zero{}:
      x
    case Succ{k}:
      mix(k, (j + 1 : U32), ((x * 5 + key(j)) .&. 65535 : U32))

law main.out:
  Nat

def main.out():
  U32.to_nat((mix(6n, 0, 1) + mix(6n, 0, 2) : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|77975n
