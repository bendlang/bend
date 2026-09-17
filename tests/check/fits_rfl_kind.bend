# soundness pin: term_compare's kind order (Data fits Type) is LE-only.
# Rfl claims equality, so it compares EQ: {==} must not prove
# {Data == Type} (the audit's e1 witness: J would transport it
# backwards into a Type -> Data cast and a closed Empty).
type Empty is Data:

law data_type: {Data == Type : Type}
def data_type(): {==}

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: data_type
#|7 | law data_type: {Data == Type : Type}
#|8>| def data_type(): {==}
#|9 |
#|exit 1
