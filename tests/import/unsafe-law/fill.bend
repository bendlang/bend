# the false law, filled by an unsafe self-call outside the file that
# declares it
import ./laws.bend as Laws

def Laws.false_law?():
  Laws.false_law()
