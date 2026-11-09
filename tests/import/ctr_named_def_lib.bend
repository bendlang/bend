# a module's own def named like Base's Done constructor: Done{..} and a
# \{Done: ..} arm still name the constructor, and Done(..) the def
import Base

def Done(b: Bool) -> Bool:
  b

def wrap(b: Bool) -> Result<U32, Bool>:
  Done{b}

def get(r: Result<U32, Bool>) -> Bool:
  {\{Fail: e => False{}; Done: b => Done(b)} : Result<U32, Bool> -> Bool}(r)

def main() -> Bool:
  get(wrap(True{}))

#|True{}
