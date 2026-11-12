# a typed let is still found when its type holds a bracket, a quote, an
# `=` or a `#` inside a literal, and when a comment sits before its `=`
import Base

def main() -> U32:
  p : {")" == ")" : String} = {==}
  q : {"'" == "'" : String} = {==}
  r : {"#=" == "#=" : String} = {==}
  s : {''' == ''' : Char} = {==}
  t : U32 # a ) and a " in a comment
    = 7
  t

#|7
