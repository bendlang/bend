# audit witness (gptpro A.2): a flattened pair whose first word is rooted
# and second owns a fresh cell, lent whole. val_sink sinks per word, so the
# owned cell dies with the pair: ledger 0 (main leaked two nodes).
import Base

type PairChain is Data:
  PairEnd{}
  PairCell{head: U32, tail: PairChain}

type ChainPair is Data:
  MakeChainPair{left: PairChain, right: PairChain}

def pair_first(xs: PairChain) -> U32:
  match xs:
    case PairEnd{}:
      0
    case PairCell{h, t}:
      h

def pair_view(p: ChainPair) -> U32:
  match p:
    case MakeChainPair{left, right}:
      pair_first(left)

def pair_use(xs: PairChain) -> U32:
  p = {MakeChainPair{xs, PairCell{99, PairEnd{}}} : ChainPair}
  pair_view(p)

def main() -> IO(Unit):
  +xs = {PairCell{7, PairEnd{}} : PairChain}
  a = pair_use(xs)
  b = pair_use(xs)
  IO.print(U32.show(U32.add(a, b)))

#|14
