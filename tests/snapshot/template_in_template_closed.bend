# a template body that calls another template at a closed ~ argument: the
# body's check mints nothing (its overlay shares the instance table), and
# the inner instance is minted when the outer template is instantiated
import Base

def inc(x: U32) -> U32:
  (x + 1 : U32)

def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def quad(~g: U32 -> U32, +x: U32) -> U32:
  (twice(~inc, x) + g(x) : U32)

def main() -> U32:
  (quad(~inc, 1) + twice(~inc, 5) : U32)

#|12
