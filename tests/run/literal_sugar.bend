# literal sugar computes on every lane: strings as "..", nats as Nn,
# chars as '.', lists as [..], in one tuple main printed field by field
# ported from bend3: the def-per-block form becomes one tuple main
# (bend's CLI prints main only); the printer's own re-sugaring is
# pinned by tests/show
import Base

def nats(xs: List<&2, Nat>) -> String:
  match xs:
    case Nil{}:
      "Nil{}"
    case h <> t:
      "Con{" ++ Nat.show(h) ++ ", " ++ nats(t) ++ "}"

law main.value:
  (String & Nat & (U32 & U32) & Char & List<&2, Nat>)

def main.value():
  (String.append("hi", "\n"), Nat.add(1n, 2n), (3, 4), 'a', [5n, 6n])

law main.show:
  for t: (String & Nat & (U32 & U32) & Char & List<&2, Nat>)
  IO(Unit)

def main.show(t):
  (s, n, (a, b), c, xs) = t
  do IO<Unit>:
    Unit <- IO.write(s)
    Unit <- IO.print(Nat.show(n))
    Unit <- IO.print(U32.show(a) ++ " " ++ U32.show(b))
    Unit <- IO.print(SCon{c, SNil{}})
    IO.print(nats(xs))

law main:
  IO(Unit)

def main():
  main.show(main.value())

#|hi
#|3
#|3 4
#|a
#|Con{5, Con{6, Nil{}}}
