import Base

# a native claim of the library cannot be filled by a later file
def IO(A):
  Empty

law boom:
  Empty

def boom():
  IO.pure(Unit, Unit{})

#|Error:
#|- expected : a fresh name (duplicate declaration: IO)
#|- observed : '('
#|Location:
#|3 | # a native claim of the library cannot be filled by a later file
#|4>| def IO(A):
#|5 |   Empty
#|exit 1
