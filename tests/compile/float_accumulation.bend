# f32: dynamic accumulation (exact ops feed an integer digest); the
# counter walks a Nat and the fl helper builds its operands by
# division; no interpreter lane (F32 axioms are stuck there)
import Base

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law loop:
  for +n  : Nat
  for acc : F32
  F32

def loop(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      loop(p, F32.add(acc, F32.mul(U32.to_f32(U32.add(1, U32.from_nat(p))), fl(1, 2))))

law main.out:
  U32

def main.out():
  F32.to_u32(F32.mul(loop(10n, fl(1, 4)), fl(100, 1)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2775
