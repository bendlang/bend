# a def referencing a later def fails as undefined: resolution follows
# book order, so prf cannot force seed's body before it exists.
# ported from bend3: bend3's --no-halt forward door checked this
# order; bend pins the refusal
import Base

law prf:
  {seed() == seed() : U32}

def prf():
  {==}

law seed:
  U32

def seed():
  42

law main:
  U32

def main():
  seed()

#|Error:
#|- expected : a defined name
#|- observed : seed
#|Location: prf
#|7 | law prf:
#|8>|   {seed() == seed() : U32}
#|9 |
#|exit 1
