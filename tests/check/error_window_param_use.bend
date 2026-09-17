# an error whose subject is a def parameter's use had no source window:
# the parameter's PVar and the checker's lambda binder were made without
# a span, so the failing variable carried none. the binder's variable
# now carries the binder's span (a use is the binder's own HOAS variable,
# so the window is the binder line, as a let-bound use already gave)
import Base

def h(p: Nat) -> Bool:
  Bool.and(True{}, p)

#|Error:
#|- expected : Bool
#|- observed : Nat
#|Context:
#|- p : Nat
#|Location: h
#| 8 | def h(p: Nat) -> Bool:
#| 9>|   Bool.and(True{}, p)
#|10 | 
#|exit 1
