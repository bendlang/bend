import Base

def main() -> IO(U32):
  do IO<U32>:
    return 256

#|bend: exit status must be between 0 and 255
#|exit 1
