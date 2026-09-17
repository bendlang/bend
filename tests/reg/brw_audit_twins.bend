# audit witness (gptpro A.1): twins, the first read and the second consumed
# first. twin_use~0 is borrowed, twin_use~1 owned (its box is stored); the
# read counts once every argument is laid out, so main keeps xs (one
# term_keep) and twin_dispose frees a copy. Main's compiler moved the twin
# and printed 51413378 for 23.
import Base

type TwinChain is Data:
  TwinEnd{}
  TwinCell{head: U32, tail: TwinChain}

type TwinTrash is Type:
  TwinWrap{value: TwinChain}
  TwinMore{tail: TwinTrash}

def twin_first(xs: TwinChain) -> U32:
  match xs:
    case TwinEnd{}:
      0
    case TwinCell{h, t}:
      h

def twin_dispose(box: TwinTrash) -> U32:
  match box:
    case TwinWrap{value}:
      0
    case TwinMore{tail}:
      0

def twin_use(reader: TwinChain, consumed: TwinChain) -> U32:
  n = twin_dispose(TwinWrap{consumed})
  U32.add(n, twin_first(reader))

def main() -> IO(Unit):
  +xs = {TwinCell{23, TwinEnd{}} : TwinChain}
  IO.print(U32.show(twin_use(xs, xs)))

#|23
