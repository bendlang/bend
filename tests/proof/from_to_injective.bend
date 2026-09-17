# the readback bijection as THEOREMS, on Word directly (the ruled port
# of bend3's FROM_TO axiom kit: no hom roster exists, U32 IS Word(32n),
# and bend3's fits-guarded Nat-side statement becomes the condition-free
# word-side one): to_nat is injective at EVERY width -- equal bits ride
# double_inj through base's Nat.half_double, mixed bits die on parity
# (Nat.even_double against even_double_succ), and the hypothesis stays
# usable by returning it through a Pi after the split (bend matches
# never specialize a context hypothesis). five_back keeps bend3's
# closed instance, now closing by plain reduction where the axiom used
# to be trusted.
# ported from bend3: main keeps the golden 42
import Base

law Nat.pred:
  for n: Nat
  Nat

def Nat.pred(n):
  match n:
    case 0n:
      0n
    case 1n+p:
      p

law Nat.half:
  for m: Nat
  Nat

def Nat.half(m):
  match m:
    case 0n:
      0n
    case 1n:
      0n
    case 2n+r:
      1n+Nat.half(r)

law Nat.even:
  for m: Nat
  Bool

def Nat.even(m):
  match m:
    case 0n:
      True{}
    case 1n:
      False{}
    case 2n+r:
      Nat.even(r)

law Nat.half_double:
  for m: Nat
  {Nat.half(Nat.double(m)) == m : Nat}

def Nat.half_double(m):
  match m:
    case 0n:
      {==}
    case 1n+q:
      Equal.cong(Nat, Nat, y => 1n+y, Nat.half(Nat.double(q)), q, Nat.half_double(q))

law Nat.even_double:
  for m: Nat
  {Nat.even(Nat.double(m)) == True{} : Bool}

def Nat.even_double(m):
  match m:
    case 0n:
      {==}
    case 1n+q:
      Nat.even_double(q)

law Nat.even_double_succ:
  for m: Nat
  {Nat.even(1n+Nat.double(m)) == False{} : Bool}

def Nat.even_double_succ(m):
  match m:
    case 0n:
      {==}
    case 1n+q:
      Nat.even_double_succ(q)

law bmot:
  for b: Bool
  Type

def bmot(b):
  match b:
    case True{}:
      Unit
    case False{}:
      Empty

law true_ne_false:
  for e: {True{} == False{} : Bool}
  Empty

def true_ne_false(e):
  %e : bmot(_)
  Unit{}

law double_inj:
  for +x: Nat
  for +y: Nat
  for  e: {Nat.double(x) == Nat.double(y) : Nat}
  {x == y : Nat}

def double_inj(x, y, e):
  Equal.trans(Nat, x, Nat.half(Nat.double(y)), y, Equal.trans(Nat, x, Nat.half(Nat.double(x)), Nat.half(Nat.double(y)), Equal.sym(Nat, Nat.half(Nat.double(x)), x, Nat.half_double(x)), Equal.cong(Nat, Nat, z => Nat.half(z), Nat.double(x), Nat.double(y), e)), Nat.half_double(y))

law parity_clash:
  for +x: Nat
  for +y: Nat
  for  e: {Nat.double(x) == 1n+Nat.double(y) : Nat}
  Empty

def parity_clash(x, y, e):
  true_ne_false(Equal.trans(Bool, True{}, Nat.even(1n+Nat.double(y)), False{}, Equal.trans(Bool, True{}, Nat.even(Nat.double(x)), Nat.even(1n+Nat.double(y)), Equal.sym(Bool, Nat.even(Nat.double(x)), True{}, Nat.even_double(x)), Equal.cong(Nat, Bool, z => Nat.even(z), Nat.double(x), 1n+Nat.double(y), e)), Nat.even_double_succ(y)))

law succ_inj:
  for -x: Nat
  for -y: Nat
  for  e: {1n+x == 1n+y : Nat}
  {x == y : Nat}

def succ_inj(x, y, e):
  Equal.cong(Nat, Nat, z => Nat.pred(z), 1n+x, 1n+y, e)

law winj:
  for +n: Nat
  for +a: Word(n)
  for +b: Word(n)
  ({Word.to_nat(n, a) == Word.to_nat(n, b) : Nat} -> {a == b : Word(n)})

def winj(n, a, b):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          e => {==}
    case 1n+p:
      match a b:
        case WCon{False{}, at} WCon{False{}, bt}:
          e => Equal.cong(Word(p), Word(1n+p), y => WCon{False{}, y}, at, bt, winj(p, at, bt)(double_inj(Word.to_nat(p, at), Word.to_nat(p, bt), e)))
        case WCon{False{}, at} WCon{True{}, bt}:
          e => Empty.absurd({WCon{False{}, at} == WCon{True{}, bt} : Word(1n+p)}, parity_clash(Word.to_nat(p, at), Word.to_nat(p, bt), e))
        case WCon{True{}, at} WCon{False{}, bt}:
          e => Empty.absurd({WCon{True{}, at} == WCon{False{}, bt} : Word(1n+p)}, parity_clash(Word.to_nat(p, bt), Word.to_nat(p, at), Equal.sym(Nat, 1n+Nat.double(Word.to_nat(p, at)), Nat.double(Word.to_nat(p, bt)), e)))
        case WCon{True{}, at} WCon{True{}, bt}:
          e => Equal.cong(Word(p), Word(1n+p), y => WCon{True{}, y}, at, bt, winj(p, at, bt)(double_inj(Word.to_nat(p, at), Word.to_nat(p, bt), succ_inj(Nat.double(Word.to_nat(p, at)), Nat.double(Word.to_nat(p, bt)), e))))

law u32_to_nat_inj:
  for +a: U32
  for +b: U32
  ({U32.to_nat(a) == U32.to_nat(b) : Nat} -> {a == b : U32})

def u32_to_nat_inj(a, b):
  match a b:
    case U32{x} U32{y}:
      e => Equal.cong(Word(32n), U32, w => U32{w}, x, y, winj(32n, x, y)(e))

law five_back:
  {U32.from_nat(U32.to_nat(5)) == 5 : U32}

def five_back():
  {==}

law main.out:
  U32

def main.out():
  U32.from_nat(U32.to_nat(42))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
