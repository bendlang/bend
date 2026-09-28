# Only Audio.write is reachable. None keeps the test independent of an
# audio device while the Some arm requires the write entry to compile.
import Base

def write(m: Maybe<&1, Audio>) -> IO(Unit):
  match m:
    case None{}:
      IO.print("write")
    case Some{a}:
      do IO<Unit>:
        r : Audio & U32 <- Audio.write(a, [])
        IO.print("write")

def main() -> IO(Unit):
  write(None{})

#|write
