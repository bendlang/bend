# bend3's one-law beta pin fed a def a NUMERIC match-lambda closure
# (\{0: 9; n => ..}); bend match-lambdas take constructor keys only,
# so the closure's own spelling dies at parse (the lam half of the
# same law carries in flatten_redex_hideouts)
import Base

law usem:
  for f: U32 -> U32
  U32

def usem(f):
  y = f(3)
  (y + 1 : U32)

law main:
  U32

def main():
  usem(\{0: 9; n => (n * 2 : U32)})

#|Error:
#|- expected : '}'
#|- observed : ':'
#|Location:
#|18 | def main():
#|19>|   usem(\{0: 9; n => (n * 2 : U32)})
#|   |           ^
#|20 |
#|exit 1
