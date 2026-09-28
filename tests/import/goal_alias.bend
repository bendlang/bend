# a goal spells another file's names as this file does, through its
# alias, so it reads back as written: M.quad(x) unfolds to
# M.double(M.double(x)). once it printed the key, goal-alias/mod.double,
# and a hub package's 0x<hash>/json.double did not even lex (#965)
import Base
import ./goal-alias/mod.bend as M

def quad_id(x: Nat) -> {M.quad(x) == x : Nat}:
  {==}

#|SOME PROOFS FAIL
#|Error:
#|- expected : M.double(M.double(x))
#|- observed : x
#|Context:
#|- x : Nat
#|Location: quad_id
#| 8 | def quad_id(x: Nat) -> {M.quad(x) == x : Nat}:
#| 9>|   {==}
#|   |   ^^^^
#|10 |
#|exit 1
