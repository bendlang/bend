# a + parameter whose type is Type (Result at &1 is Type) is refused at
# that parameter, and the note names it with its rule; the Context lists
# the parameters before it, which are not the cause (#980)
import Base

def two(+name: String, +res: Result<&1, &1, U32 & String, Unit>) -> Unit:
  Unit{}

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- name : String
#|Location: two
#|5 |
#|6>| def two(+name: String, +res: Result<&1, &1, U32 & String, Unit>) -> Unit:
#|  |                              ^^^^^^^^^
#|7 |   Unit{}
#|Note: +res can be used many times, so its type must be Data.
#|exit 1
