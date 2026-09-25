# a fresh def types itself: a Bind telescope and a "->" return type.
# bare binders belong to the fill of a prior assert alone, so a fresh
# def spelled with bare names is refused at the missing arrow.
def add(x, y):
  x

#|Error:
#|- expected : '->' (a def with no return type fills a law; no law named add is in scope)
#|- observed : ':'
#|Location:
#|3 | # def spelled with bare names is refused at the missing arrow.
#|4>| def add(x, y):
#|  |              ^
#|5 |   x
#|exit 1
