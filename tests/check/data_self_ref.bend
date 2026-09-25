# refusal pin: bend3's sort fixpoint grew P's table through its own
# declaration and refused a t: Type bound at the Box formation inside
# it. the grade kernel reads declared kinds: P6 declares Type (its End6
# field holds a T: Type), so the Box5<P6<T>> formation inside P6's own
# declaration refuses at Box5's Data bound -- Type never fits Data.
import Base

type Box5<-T: Data> is Data:
  MkBox5{v: T}
type P6<-T: Type> is Type:
  MkP6{v: Box5<P6<T>>}
  End6{w: T}

law main:
  U32

def main(): 0

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- T : Type
#|Location: MkP6
#|10 | type P6<-T: Type> is Type:
#|11>|   MkP6{v: Box5<P6<T>>}
#|   |                ^^^^
#|12 |   End6{w: T}
#|exit 1
