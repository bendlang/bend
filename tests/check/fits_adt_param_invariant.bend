# soundness pin: ADT parameters compare EQ under conversion. A
# parameter can sit in a stored function's domain, so Contra<Data>
# fitting Contra<Type> would relabel a Data -> Data field as
# Type -> Data (the audit's e_adt witness).
type Contra<A:Type> is Type:
  Contra{f: A -> Data}

law cid: Data -> Data
def cid(x): x

law cData: Contra<Data>
def cData(): Contra{cid}

law cType: Contra<Type>
def cType(): cData

#|Error:
#|- expected : Contra<Type>
#|- observed : Contra<Data>
#|Location: cType
#|14 | law cType: Contra<Type>
#|15>| def cType(): cData
#|   |              ^^^^^
#|16 |
#|exit 1
