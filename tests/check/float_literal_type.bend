# a float literal is an F32: at a U32 goal the build is refused. a
# literal IS its binary32 word, so the observed side spells that word
# exactly as a U32 literal spells its own
import Base

law main:
  U32

def main():
  1.5

#|Error:
#|- expected : U32
#|- observed : F32
#|Location: main
#| 9 | def main():
#|10>|   1.5
#|11 |
#|exit 1
