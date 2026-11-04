# an importer checks a module that writes a Base datatype with braces:
# the note still names the datatype, though the braces resolve in the
# module's constructors
import Base
import ./ctr_of_datatype_lib.bend as L

#|SOME PROOFS FAIL
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
