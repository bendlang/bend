# soundness pin: LE swaps function domains. @T:Data -> Type must not
# fit @U:Type -> Type: the slot's owner picks the argument, and a Data
# binder licenses contraction the argument may not survive (the
# audit's d_pi witness: it granted +x over a self-applied function).
type Empty is Data:

law K: @T:Data -> Type
def K(T): @+x:T -> Empty

law KAny: @T:Type -> Type
def KAny(T): ({K : @U:Type -> Type})(T)

#|Error:
#|- expected : @U:Type -> Type
#|- observed : @T:Data -> Type
#|Context:
#|- T : Type
#|Location: KAny
#|10 | law KAny: @T:Type -> Type
#|11>| def KAny(T): ({K : @U:Type -> Type})(T)
#|   |                ^
#|12 |
#|exit 1
