# A & B is Sigma<&1, &1, ..>, which is Type; a list element here asks
# for Data, so the note names the spelling that is.
import Base

def f(xs: List<&2, U32 & U32>) -> List<&2, U32 & U32>:
  xs

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Location: f
#|4 |
#|5>| def f(xs: List<&2, U32 & U32>) -> List<&2, U32 & U32>:
#|  |                    ^^^^^^^^^
#|6 |   xs
#|Note: A & B is Type. A pair that is Data is +Sigma<A, _ => B>.
#|exit 1
