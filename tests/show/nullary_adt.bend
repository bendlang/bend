# the shower prints a nullary ADT as its bare name: `U32<>` was
# emitted into every error and --show while the parser refuses that
# text, since <> is the cons operator (AUDIT 6b pinned); an applied
# ADT keeps its angle brackets
import Base

law scalar:
  Type

def scalar():
  U32

law table:
  Type

def table():
  Map<&2, U32>

law main:
  Nat

def main():
  U32.to_nat(3)

#|3n
