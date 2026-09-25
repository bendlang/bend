# bend3's JSON module is absent from bend by ruling (JSON is on the
# do-not-add list): the head call is an undefined name
import Base

law main:
  U32

def main():
  JSON.read("{\"a\": 1}")

#|Error:
#|- expected : a defined name
#|- observed : JSON.read
#|Location: main
#| 8 | def main():
#| 9>|   JSON.read("{\"a\": 1}")
#|   |   ^^^^^^^^^
#|10 |
#|exit 1
