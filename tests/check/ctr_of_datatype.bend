# a datatype takes its arguments in <>, a constructor its fields in {}.
# Maybe{&2, Bool} is neither, and the error names the repair
import Base

def t(b: Bool) -> Maybe{&2, Bool}:
  match b:
    case True{}:
      Some{False{}}
    case False{}:
      None{}

#|Error:
#|- expected : Type
#|- observed : non-inferrable term
#|Context:
#|- b : Bool
#|Location: t
#|4 |
#|5>| def t(b: Bool) -> Maybe{&2, Bool}:
#|  |                   ^^^^^^^^^^^^^^^
#|6 |   match b:
#|Note: Maybe is a datatype: write its arguments as <>
#|exit 1
