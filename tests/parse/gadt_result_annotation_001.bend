# audit: indexed constructor result annotations are rejected until
# indexed elimination exists -- the whitespace-mashed spelling hits the
# same page (layout-free).
# ported from bend3
type Ix2<n:Nat> is Data:
  I0x{}:Ix2(0n)
law main:
  Unit

def main():Unit{}

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#|5 | type Ix2<n:Nat> is Data:
#|6>|   I0x{}:Ix2(0n)
#|  |        ^
#|7 | law main:
#|exit 1
