# an importer runs a module whose locals are named like the module's own
# defs: every binder shape binds, and the values print
import Base
import ./binder_named_def_lib.bend as M

def main() -> List<Bool>:
  [M.lt(True{}), M.plus(2n), M.pat(M.P{False{}, 0n}), M.ppat(M.P{True{}, 0n}), M.lam(False{})]

#|[True{}, False{}, False{}, True{}, False{}]
