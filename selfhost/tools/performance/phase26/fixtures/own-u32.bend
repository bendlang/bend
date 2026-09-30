# A type named U32 with a different constructor has no native-word identity.
type U32 is Data:
  Foo{}
  Bar{}

type Decision is Data:
  No{}
  Yes{}

def classify(n: U32) -> Decision:
  match n:
    case Foo{}: Yes{}
    case Bar{}: No{}

def bench() -> Decision:
  classify(Foo{})

def other() -> Decision:
  classify(Bar{})
