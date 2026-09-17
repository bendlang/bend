# the frozen brace forms, each ONE term: `{x : T}` is Ann, `{a == b : T}`
# is Eql, `{==}` is refl. There is no statement reading of a brace.
# ported from bend3: Eql spells == (bend3 spelled =), ops become Base calls
import Base

law refl:
  {U32.add(1, 2) == 3 : U32}

def refl(): {==}

law app:
  for f: U32 -> U32
  for x: U32
  U32

def app(f, x):
  f(x)

law main:
  U32

def main():
  app(y => {U32.add(U32.mul(y, 10), 2) : U32}, 4)

#|42
