# Node without getBuiltinModule must still load the Process.run worker.
# JS-only: runs real Node; skips when Bun cannot find node on PATH.
import Base

def Host.process_run_old_node() -> IO(U32):
  import "./process_run_old_node.js"

def main() -> IO(Unit):
  do IO<Unit>:
    status : U32 <- Host.process_run_old_node()
    IO.print(U32.show(status))

#|0
