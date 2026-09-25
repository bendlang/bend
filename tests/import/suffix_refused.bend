# a module import names a .bend file: any other suffix is refused as
# the line is read, before the path is opened, and the refusal marks
# the line (an absolute path keeps the golden stable: the corpus is
# single-file, and the check never reaches the file system). A def's
# own import lines, the foreign C and JS fills, are a different
# construct and keep their .c and .js.
import Base
import /lib/words.txt as W

law main:
  U32

def main():
  0

#|Error:
#|- expected : an import of a .bend file
#|- observed : '/lib/words.txt'
#|Location:
#|7 | import Base
#|8>| import /lib/words.txt as W
#|  |        ^
#|9 |
#|exit 1
