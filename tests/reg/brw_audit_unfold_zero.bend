# audit witness (gptpro A.5/B.4): an argument folded away before a self-jump.
# loop_choose(True{}, xs) unfolds to LoopEnd{}; the count move leaves xs at
# zero and sinks it there, since the jump runs no bind_dead: ledger 0 (both
# compilers leaked the cell).
import Base

type LoopChain is Data:
  LoopEnd{}
  LoopCell{head: U32, tail: LoopChain}

def loop_choose(drop: Bool, xs: LoopChain) -> LoopChain:
  match drop:
    case False{}:
      xs
    case True{}:
      LoopEnd{}

def loop_run(n: Nat, xs: LoopChain) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      loop_run(p, loop_choose(True{}, xs))

def main() -> IO(Unit):
  IO.print(U32.show(
    loop_run(Nat.add(0n, 1n), LoopCell{9, LoopEnd{}})))

#|0
