# f32: dynamic compares feed a U32 count; a division chain feeds the
# integer digest. the < becomes F32.is_lt through a Bool, counters
# walk Nats; no interpreter lane (F32 axioms are stuck there)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law step:
  for +n: Nat
  for  x: F32
  F32

def step(n, x):
  match n:
    case 0n:
      x
    case 1n+p:
      step(p, F32.div(F32.add(x, U32.to_f32(U32.add(1, U32.from_nat(p)))), fl(2, 1)))

law count:
  for +n  : Nat
  for acc : U32
  U32

def count(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      count(p, U32.add(acc, bu(F32.is_lt(U32.to_f32(U32.add(1, U32.from_nat(p))), fl(11, 2)))))

law main.out:
  U32

def main.out():
  U32.add(F32.to_u32(F32.mul(step(20n, fl(3, 2)), fl(1000000, 1))), count(9n, 0))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1999985
