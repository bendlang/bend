# bend3's stuck-wnf tripwire, re-pinned as bend's own live class: the
# 16-deep share chain's counter is gone (no --stats), but the compact-
# chain claim itself fails here -- a division's result fed through a
# multiplication, nested twice as a match's computed scrutinee, blows
# the evaluator; the intended golden is the value every sound lane
# answers
import Base

law prng:
  for +s: U32
  U32

def prng(s):
  (s / 3 * 65537 : U32)

law mix.go:
  for w: U32
  U32

def mix.go(w):
  match w:
    case 0:
      1
    case n:
      2

law mix:
  for s0: U32
  U32

def mix(s0):
  mix.go(prng(prng(s0)))

law main.out:
  Nat

def main.out():
  U32.to_nat(mix(7))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|2n
