# A leaf handed off from a forky segment under ! runs on the host's 2 GiB
# stack; the device hands no leaf off (#930), so the same leaf runs there on
# heap continuations at any depth. Only a bang's root and a fork kid run on
# a lane's STAK_LEN-word stack on the device: three exit words and one a
# level, so 2045 levels fill it exactly.
import Base

def deep(+n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(1, deep(p))

def two(+n: Nat) -> U32:
  c = deep(2045n)
  a b = deep(n) deep(n)
  U32.add(U32.add(a, b), c)

def main() -> IO(Unit):
  IO.print(U32.show(two!(1n)))

#|2047
