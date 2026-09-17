# bend3's bare re-exporting module tree carried one IO across files;
# bend imports are aliased single files, the corpus is flat, and no
# IO driver exists -- the leading-line load dies on the absent tree
import Base
import /shared/io_tree.bend as T

law main:
  U32

def main():
  0

#|Error:
#|- message  : no such file: /shared/io_tree.bend
#|Location:
#|4 | import Base
#|5>| import /shared/io_tree.bend as T
#|6 |
#|exit 1
