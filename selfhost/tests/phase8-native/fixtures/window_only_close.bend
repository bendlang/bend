# Compile the grouped Window source without opening a display.
import Base

def close(m: Maybe<&1, Window>) -> IO(Unit):
  match m:
    case None{}:
      IO.print("window guarded")
    case Some{w}:
      Window.close(w)

def main() -> IO(Unit):
  close(None{})

#|window guarded
