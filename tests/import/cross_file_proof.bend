# bend3 chained a proof transitively over bare imports; bend's flat
# corpus has no module tree to chain across -- the leading-line load
# dies on the absent file
import Base
import /shared/proof_chain.bend as P

law main:
  U32

def main():
  0

#|Error:
#|- message  : no such file: /shared/proof_chain.bend
#|Location:
#|4 | import Base
#|5>| import /shared/proof_chain.bend as P
#|6 |
#|exit 1
