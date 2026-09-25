# bend3's Bytes module (encode/pack/to_list) has no bend surface: a
# Bytes value is an Array of U32 by ruling, and no Bytes namespace
# exists in base -- the head call is an undefined name
import Base

law main:
  U32

def main():
  Bytes.encode("banana")

#|Error:
#|- expected : a defined name
#|- observed : Bytes.encode
#|Location: main
#| 9 | def main():
#|10>|   Bytes.encode("banana")
#|   |   ^^^^^^^^^^^^
#|11 |
#|exit 1
