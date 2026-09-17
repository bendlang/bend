# string escapes are real characters: \n is one Char, \\ is one Char.
# ported from bend3: List.length over Chars becomes a local String
# walk returning Nat (bend base has no length)
import Base

law slen:
  for s: String
  Nat

def slen(s):
  match s:
    case SNil{}:
      0n
    case SCon{h, t}:
      Succ{slen(t)}

law main.out:
  Pair(Nat, Nat)

def main.out():
  (slen("a\nb"), slen("\\"))

law main:
  IO(Unit)

law main.pr:
  for t: Pair(Nat, Nat)
  IO(Unit)

def main.pr(t):
  Tuple{a, b} = t
  s = String.append(Nat.show(a), String.append("n, ", String.append(Nat.show(b), "n}")))
  IO.print(String.append("Tuple{", s))

def main():
  main.pr(main.out())

#|Tuple{3n, 1n}
