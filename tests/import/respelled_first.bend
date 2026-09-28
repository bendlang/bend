# one file reached by two spellings is one module: core is loaded first by
# its own path, then facts (outside tests/import) imports it back through
# ../reg/.., and facts' alias names the module already loaded
import Base
import ./respelled/core.bend as C
import ../reg/respelled/facts.bend as F

def main() -> IO(Unit):
  IO.print(Nat.show(Nat.add(C.seven(), F.seven_again())))

#|14
