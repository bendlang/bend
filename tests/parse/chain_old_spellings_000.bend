# the old Nat spelling +n is no operator: a + glued to a name heads
# a binder, so 1n +n opens a parallel let that finds no = at 2n
import Base

def main() -> Nat:
  1n +n 2n

#|Error:
#|- expected : '='
#|- observed : '2'
#|Location:
#|5 | def main() -> Nat:
#|6>|   1n +n 2n
#|  |         ^
#|7 |
#|exit 1
