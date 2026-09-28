import Base

def small(n: Nat) -> Nat:
  3n+n

def large(n: Nat) -> Nat:
  257n+n

def main() -> List<Nat>:
  [3n+4n, small(5n), large(5n)]

#|[7n, 8n, 262n]
