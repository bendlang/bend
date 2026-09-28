# Only Audio.close is reachable; the unused open and write entries must
# not require their constructor IDs. None needs no audio device.
import Base

def close(m: Maybe<&1, Audio>) -> IO(Unit):
  match m:
    case None{}:
      IO.print("close")
    case Some{a}:
      Audio.close(a)

def main() -> IO(Unit):
  close(None{})

#|close
