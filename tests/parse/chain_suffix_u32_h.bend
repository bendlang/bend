# a ": U32" before the ")" names every operator inside the parens:
# nested parens inherit it, a call argument takes its own parens, and
# a let value is a parenthesized chain
import Base

def f(a: U32, b: U32, c: U32) -> U32:
  (a + b * c : U32)

def g(a: U32, b: U32, c: U32) -> U32:
  U32.add((a + b : U32), c)

def main(+a: U32, b: U32, c: U32) -> U32:
  x = (a << 2n .|. b : U32)
  ((x - c) * a : U32)

#|a => b => c => U32.mul(U32.sub(U32.or(U32.shl(U32.shl(a)), b), c), a)
