# a module in a subfolder: a folder import loads only the files right in
# the folder, so this one never loads (it would not even check)
import Base

def sq() -> Nat:
  Nat.nope
