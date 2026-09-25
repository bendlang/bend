# the indirect forgery: a Data-declared box over an affine parameter
# would hand a Type-kinded value the Data license through its field.
# adt_valid refuses the live field at the Data declaration (its kind
# Type is not entailed by Data), so no wrapper converts an affine
# value into a duplicable one
type Unit is Data:
  One{}

type Box<-A: Type> is Data:
  Mk{x: A}

law dup:
  for -A: Type
  for +b: Box<A>
  Box<A>

def dup(A, b):
  match b:
    case Mk{x}:
      Mk{x}

law main:
  Type

def main():
  Type

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- A : Type
#|Location: Mk
#| 9 | type Box<-A: Type> is Data:
#|10>|   Mk{x: A}
#|   |         ^
#|11 | 
#|exit 1
