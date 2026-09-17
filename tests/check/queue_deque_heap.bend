# bend3's Queue/Deque/Heap interplay test rides modules bend's base
# does not have: the head call is an undefined name
import Base

law main:
  U32

def main():
  Queue.push(1, Queue.new())

#|Error:
#|- expected : a defined name
#|- observed : Queue.push
#|Location: main
#| 8 | def main():
#| 9>|   Queue.push(1, Queue.new())
#|10 |
#|exit 1
