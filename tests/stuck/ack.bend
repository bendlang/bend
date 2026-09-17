# Ackermann, whose inner arm regrows the first argument: ack(1n, 1n+x)
# steps to ack(0n, ack(1n, x)), the outer call reduces to 1n+ and the
# inner sticks on x. An evaluator that unrolled the stuck call's arms
# would never stop here; the goal is 1n+ack(1n, x).
import Base

law ack:
  for +m: Nat
  for  n: Nat
  Nat

def ack(m, n):
  match m:
    case 0n:
      1n+n
    case 1n+p:
      match n:
        case 0n:
          ack(p, 1n)
        case 1n+q:
          ack(p, ack(1n+p, q))

law main:
  @x:Nat -> Nat

def main():
  x => ack(1n, 1n+x)

#|x => 1n+ack(1n, x)
