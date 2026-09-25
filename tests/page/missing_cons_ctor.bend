# a list literal is Con/Nil whatever the goal: at a foreign type the
# checker refuses the constructor against the goal type (bend3's page
# hinted the missing List.Cons under sugar gating)
import Base

type Fx is Data:
  Mk{}

law main:
  Fx

def main():
  [1]

#|Error:
#|- expected : Fx
#|- observed : List
#|Location: main
#|12 | def main():
#|13>|   [1]
#|   |   ^^^
#|14 |
#|exit 1
