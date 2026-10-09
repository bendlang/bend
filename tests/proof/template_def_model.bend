# An opaque injectivity proof needs a checked def as its model; constructor
# and reflexivity models cannot prove its dependent result. The witness is
# declared after the generic root, so model lookup must not depend on order.
import Base

type N is Data:
  Z{}
  S{p: N}

def pred(n: N) -> N:
  match n:
    case Z{}: Z{}
    case S{p}: p

def use(~F: @a: N -> @b: N -> {S{a} == S{b} : N} -> {a == b : N},
  a: N, b: N, e: {S{a} == S{b} : N}) -> {a == b : N}:
  F(a, b, e)

def inj(a: N, b: N, e: {S{a} == S{b} : N}) -> {a == b : N}:
  %x@e : {pred(S{a}) == pred(_) : N}
  {==}

def main() -> {Z{} == Z{} : N}:
  use(~inj, Z{}, Z{}, {==})

#|{==}
