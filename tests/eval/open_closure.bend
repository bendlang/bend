# bend3's --eval printed an unapplied def normalized UNDER its binders;
# bend's snf keeps a bare ref closed (eval_toplevel_ref_print pins
# that), and the open rendering lives on the --show lane: the parsed
# body prints with its params peeled, exactly bend3's shape
import Base

law pipe:
  for f: U32 -> U32
  for g: U32 -> U32
  U32 -> U32

def pipe(f, g):
  x => g(f(x))

law main:
  IO(Unit)

def main():
  n = U32.to_nat(pipe(a => (a + 1 : U32), b => (b * 2 : U32))(5))
  IO.print(Nat.show(n))

#|12
