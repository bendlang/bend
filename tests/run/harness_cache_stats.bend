# bend3's harness-cache adversary, stats side: --stats bypassed the
# cache and measured a fresh check. bend has no --stats; the cache
# half that still speaks is pinned -- the rendered page and the value
# repeat byte-identically around each other off one in-process book
import Base

law flip:
  for c: Cmp
  Cmp

def flip(c):
  match c:
    case LT{}:
      GT{}
    case EQ{}:
      EQ{}
    case GT{}:
      LT{}

def Cmp.text(c: Cmp) -> String:
  match c:
    case LT{}:
      "LT{}"
    case EQ{}:
      "EQ{}"
    case GT{}:
      "GT{}"

law main:
  IO(Unit)

def main():
  IO.print(Cmp.text(flip(flip(LT{}))))

#|LT{}
