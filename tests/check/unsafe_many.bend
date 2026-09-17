# @unsafe also lifts the Data wall on + binders: inside an unsafe
# def's types, a + domain forms at any kind, so a function may sit
# under a + binder (the safe checker rejects this: no function type
# is Data)
import Base

law twice:
  for f: @+g: (Nat -> Nat) -> Nat
  Nat

@unsafe
def twice(f):
  f(x => 1n+x)

law main:
  U32

def main(): 7

#|7
