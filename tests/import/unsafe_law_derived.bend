# a law proved from an unsafely filled law relies on unsafe too, with no
# @unsafe of its own; both laws are listed, the helper boom is not (#1001)
import Base
import ./unsafe-law/derived.bend as D

#|All terms check, but 2 defs rely on unsafe or foreign code:
#|- unsafe-law/laws.false_law
#|- unsafe-law/succ.succ_is_id
