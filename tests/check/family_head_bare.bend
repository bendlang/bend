# a bare parameterized family head is not a term: D<..> is the one
# spelling. gutted, the bare Ref takes the type Type and List rides as
# a first-class value -- an unapplied family the theory gives no
# meaning, convertible by name to itself anywhere a Type is expected.
import Base

law bare:
  Type

def bare():
  List

#|Error:
#|- expected : a family instance (write List<..>)
#|- observed : List
#|Location: bare
#|10 | def bare():
#|11>|   List
#|12 |
#|exit 1
