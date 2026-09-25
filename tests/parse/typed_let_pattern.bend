# a typed let binds a name: its value is {v : T}, and a pattern let
# scrutinizes a variable, so a pattern with a type is refused where it
# is written, as a parallel let refuses one
import Base

type Aa is Type:
  Kk{x: U32, y: U32}

def g(b: Aa) -> U32:
  Kk{a, c} : Aa = b
  (a + c : U32)

def main() -> U32:
  g(Kk{1, 2})

#|Error:
#|- message  : a name (a parallel or typed let binds names; destructure in its body)
#|Location:
#| 9 | def g(b: Aa) -> U32:
#|10>|   Kk{a, c} : Aa = b
#|   |   ^^^^^^^^
#|11 |   (a + c : U32)
#|exit 1
