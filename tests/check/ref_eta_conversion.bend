# two defs with the same body convert: a bare def is under-applied, so
# a function, and term_compare applies both to a fresh var, as it does
# when one side is a lambda. once it compared the names alone, so f and
# g each converted with x => x but not with each other (#1028)
import Base

def f(x: U32) -> U32:
  x

def g(x: U32) -> U32:
  x

def add(a: U32, b: U32) -> U32:
  U32.add(a, b)

def plus(a: U32, b: U32) -> U32:
  U32.add(a, b)

def main() -> {f == g : U32 -> U32}:
  {==}

def two() -> {add == plus : U32 -> U32 -> U32}:
  {==}

#|{==}
