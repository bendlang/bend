# a string or a nat literal is one Lit node; the compiler reads it as its
# chain wherever a term is read: a scrutinee folded at compile time, a nat
# past 256 (U32.to_nat), and "" at a borrowed parameter, which is packed
# (no heap) and so leaves the parameter borrowed: read raw, it owned len's
# parameter and heated String. The three lanes agree.
import Base

type Amount is Data:
  Amount{value: U32}

def Amount.literal(n: U32) -> Amount:
  Amount{n}

def Amount.add(a: Amount, b: Amount) -> Amount:
  Amount{x} = a
  Amount{y} = b
  Amount{U32.add(x, y)}

type Label is Data:
  Label{value: String}

def Label.literal(s: String) -> Label:
  Label{s}

type Tagged<-A: Type> is Type:
  Tagged{value: A}

def Tagged.literal(-A: Type, x: A) -> Tagged<A>:
  Tagged{x}

def literal_eq() -> {(42 : Amount) == Amount{42} : Amount}:
  {==}

def literal_surrogate() -> {("\u{d800}" : Label) == Label{"\u{d800}"} : Label}:
  {==}

def literal_list(x: U32) -> Tagged<List<&1, U32>>:
  ([x, 2] : Tagged<List<&1, U32>>)

def literal_char() -> {('a' : Tagged<Char>) == Tagged{'a'} : Tagged<Char>}:
  {==}

def literal_tuple() -> {((1, 2) : Tagged<(U32 & U32)>) == Tagged{(1, 2)} : Tagged<(U32 & U32)>}:
  {==}

def literal_scope() -> {(x = {1 : U32}; 2 : Amount) == Amount{2} : Amount}:
  {==}

def literal_named() -> {(U32.add(1, 2) : Amount) == 3 : U32}:
  {==}

def literal_braces() -> {({1 : U32} : Amount) == 1 : U32}:
  {==}

def literals_show(a: Amount, l: Label, t: Tagged<U32>) -> String:
  Amount{n} = a
  Label{s} = l
  Tagged{x} = t
  U32.show(n) ++ " " ++ s ++ " " ++ U32.show(x)

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
  s = literals_show((1 + (2 + 4) : Amount), ("abc" : Label), (9 : Tagged<U32>))
  IO.print(U32.show(a) ++ " " ++ U32.show(b) ++ " " ++ s)

#|97 310 7 abc 9
