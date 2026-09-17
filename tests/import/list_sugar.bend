# list literals and <> need a `sugar List: Nil, Con` declaration, which
# Base makes: without Base the sugar role is unbound and the parse fails
# at it -- bend's gating story (bend3 gated the parse on `import List`)
type Nx is Data:
  Zx{}

law main:
  Nx

def main():
  h = [Zx{}]
  Zx{}

#|Error:
#|- expected : a declared constructor
#|- observed : [Zx{}]
#|Location: main
#|10 | def main():
#|11>|   h = [Zx{}]
#|12 |   Zx{}
#|exit 1
