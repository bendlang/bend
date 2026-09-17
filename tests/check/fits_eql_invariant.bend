# soundness pin: equation endpoints flow both ways (J rewrites left and
# right), so conversion is EQ inside Eql: a real {Data == Data} proof
# must not convert to {Data == Type} (the audit's c_eql witness).
law rr: {Data == Data : Type}
def rr(): {==}

law dt: {Data == Type : Type}
def dt(): rr

#|Error:
#|- expected : {Data == Type : Type}
#|- observed : {Data == Data : Type}
#|Location: dt
#|7 | law dt: {Data == Type : Type}
#|8>| def dt(): rr
#|9 |
#|exit 1
