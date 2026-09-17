# do-notation end-to-end over the 2-param base Result monad: binds
# desugar to Result.bind/Result.pure with the lead type threading
# unchanged, covering a bind line, a discard line and a `return` tail.
# ported from bend3: the local Result becomes base Result (Done/Fail),
# binds carry their per-line type, the discard line spells its yield
# type, result 105 shown as a Nat
import Base

law half:
  @x:U32 -> Result<&2, &2, U32, U32>

def half():
  x => Done{U32.div(x, 2)}

law note:
  @x:U32 -> Result<&2, &2, U32, U32>

def note():
  x => Done{0}

law run:
  Result<&2, &2, U32, U32>

def run():
  do Result<&2, &2, U32, U32>:
    r1 : U32 <- half(10)
    U32 <- note(3)
    return U32.add(r1, 100)

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

#|105n
