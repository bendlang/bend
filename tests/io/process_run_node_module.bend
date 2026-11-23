# Node module-mode launches must preserve Process.run and worker preloads.
# So must a Node without getBuiltinModule (before 20.16), by a preload.
# JS-only: runs real Node; skips when Bun cannot find node on PATH.
import Base

def Host.process_run_node_module() -> IO(U32):
  import "./process_run_node_module.js"

def main() -> IO(Unit):
  do IO<Unit>:
    status : U32 <- Host.process_run_node_module()
    IO.print(U32.show(status))

#|0
