# a foreign fill dodges the grade wall no better than a local one: a
# foreign def must answer base's IO, and a book
# whose IO is a transparent local def (IO(A) = A) has none -- so a
# foreign "duplicator" of an affine value cannot ride an import line
law IO:
  for A: Type
  Type
def IO(A):
  A

type Two<-A: Type> is Type:
  MkTwo{fst: A, snd: A}

law magic:
  for -A: Type
  for  x: A
  IO(Two<A>)
def magic(A, x):
  import "./noop.js"

law dup:
  for -A: Type
  for  x: A
  Two<A>
def dup(A, x):
  magic(A, x)

#|Error:
#|- expected : a foreign definition returning base IO(...) directly (return type aliases are not unfolded)
#|- observed : magic
#|Location: magic
#|16 |   for  x: A
#|17>|   IO(Two<A>)
#|   |   ^^^^^^^^^^
#|18 | def magic(A, x):
#|exit 1
