# bend3's ../../ module ascent reached C-bodied defs; bend has
# neither (imports open literal paths, C bodies are gone), and a module
# import names a .bend file -- the ascent's target dies at the leading
# line on its suffix, before any path is opened
import Base
import /up/up/native_mod.c as M

law main:
  U32

def main():
  0

#|Error:
#|- expected : an import of a .bend file
#|- observed : '/up/up/native_mod.c'
#|Location:
#|5 | import Base
#|6>| import /up/up/native_mod.c as M
#|7 |
#|exit 1
