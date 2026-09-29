import Base

type T is Data:
  Tick{}

def Tick() -> IO(U32):
  import "./effect_collision.js"
  import "./effect_collision.c"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Tick()
    IO.print(U32.show(n))

#|Error: Tick names both a constructor and a foreign def: name one apart
#|exit 1
