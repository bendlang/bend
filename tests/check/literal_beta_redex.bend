# a literal lambda application is a beta-redex: infer-app takes the
# one beta step, and the substituted body, a constructor, cannot be
# inferred, so the redex is refused as any bare constructor is.
import Base

law main:
  U32

def main(): (x => x)(3)

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : 3
#|Location: main
#| 8 |
#| 9>| def main(): (x => x)(3)
#|10 |
#|exit 1
