# bend3 canonicalized relative spellings to one module identity;
# bend dedups by realpath, which a flat corpus cannot exercise with
# two spellings of a real file -- the canonical target dies loudly
import Base
import /mods/canonical.bend as C

law main:
  U32

def main():
  0

#|Error:
#|- message  : no such file: /mods/canonical.bend
#|Location:
#|4 | import Base
#|5>| import /mods/canonical.bend as C
#|6 |
#|exit 1
