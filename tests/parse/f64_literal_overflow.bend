# an f64 literal that rounds to infinity is a parse error, as an f32's is
import Base

def main() -> F64:
  1.0e309f64

#|Error:
#|- expected : a float literal with a finite f64 value (got 1.0e309f64)
#|- observed : '
#|'
#|Location:
#|4 | def main() -> F64:
#|5>|   1.0e309f64
#|6 |
#|exit 1
