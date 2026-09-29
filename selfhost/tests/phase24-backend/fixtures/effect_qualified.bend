import Base

type T is Data:
  Scope.Tick{}

def Scope.Tick() -> IO(U32):
  import "./effect_qualified.js"
  import "./effect_qualified.c"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Scope.Tick()
    IO.print(U32.show(n))

#|Error: Scope.Tick names both a constructor and a foreign def: name one apart
#|exit 1
