# An unused template gets a model from a checked proof of the same type.
# No call supplies an instance of use.
import Base

type N is Data:
  Z{}
  S{p: N}

def pred(n: N) -> N:
  match n:
    case Z{}: Z{}
    case S{p}: p

def inj(a: N, b: N, e: {S{a} == S{b} : N}) -> {a == b : N}:
  %x@e : {pred(S{a}) == pred(_) : N}
  {==}

def use(~F: @a: N -> @b: N -> {S{a} == S{b} : N} -> {a == b : N},
  a: N, b: N, e: {S{a} == S{b} : N}) -> {a == b : N}:
  F(a, b, e)

def main() -> N:
  Z{}

#|Z{}
