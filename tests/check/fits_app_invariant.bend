# soundness pin: an opaque type application compares its argument EQ.
# F(Data) must not fit F(Type): F's variance is unknown, and its later
# fill can put the parameter in a domain (the audit's f_app witness:
# coerce was validated before F's body arrived).
law F: Type -> Type

law coerce: F(Data) -> F(Type)
def coerce(x): x

def F(A): A -> Data

#|Error:
#|- expected : F(Type)
#|- observed : F(Data)
#|Context:
#|- x : F(Data)
#|Location: coerce
#|7 | law coerce: F(Data) -> F(Type)
#|8>| def coerce(x): x
#|  |                ^
#|9 |
#|exit 1
