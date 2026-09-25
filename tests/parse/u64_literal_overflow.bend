# a u64 literal past 2^64-1 is a parse error, not a wrap
import Base

def main() -> U64:
  18446744073709551616u64

#|Error:
#|- expected : a u64 literal up to 18446744073709551615 (got 18446744073709551616u64)
#|- observed : '
#|'
#|Location:
#|4 | def main() -> U64:
#|5>|   18446744073709551616u64
#|6 |
#|exit 1
