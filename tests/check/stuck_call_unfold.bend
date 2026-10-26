# two calls of distinct defs convert where each def's body, once on its
# arguments, does: a stuck call on an open variable, a partial call, and
# a stuck call inside a constructor
import Base

def not1(b: Bool) -> Bool:
  match b:
    case True{}:
      False{}
    case False{}:
      True{}

def not2(b: Bool) -> Bool:
  match b:
    case True{}:
      False{}
    case False{}:
      True{}

# stuck on the open b
def stuck(b: Bool) -> {not1(b) == not2(b) : Bool}:
  {==}

def snd1(a: U32, b: U32) -> U32:
  b

def snd2(a: U32, b: U32) -> U32:
  b

# short of its parameters
def partial() -> {snd1(1) == snd2(1) : U32 -> U32}:
  {==}

# inside a constructor
def inner(b: Bool) -> {Con{not1(b), Nil{}} == Con{not2(b), Nil{}} : List<Bool>}:
  {==}

def main() -> U32:
  7

#|7
