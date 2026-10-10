# a PROOF.bend's claims are its own defs and its LAWS.bend's (#1463): a
# def beyond them that relies on unsafe or foreign code is a note on the
# pass, where it failed every law. A law that relies on one fails, as
# tests/import/PROOF.bend shows
import Base
import ./LAWS.bend as Laws

def Laws.greets():
  {==}

#|ALL PROOFS CHECK
#|Note: 2 defs rely on unsafe or foreign code, but no law or proof does:
#|- app/main.serve
#|- app/main.main
#|Use --verdict for mathematical validity.
