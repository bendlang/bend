# Only Audio.open is reachable: its shared source must not register
# write or close. Rate 0 avoids opening a native audio device.
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32 & String, Audio> <- Audio.open(0)
    IO.print("open")

#|open
