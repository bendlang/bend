# comp pin (page_comp_param_match): bend3's template body matching on
# its ~ param died at spec mint with the cannot-be-matched-on page.
# bend's ~ law t checks once with f an opaque constant, and a match on
# it is a match on no parameter: refused at t, before any instance.
import Base

law t:
  for ~f: U32 -> U32
  U32

def t(f):
  match f:
    case U32{w}:
      0

law main:
  U32

def main():
  t(x => (x + 1 : U32))

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{U32: (w => 0)}
#|Location: t
#|12 |   match f:
#|13>|     case U32{w}:
#|   |          ^^^^^^
#|14 |       0
#|exit 1
