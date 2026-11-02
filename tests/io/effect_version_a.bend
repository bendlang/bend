# io (effect_versions): one version of a package with a C effect.
import Base

type Instant is Data:
  Instant{value: U32}

def now() -> IO(Instant):
  import "./effect_version_a.c"
  import "./effect_version_a.js"

#|SOME PROOFS FAIL
#|Error: 1 def relies on unsafe or foreign code:
#|defs that depend on foreign effects: now
#|exit 1
