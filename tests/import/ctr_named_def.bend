# an importer runs a module whose own def is named like Base's Done
# constructor. once the module's Done{..} and \{Done: ..} resolved to
# the def, and the module failed to check (#1236)
import Base
import ./ctr_named_def_lib.bend as M

def main() -> Bool:
  M.get(M.wrap(True{}))

#|True{}
