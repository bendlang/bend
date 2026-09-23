# a module with an @unsafe def: its own verdict names it (and nothing
# else), and an importer's verdict names only what the importer uses
import Base

@unsafe
def boom() -> Empty:
  boom()

def safe(n: Nat) -> Nat:
  n

#|All terms check, but 1 def relies on unsafe or foreign code:
#|- boom
#|exit 1
