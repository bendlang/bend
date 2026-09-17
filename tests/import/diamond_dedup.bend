# bend3 loaded a diamond once per module identity; bend dedups by
# realpath (Base imported twice below is one load) and the flat corpus
# cannot spell the tree -- the absent diamond top dies at its line
import Base
import Base
import /diamond/top.bend as D

law main:
  U32

def main():
  0

#|Error:
#|- message  : no such file: /diamond/top.bend
#|Location:
#|5 | import Base
#|6>| import /diamond/top.bend as D
#|7 |
#|exit 1
