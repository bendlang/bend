# #994: a constructor key cannot be reused by a later declaration to
# capture a template's opaque ~ binder and inhabit Empty.
import ./template-capture/law.k~B.bend as E

#|Error:
#|- expected : a fresh ~ binder name
#|- observed : B.x
#|Location:
#|1 | law k:
#|2>|   for ~B.x: Data
#|3 |   Data
#|exit 1
