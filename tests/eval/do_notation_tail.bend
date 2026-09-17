# a raw expression as a do-block's last line is the monadic tail, used
# as-is; a bind line's type B is per-line (here Unit) while the head's
# last param stays the block's result type -- and the Fail
# short-circuits through Result.bind.
# ported from bend3: base Result (Done/Fail); bend has no match-in-do
# (match heads a def body, not a term), so the bend3 tail's match
# collapses to the pure tail it computed to; result 7 shown as a Nat
import Base

law boom:
  @x:U32 -> Result<&2, &2, U32, Unit>

def boom():
  x => Fail{x}

law run:
  Result<&2, &2, U32, U32>

def run():
  do Result<&2, &2, U32, U32>:
    u : Unit <- boom(7)
    Result.pure(&2, &2, U32, U32, 1)

law unwrap:
  for r: Result<&2, &2, U32, U32>
  U32

def unwrap(r):
  match r:
    case Done{v}:
      v
    case Fail{x}:
      x

law main.out:
  Nat

def main.out():
  U32.to_nat(unwrap(run()))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|7n
