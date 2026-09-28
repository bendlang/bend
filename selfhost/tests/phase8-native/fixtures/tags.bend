import Base

type Token is Data:
  Pick{}
  pick{}

def answer() -> U32:
  42

law get:
  U32 -> IO(Token)

def get(n):
  import "./tags.c"

def show(t: Token) -> String:
  match t:
    case Pick{}: "upper"
    case pick{}: "lower"
