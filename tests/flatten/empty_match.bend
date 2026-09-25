# \{} applied to a value is a lambda-match application too: the banned
# form, rejected by the checker (spell the absurd elimination as a def)
type Emp is Data:

law main:
  for e: Emp
  Emp

def main(e):
  (\{})(e)

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{}
#|Context:
#|- e : Emp
#|Location: main
#| 9 | def main(e):
#|10>|   (\{})(e)
#|   |    ^^^
#|11 |
#|exit 1
