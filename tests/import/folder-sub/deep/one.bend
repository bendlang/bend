# the only .bend file under folder-sub/, one folder down: folder_sub
# imports folder-sub, which holds no .bend file of its own, and is refused
import Base

def one() -> Nat:
  1n
