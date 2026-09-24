# a foreign def and a constructor share the C constructor ids, so they may
# not share a name (Tick's arity and its effect's were one table cell)
import Base

type T is Data:
  Tick{}
  Tock{}

def Tick() -> IO(U32):
  import "./effect_ctr_name.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Tick()
    IO.print(U32.show(n))

#|Error: Tick names both a constructor and a foreign def: name one apart
#|exit 1
