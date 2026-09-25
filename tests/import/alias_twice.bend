# one alias names one import: a second import as M once silently took M
# over from the first
import Base
import ./alias_lib.bend as M
import ./tmpl_chain_lib.bend as M

def main() -> Nat:
  M.two()

#|Error:
#|- expected : a fresh alias (M names an earlier import)
#|- observed : 'import ./tmpl_chain_lib.bend as M'
#|Location:
#|4 | import ./alias_lib.bend as M
#|5>| import ./tmpl_chain_lib.bend as M
#|  |        ^
#|6 |
#|exit 1
