import Base

type T is Data:
  Tick{}

def Tick() -> IO(U32):
  import "./effect_unused.js"
  import "./effect_unused.c"

def main() -> IO(Unit):
  IO.print("unused")

#|Error: Tick names both a constructor and a foreign def: name one apart
#|exit 1
