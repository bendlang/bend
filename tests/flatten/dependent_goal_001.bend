# bend3's nested dependent computed matches: the goal mentions both
# scrutinees. bend's computed match never specializes, by design, so
# the applied spelling pins bend's own refusal
# ported from bend3: the numeric columns become ctor columns
type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law not:
  for a: Bl
  Bl

def not(a):
  match a:
    case T{}:
      F{}
    case F{}:
      T{}

law and:
  for a: Bl
  for b: Bl
  Bl

def and(a, b):
  match a, b:
    case T{}, b:
      b
    case F{}, b:
      F{}

law pos:
  for a: W
  Bl

def pos(a):
  match a:
    case Z{}:
      F{}
    case n:
      T{}

law odd:
  for a: W
  Bl

def odd(a):
  match a:
    case Z{}:
      F{}
    case S{n}:
      not(odd(n))

law main:
  for n: W
  {and(pos(n), odd(n)) == and(odd(n), pos(n)) : Bl}

def main(n):
  \{T: \{T: {==}; F: {==}}(odd(n)); F: \{T: {==}; F: {==}}(odd(n))}(pos(n))

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{T: \{T: {==}; F: {==}}(odd(n)); F: \{T: {==}; F: {==}}(odd(n))}
#|Context:
#|- n : W
#|Location: main
#|62 | def main(n):
#|63>|   \{T: \{T: {==}; F: {==}}(odd(n)); F: \{T: {==}; F: {==}}(odd(n))}(pos(n))
#|64 |
#|exit 1
