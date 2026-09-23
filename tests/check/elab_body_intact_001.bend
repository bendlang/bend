# a law's type names a def declared later: a dead forward reference
# sees the bodiless claim, which no rewrite can force before its fill,
# so the equation holds by its two stuck sides and the fill runs after.
# ported from bend3: bend3's --no-halt forward door checked this
# order; bend refused until every def declared up front
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

#|42
