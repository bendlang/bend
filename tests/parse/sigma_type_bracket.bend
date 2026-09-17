# a &-sigma passed as a type argument is a plain leading argument,
# PARENTHESIZED: pick((&x:A -> B), v) -- the arrow would otherwise
# swallow the following commas at the call's precedence.
# ported from bend3: def <T> params become an erased -T bind
import Base

law pick:
  for -T: Type
  for  x: T
  T

def pick(T, x):
  x

law w:
  &y:Nat -> {y == y : Nat}

def w(): pick((&y:Nat -> {y == y : Nat}), (0n, {==}))

law main:
  &y:Nat -> {y == y : Nat}

def main(): w

#|(0n, {==})
