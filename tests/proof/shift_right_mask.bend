# the right-shift roster, on bend's own law (the ruled port of bend3's
# count-general SHR_HOM kit: no mask exists -- U32.shrn takes a Nat
# count and shifts out past the width): the one-step hom is the real
# theorem shr_half (a right shift halves the value, arm for arm through
# base's Word.shr.pad_to_nat and Nat.half_double), div4's composed
# spelling is shrn(2) by plain reduction, composition holds at any
# counts by base's U32.shrn_add, and the mask edges invert: 32 and 33
# shift to zero, proved closed.
# ported from bend3: mask semantics diverge by ruling, so main's golden
# is bend's own 25000 (bend3 answered 25385 through the mask)
import Base

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

law Nat.half_double:
  for m: Nat
  {Nat.half(Nat.double(m)) == m : Nat}

def Nat.half_double(m):
  match m:
    case 0n:
      {==}
    case 1n+q:
      Equal.cong(Nat, Nat, y => 1n+y, Nat.half(Nat.double(q)), q, Nat.half_double(q))

law Nat.half_double_succ:
  for m: Nat
  {Nat.half(1n+Nat.double(m)) == m : Nat}

def Nat.half_double_succ(m):
  match m:
    case 0n:
      {==}
    case 1n+q:
      Equal.cong(Nat, Nat, y => 1n+y, Nat.half(1n+Nat.double(q)), q, Nat.half_double_succ(q))

law Word.shr.pad_to_nat:
  for n: Nat
  for w: Word(n)
  {Word.to_nat(1n+n, Word.shr.pad(n, w)) == Word.to_nat(n, w) : Nat}

def Word.shr.pad_to_nat(n, w):
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+q:
      match w:
        case WCon{False{}, t}:
          Equal.cong(Nat, Nat, y => Nat.double(y), Word.to_nat(1n+q, Word.shr.pad(q, t)), Word.to_nat(q, t), Word.shr.pad_to_nat(q, t))
        case WCon{True{}, t}:
          Equal.cong(Nat, Nat, y => 1n+Nat.double(y), Word.to_nat(1n+q, Word.shr.pad(q, t)), Word.to_nat(q, t), Word.shr.pad_to_nat(q, t))

law U32.shrn_add:
  for k: Nat
  for m: Nat
  for a: U32
  {U32.shrn(U32.shrn(a, m), k) == U32.shrn(a, Nat.add(k, m)) : U32}

def U32.shrn_add(k, m, a):
  match k:
    case 0n:
      {==}
    case 1n+q:
      %U32.shrn_add(q, m, a) : {U32.shr(U32.shrn(U32.shrn(a, m), q)) == U32.shr(_) : U32}
      {==}

law shr_half:
  for +n: Nat
  for +w: Word(n)
  {Word.to_nat(n, Word.shr(n, w)) == Nat.half(Word.to_nat(n, w)) : Nat}

def shr_half(n, w):
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{False{}, t}:
          Equal.trans(Nat, Word.to_nat(1n+p, Word.shr.pad(p, t)), Word.to_nat(p, t), Nat.half(Nat.double(Word.to_nat(p, t))), Word.shr.pad_to_nat(p, t), Equal.sym(Nat, Nat.half(Nat.double(Word.to_nat(p, t))), Word.to_nat(p, t), Nat.half_double(Word.to_nat(p, t))))
        case WCon{True{}, t}:
          Equal.trans(Nat, Word.to_nat(1n+p, Word.shr.pad(p, t)), Word.to_nat(p, t), Nat.half(1n+Nat.double(Word.to_nat(p, t))), Word.shr.pad_to_nat(p, t), Equal.sym(Nat, Nat.half(1n+Nat.double(Word.to_nat(p, t))), Word.to_nat(p, t), Nat.half_double_succ(Word.to_nat(p, t))))

law shr_hom_one:
  for +a: U32
  {U32.to_nat(U32.shrn(a, 1n)) == Nat.half(U32.to_nat(a)) : Nat}

def shr_hom_one(a):
  match a:
    case U32{w}:
      shr_half(32n, w)

law div4:
  for a: U32
  U32

def div4(a):
  U32.shr(U32.shr(a))

law div4_shrn:
  for a: U32
  {div4(a) == U32.shrn(a, 2n) : U32}

def div4_shrn(a):
  {==}

law shrn_compose:
  for a: U32
  {U32.shrn(U32.shrn(a, 16n), 16n) == U32.shrn(a, 32n) : U32}

def shrn_compose(a):
  U32.shrn_add(16n, 16n, a)

law shr32_gone:
  {U32.shrn(77, 32n) == 0 : U32}

def shr32_gone():
  {==}

law shr33_gone:
  {U32.shrn(77, 33n) == 0 : U32}

def shr33_gone():
  {==}

law main.out:
  U32

def main.out():
  (div4(103) * 1000 + (77 >> 33n) * 10 + (5 >> 32n) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|25000
