# Model lookup can use a checked proof declared after the template.
# A proof with a different type must not match.
import Base

type N is Data:
  Z{}
  S{p: N}

def refl(-a: N) -> {a == a : N}:
  {==}

law use:
  for ~F: @a: N -> @b: N -> {S{a} == S{b} : N} -> {a == b : N}
  for a: N
  for b: N
  for e: {S{a} == S{b} : N}
  {a == b : N}

def use(F, a, b, e):
  F(a, b, e)

def pred(n: N) -> N:
  match n:
    case Z{}: Z{}
    case S{p}: p

def inj(a: N, b: N, e: {S{a} == S{b} : N}) -> {a == b : N}:
  %x@e : {pred(S{a}) == pred(_) : N}
  {==}

def main() -> N:
  Z{}

#|Z{}
