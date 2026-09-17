# reduction keeps a stuck application's span, so an invalid datatype
# kind points at the application in the declaration
law F: Type -> Type
type Bad is F(Type):

#|Error:
#|- expected : a kind (type Bad<..> is Kind(g))
#|- observed : F(Type)
#|Location: Bad
#|3 | law F: Type -> Type
#|4>| type Bad is F(Type):
#|5 |
#|exit 1
