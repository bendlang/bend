# bend3's T/F word-wrap misfired ctor patterns on a numeric scrutinee
# and the page had to name the number; bend has no Bool wrap over
# words at all -- is_eq answers a real Bool through a worker def, and
# a List row on it gets the constructor page naming Bool itself
import Base

law main.go:
  for z: Bool
  U32

def main.go(z):
  match z:
    case h <> t:
      h
    case Nil{}:
      0

law main:
  U32

def main():
  main.go(U32.is_eq(3, 3))

#|Error:
#|- expected : a constructor of Bool (missing, or already matched)
#|- observed : \{Con: (h => t => h); Nil: 0}
#|Location: main.go
#|12 |   match z:
#|13>|     case h <> t:
#|   |          ^^^^^^
#|14 |       h
#|exit 1
