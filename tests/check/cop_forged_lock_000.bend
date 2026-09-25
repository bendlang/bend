# the grade system has one duplication license: a + binder over a type
# whose kind reduces to Data. a book that never imports Base cannot
# forge one -- a def spelled Copiable is an ordinary def now (no lock),
# and a + binder over a Type-kinded datatype is still refused, so no
# forged Copiable licenses contraction at an affine type
law Copiable:
  for -T: Type
  Type

def Copiable(T):
  Type

type Aff is Type:
  Mk{}

type Two is Type:
  MkTwo{fst: Aff, snd: Aff}

law dup:
  for +x: Aff
  Two

def dup(x):
  MkTwo{x, x}

law main:
  Type

def main():
  Type

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: dup
#|19 | law dup:
#|20>|   for +x: Aff
#|   |           ^^^
#|21 |   Two
#|exit 1
