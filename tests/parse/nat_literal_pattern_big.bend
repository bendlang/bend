# a nat literal past NAT_LITERAL_MAX parses as U32.to_nat(n) and still
# expands into the Succ chain its pattern needs.
import Base

def g(b: Nat) -> Nat:
  match b:
    case 257n:
      1n
    case p:
      0n

def main() -> Nat:
  g(257n)

#|1n
