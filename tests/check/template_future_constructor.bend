# The complete namespace reserves even constructors revealed after a
# template fill; validation order cannot hide an opaque-name collision.
import ./template-future/law.k~B.bend as E

#|Error:
#|- expected : a fresh ~ binder name
#|- observed : B.x
#|Location:
#|1 | law k:
#|2>|   for ~B.x: Data
#|3 |   Data
#|exit 1
