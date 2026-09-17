# a case naming a constructor no datatype declares: the error names
# the case's tag (bend tags are global, so this is unknown-at-parse,
# never an internal flattened match)
type MB is Data:
  T{}
  F{}
law not:
  for b: MB
  MB

def not(b):
  match b:
    case Tr{}:
      F{}
    case F{}:
      T{}
law main:
  MB

def main(): not(T{})

#|Error:
#|- message  : a declared constructor (unknown: Tr)
#|Location:
#|12 |   match b:
#|13>|     case Tr{}:
#|14 |       F{}
#|exit 1
