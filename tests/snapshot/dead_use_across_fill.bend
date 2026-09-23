# an open law in a dead position (a type), then its fill, then a live use
import Base

law L:
  for n: Nat
  Nat

def spec(n: Nat) -> Type:
  {L(n) == n : Nat}

def L(n):
  n

def proof(n: Nat) -> spec(n):
  {==}

def main() -> Nat:
  L(3n)

#|3n
