# an erased Empty hypothesis is dead, may never be supplied, and
# cannot launder a Data license: Empty.absurd(Data, e) is a Data-kinded
# type, so the + rebind is licensed, but x : T never converts to that
# stuck type -- the laundering dies at conversion
import Base

type Dup2<-T: Data> is Data:
  Two2{left: T, right: T}

law launder:
  for -T: Type
  for -e: Empty
  @x: T ->
  Dup2<Empty.absurd(Data, e)>

def launder(T, e, x):
  +y = {x : Empty.absurd(Data, e)};
  Two2{y, y}

#|Error:
#|- expected : Empty.absurd(Data, e)
#|- observed : T
#|Context:
#|- T : Type
#|- e : Empty
#|- x : T
#|Location: launder
#|16 | def launder(T, e, x):
#|17>|   +y = {x : Empty.absurd(Data, e)};
#|   |         ^
#|18 |   Two2{y, y}
#|exit 1
