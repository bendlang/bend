# an erased Data-kinded binder is a lawful license (the hypothesis
# discharges at call sites): audit_dup binds -T: Data and duplicates
# its +x, and the call site must instantiate T at a Data type -- a
# closure type (Type) is refused there (audit_clone's own type stays
# generic through count, so no ill-formed AuditDup<..> is spelled)
import Base

type AuditDup<-T: Data> is Data:
  AuditTwo{left: T, right: T}

law audit_dup:
  for -T: Data
  for +x: T
  AuditDup<T>

def audit_dup(T, x):
  AuditTwo{x, x}

law count:
  for -T: Data
  for d: AuditDup<T>
  U32

def count(T, d):
  match d:
    case AuditTwo{l, r}:
      2

law audit_clone:
  for f: U32 -> U32
  U32

def audit_clone(f):
  count((U32 -> U32), audit_dup((U32 -> U32), f))

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- f : @_:U32 -> U32
#|Location: audit_clone
#|33 | def audit_clone(f):
#|34>|   count((U32 -> U32), audit_dup((U32 -> U32), f))
#|   |          ^^^^^^^^^^
#|35 |
#|exit 1
