# the compiler applies a closure through a def it synthesizes, once
# named Clo.apply: a user def at that name was never called, the lane
# ran the closure instead, and a checked False{} came back True{}. It is
# Clo~apply now, which no file can spell, so a Clo.apply is the user's
import Base

def Clo.apply(f: U32 -> Bool, x: U32) -> Bool:
  False{}

def yes(x: U32) -> Bool:
  True{}

def main() -> Bool:
  Clo.apply(yes, 0)

#|False{}
