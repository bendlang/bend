# audit witness (gptpro B.1): a fork whose second kid feeds a temporary to the
# parameter its first kid reads. The convention is fixed for the pass (brw_of
# memoized), so both paths of the fork hold the same values; the temporary
# owns fork_first~0 for the next pass. The emitter once died here with
# "a fork's paths hold different values".
import Base

type ForkChain is Data:
  ForkEnd{}
  ForkCell{head: U32, tail: ForkChain}

def fork_first(xs: ForkChain) -> U32:
  match xs:
    case ForkEnd{}:
      0
    case ForkCell{h, t}:
      h

def main() -> IO(Unit):
  xs = {ForkCell{1, ForkEnd{}} : ForkChain}
  a b = fork_first(xs) fork_first(ForkCell{2, ForkEnd{}})
  IO.print(U32.show(U32.add(a, b)))

#|3
