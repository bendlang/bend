# bend3 refused `as` on a multi-scrutinee match (one name, two
# columns); bend has no as binder at all -- the words read as extra
# scrutinees and the pattern count refuses at the same early spot
import Base

law both:
  for a: Bool
  for b: Bool
  U32

def both(a, b):
  match Bool.not(a), b as e:
    case True{}, True{}:
      1
    case x, y:
      0

law main:
  U32

def main():
  0

#|Error:
#|- expected : 4 patterns (one per scrutinee)
#|- observed : 'True{}, True{}'
#|Location:
#|12 |   match Bool.not(a), b as e:
#|13>|     case True{}, True{}:
#|   |          ^^^^^^^^^^^^^^
#|14 |       1
#|exit 1
