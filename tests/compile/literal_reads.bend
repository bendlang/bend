# a string or a nat literal is one Lit node; the compiler reads it as its
# chain wherever a term is read: a scrutinee folded at compile time, a nat
# past 256 (U32.to_nat), and "" at a borrowed parameter, which is packed
# (no heap) and so leaves the parameter borrowed: read raw, it owned len's
# parameter and heated String. The three lanes agree.
import Base

def head(s: String) -> U32:
  match s:
    case SNil{}:
      0
    case SCon{c, t}:
      Char.to_u32(c)

def len(s: String) -> Nat:
  match s:
    case SNil{}:
      0n
    case SCon{c, t}:
      Nat.add(1n, len(t))

def rep(n: Nat, +s: String) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(U32.from_nat(len(s)), rep(p, s))

def main() -> IO(Unit):
  a = U32.add(head("abc"), head(""))
  b = U32.add(rep(2n, "hello"), U32.from_nat(Nat.add(len(""), 300n)))
  IO.print(U32.show(a) ++ " " ++ U32.show(b))

#|97 310
