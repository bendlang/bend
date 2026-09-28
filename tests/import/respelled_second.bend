# the other order: facts loads core first by the spelling that climbs out of
# tests/import and back in, and this file's own alias names that module
import Base
import ../reg/respelled/facts.bend as F
import ./respelled/core.bend as C

def main() -> IO(Unit):
  IO.print(Nat.show(Nat.add(C.seven(), F.seven_again())))

#|14
