# Reversing discovery order also preserves the scheduling helper's call.
import Base

def A.run(ms: U32) -> IO(U32):
  import "./effect_need_worker.js"

def A.run_need() -> IO(U32):
  import "./effect_need_name.js"

def main() -> IO(Unit):
  do IO<Unit>:
    x : U32 <- A.run(1)
    y : U32 <- A.run_need()
    IO.print(U32.show(x) ++ " " ++ U32.show(y))

#|11 22
