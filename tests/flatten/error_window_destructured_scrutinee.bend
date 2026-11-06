# deep in a chain of destructures, a statement re-matches a binder an
# earlier one already split: the error points at that match, where the
# substituted scrutinee was written
type L is Data:
  C{next: L}

law main:
  for x0: L
  L

def main(x0):
  C{x1} = x0
  C{x2} = x1
  C{x3} = x2
  C{x4} = x3
  C{x5} = x4
  C{x6} = x5
  C{x7} = x6
  C{x8} = x7
  C{x9} = x8
  C{x10} = x9
  C{x11} = x10
  C{x12} = x11
  match x5:
    case C{y}:
      y
#|SOME PROOFS FAIL
#|Error:
#|- message  : 'x5' can't be matched here (match it in the same match as the pattern that introduced it)
#|Location:
#|23 |   C{x12} = x11
#|24>|   match x5:
#|   |   ^^^^^^^^^
#|25 |     case C{y}:
#|exit 1
