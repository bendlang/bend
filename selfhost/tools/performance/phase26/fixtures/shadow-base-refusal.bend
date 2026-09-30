# Base native identities cannot be replaced by a duplicate local declaration.
import Base

type U32 is Data:
  Foo{}

def bench() -> U32:
  Foo{}
