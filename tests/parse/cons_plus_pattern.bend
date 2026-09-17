# h <> t is Con{h, t} in a term and in a pattern; +h <> t marks the
# head reusable, as Con{+h, t} does; a chain ends in a list literal
import Base

def twice(xs: List<U32>) -> U32:
  match xs:
    case +h <> t:
      (h + h + twice(t) : U32)
    case []:
      0

def main() -> U32:
  twice(1 <> 2 <> [3])

#|12
