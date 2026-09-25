# error census: a trailing bind line (no continuation) is rejected -- a
# bind needs a rest to feed.
# ported from bend3: Base's Result, bend error page
import Base

law f:
  Result<&2, &2, Unit, U32>

def f():
  do Result<&2, &2, Unit, U32>:
    x <- Result.pure(&2, &2, Unit, U32, 1)

#|Error:
#|- expected : a term
#|- observed : end of input
#|Location:
#|20 | #|exit 1
#|21>|
#|   | ^
#|exit 1
