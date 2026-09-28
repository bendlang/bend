import Base
type Id<-A: Type> is Type:
  MkId{v: A}
def main() -> Id<U32>:
  do Id<U32>:
    MkId{9}
