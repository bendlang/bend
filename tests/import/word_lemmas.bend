# bend3's width-8 Word module and its on-import lemmas; bend's base
# Word is width-generic, so the same kit instantiates at 8n directly:
# add computes (5 + 3 reads back 8n through Word.to_nat) and the
# add_comm/add_zero lemmas check at the fixed width
import Base

law Word.add_zero:
  for n: Nat
  for w: Word(n)
  {Word.add(n, w, Word.zero(n)) == w : Word(n)}

def Word.add_zero(n, w):
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{False{}, t}:
          Equal.cong(Word(p), Word(1n+p), y => WCon{False{}, y}, Word.add(p, t, Word.zero(p)), t, Word.add_zero(p, t))
        case WCon{True{}, t}:
          Equal.cong(Word(p), Word(1n+p), y => WCon{True{}, y}, Word.add(p, t, Word.zero(p)), t, Word.add_zero(p, t))

law w5:
  Word(8n)

def w5():
  WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WNil{}}}}}}}}}

law w3:
  Word(8n)

def w3():
  WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WNil{}}}}}}}}}

law comm_at_8:
  for a: Word(8n)
  for b: Word(8n)
  {Word.add(8n, a, b) == Word.add(8n, b, a) : Word(8n)}

def comm_at_8(a, b):
  Word.add_comm(8n, a, b)

law zero_at_8:
  for w: Word(8n)
  {Word.add(8n, w, Word.zero(8n)) == w : Word(8n)}

def zero_at_8(w):
  Word.add_zero(8n, w)

law main.out:
  Nat

def main.out():
  Word.to_nat(8n, Word.add(8n, w5(), w3()))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|8n
