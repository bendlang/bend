# a literal is a String by name only where String is Base's: a module's
# own String that declares SCon with other fields checks the literal's
# unfolding, so "x" is refused as SCon{'x', ""} where 'x' is not an Empty (#941)
type Empty is Data:

type String is Data:
  SCon{e: Empty, tail: Empty}

def extract(s: String) -> Empty:
  match s:
    case SCon{e, tail}:
      e

def boom() -> Empty:
  extract("x")

#|Error:
#|- expected : a declared constructor (Empty declares )
#|- observed : 'x'
#|Location: boom
#|14 | def boom() -> Empty:
#|15>|   extract("x")
#|   |           ^^^
#|16 | 
#|exit 1
