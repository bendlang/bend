import Base

# a native claim of the library cannot be filled by a later file
def IO(A):
  Empty

law boom:
  Empty

def boom():
  IO.pure(Unit, Unit{})

#|SOME PROOFS FAIL
#|Error:
#|- expected : '->' (a def with no return type fills a law; no law named IO is in scope)
#|- observed : ':'
#|Location:
#|3 | # a native claim of the library cannot be filled by a later file
#|4>| def IO(A):
#|  |          ^
#|5 |   Empty
#|exit 1
