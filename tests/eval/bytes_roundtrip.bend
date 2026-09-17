# bend3's Bytes.from_string/to_string roundtrip has no bend surface
# (Bytes = an Array of U32 by ruling, no namespace in base): the head
# call is an undefined name
import Base

law main:
  U32

def main():
  Bytes.to_string(Bytes.from_string("hi"))

#|Error:
#|- expected : a defined name
#|- observed : Bytes.to_string
#|Location: main
#| 9 | def main():
#|10>|   Bytes.to_string(Bytes.from_string("hi"))
#|11 |
#|exit 1
