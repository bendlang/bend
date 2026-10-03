# A closure is passed to C without any dynamic application in Bend. The
# effect must still be able to name the runtime's Clo~apply segment.
import Base

def native.apply(step: U32 -> U32, value: U32) -> IO(Unit):
  import "./foreign_runtime_apply.c"
  import "./foreign_runtime_apply.js"

def main() -> IO(Unit):
  native.apply(x => (x + 2 : U32), 40)

#|42
