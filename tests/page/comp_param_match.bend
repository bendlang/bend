# comp pin (page_comp_param_match): bend3's template body matching on
# its ~ param died at spec mint with the cannot-be-matched-on page.
# bend has no ~ params to mint; the ~ binder pins bend's own parse
# refusal before any match is reached.
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
#|- expected : a name
#|- observed : '~'
#|Location:
#|7 | law t:
#|8>|   for ~f: U32 -> U32
#|9 |   U32
#|exit 1
