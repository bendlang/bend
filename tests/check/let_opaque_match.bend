# bend3's sealed-let pin: a match on a let-bound 1e9-deep call
# dispatched on the abstract binder and never ran it. bend bans the
# let-then-match outright, so the dispatch moves behind its own def
# and matches a parameter -- the literal-0 arm is a structural word
# pattern, the catch-all takes the rest, and main answers 0
import Base

law probe.go:
  for w: U32
  U32

def probe.go(w):
  match w:
    case 0:
      0
    case w:
      1

law probe:
  for s: U32
  U32

def probe(s):
  probe.go((s * 3 : U32))

law main:
  U32

def main():
  0

#|0
