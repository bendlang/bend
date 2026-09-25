# the old dotted float family (+. -. *. /. <. ==.) is no operator:
# +. is a + followed by a dot, which heads no term
import Base

def main() -> F32:
  1.0 +. 2.0

#|Error:
#|- expected : a term
#|- observed : '.'
#|Location:
#|5 | def main() -> F32:
#|6>|   1.0 +. 2.0
#|  |        ^
#|7 |
#|exit 1
