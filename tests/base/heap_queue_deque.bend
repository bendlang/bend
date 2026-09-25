# bend3's Heap/Queue/Deque container modules are absent from bend's
# base (Map and Set are its containers): the head call is an undefined
# name
import Base

law main:
  U32

def main():
  Deque.push_front(1, Deque.new())

#|Error:
#|- expected : a defined name
#|- observed : Deque.push_front
#|Location: main
#| 9 | def main():
#|10>|   Deque.push_front(1, Deque.new())
#|   |   ^^^^^^^^^^^^^^^^
#|11 |
#|exit 1
