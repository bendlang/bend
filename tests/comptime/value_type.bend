# a compile-time parameter may hold a value (the literal folds into the
# instance) or a type (the instance is monomorphic); ~_ takes an
# argument nobody can name
import Base

def id(~A: Type, x: A) -> A:
  x

def scale(~n: U32, x: U32) -> U32:
  (x * n : U32)

def drop(~_: Nat, x: U32) -> U32:
  x

def main() -> IO(Unit):
  a = scale(~3, 5)
  b = U32.inc(scale(~2, id(~U32, 4)))
  IO.print(U32.show((a + b + drop(~7n, 1) : U32)))

#|25
