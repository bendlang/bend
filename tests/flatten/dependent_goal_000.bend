# bend3's dependent computed match: the goal mentions the scrutinee
# even(n) and the with-equality rewrites it. bend bans the applied
# match outright, so the spelling pins the ban itself
# ported from bend3: the numeric column becomes a ctor column
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

law even:
  for a: W
  Bl

def even(a):
  match a:
    case Z{}:
      T{}
    case S{n}:
      not(even(n))

law main:
  for n: W
  {not(not(even(n))) == even(n) : Bl}

def main(n):
  \{T: {==}; F: {==}}(even(n))

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{T: {==}; F: {==}}
#|Context:
#|- n : W
#|Location: main
#|39 | def main(n):
#|40>|   \{T: {==}; F: {==}}(even(n))
#|   |   ^^^^^^^^^^^^^^^^^^^
#|41 |
#|exit 1
