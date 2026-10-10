import Base

def main() -> IO(Unit):
  IO.die(Unit, 256, "x")

#|bend: exit status must be between 0 and 255
#|exit 1
