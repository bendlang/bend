# bend3's binder-optional Pi domain (@Type -> ..); bend's All always
# binds Name ':' Term, so the reserved head dies at the binder
import Base

law main:
  Type

def main():
  @Type -> x => Type

#|Error:
#|- expected : a name (got the keyword 'Type')
#|- observed : ' '
#|Location:
#| 8 | def main():
#| 9>|   @Type -> x => Type
#|10 |
#|exit 1
