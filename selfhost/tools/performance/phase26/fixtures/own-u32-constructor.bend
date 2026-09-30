# Even spelling the constructor U32 does not make this local declaration native.
type Flag is Data:
  Off{}
  On{}

type U32 is Data:
  U32{value: Flag}

def view(n: U32) -> Flag:
  match n:
    case U32{value}: value

def bench() -> Flag:
  view(U32{On{}})
