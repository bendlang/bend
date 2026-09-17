# {a != b : T} desugars at parse time to {a == b : T} -> Empty: no
# negated Eql node and no minted def exist anywhere (bend3 minted
# Empty.Not; bend unfolds structurally in the parser)
import Base

law NEQ01:
  Type

def NEQ01():
  {0n != 1n : Nat}

law main:
  Type

def main():
  NEQ01()

#|@_:{0n == 1n : Nat} -> Empty
