# bend3's harness-cache adversary, stats side: --stats bypassed the
# cache and measured a fresh check. bend has no --stats; the cache
# half that still speaks is pinned -- the rendered page and the value
# repeat byte-identically around each other off one in-process book
import Base

law main:
  for c: Cmp
  Cmp

def main(c):
  match c:
    case LT{}:
      GT{}
    case EQ{}:
      EQ{}
    case GT{}:
      LT{}

#|\{LT: GT{}; EQ: EQ{}; GT: LT{}}
