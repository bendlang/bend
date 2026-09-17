# no U32 truthiness: a branch scrutinee is Bool -- a literal word
# cannot even sit there (the Bool-matching def rejects the U32 ctor;
# bend3's one-way U32-Bool bridge has no counterpart at all). the if
# sugar itself is gone with the lambda-match application ban.
import Base

law pick:
  for b: Bool
  U32

def pick(b):
  match b:
    case True{}:
      2
    case False{}:
      3

law main:
  U32

def main():
  pick(1)

#|Error:
#|- expected : Bool
#|- observed : U32
#|Location: main
#|21 | def main():
#|22>|   pick(1)
#|23 |
#|exit 1
