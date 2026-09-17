# bend3's Cat read ++ at inferring positions over any List; bend's ++
# reads String.append (the wider List reading stays pending the
# author), so the string halves carry at plain lets (re-used strings
# bind +: String is Data) and the lengths answer on
# every lane
import Base

law go:
  for +s  : String
  for +sh : String
  U32

def go(s, sh):
  a = s ++ "!"
  b = "> " ++ s
  d = "a" ++ ("b" ++ s)
  e = sh ++ sh
  U32.from_nat(Nat.add(Nat.add(String.length(a), String.length(b)), Nat.add(String.length(d), String.length(e))))

law main.out:
  Nat

def main.out():
  U32.to_nat(go("hey", "!!"))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|18n
