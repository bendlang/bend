# comp-splice pin (spec_comp_mint_dedupe): bend3's filter/fold shapes
# with per-site mint counting. bend rules the comp surface out
# (filter/map are not checkable libs); the ~ binder pins bend's own
# parse refusal. (bend3's `x % 2` oddness respells through U32.and.)
import Base

type L is Data:
  C{h: U32, t: L}
  N{}

law filter:
  for ~p: U32 -> Bool
  for xs: L
  L

def filter(p, xs):
  match xs:
    case C{h, t}:
      if p(h):
        C{h, filter(p, t)}
      else:
        filter(p, t)
    case N{}:
      N{}

law fold:
  for ~f: U32 -> U32 -> U32
  for xs: L
  for z: U32
  U32

def fold(f, xs, z):
  match xs:
    case C{h, t}:
      fold(f, t, f(h, z))
    case N{}:
      z

law nums:
  L

def nums():
  C{1, C{2, C{3, C{4, N{}}}}}

law odds:
  L

def odds():
  filter(x => U32.is_ne(U32.and(x, 1), 0), nums())

law main:
  U32

def main():
  fold(a => b => (a + b : U32), odds(), 0)

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|11 | law filter:
#|12>|   for ~p: U32 -> Bool
#|13 |   for xs: L
#|exit 1
