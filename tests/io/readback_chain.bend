# a user constructor with Nat fields, built at runtime and printed by
# a local show: the interpreter, JS and C print the same spine.
# ported from bend3: bend3's tag-punned improper-chain readback
# (1<>2) is bend3-only; the pin here is the same shape's spelled ctor
# (Nat fields for readability)
import Base

type Chain is Data:
  ChCons{h: Nat, t: Nat}

def Chain.show(c: Chain) -> String:
  match c:
    case ChCons{h, t}:
      "ChCons{" ++ Nat.show(h) ++ ", " ++ Nat.show(t) ++ "}"

law main:
  IO(Unit)

def main():
  IO.print(Chain.show(ChCons{1n, 2n}))

#|ChCons{1, 2}
