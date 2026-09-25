# a folder import loads the .bend files right in the folder, never those
# of its subfolders: folder-sub/ holds one only in folder-sub/deep/, so
# the import is refused
import Base
import ./folder-sub as S

def main() -> Nat:
  S.one()

#|Error:
#|- expected : a folder with .bend files in it
#|- observed : './folder-sub'
#|Location:
#|4 | import Base
#|5>| import ./folder-sub as S
#|6 |
#|exit 1
