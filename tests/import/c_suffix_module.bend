# a module import names a .bend file: any other suffix is refused before
# the path is looked up, so the error names the spelling as written (an
# absolute path keeps the golden stable: the corpus is single-file and
# no fixture tree exists). A def's own import lines, its foreign C and
# JS fills, are a different construct and keep their .c and .js.
import Base
import /lib/helper.c as H

law main:
  U32

def main():
  0

#|Error:
#|- expected : an import of a .bend file
#|- observed : '/lib/helper.c'
#|Location:
#|6 | import Base
#|7>| import /lib/helper.c as H
#|8 |
#|exit 1
