# Fly -- the proofs. Esc quits by computation; press_reads is an
# induction over the held list with a case analysis on the slot.
import Base
import ./main.bend as Ray
import ./LAWS.bend as Laws

def Laws.esc_quits(rest, s):
  {==}

def Laws.press_reads(held, k, v):
  match held k:
    case [] 0n:
      {==}
    case [] 1n+j:
      Laws.press_reads([], j, v)
    case h <> t 0n:
      {==}
    case h <> t 1n+j:
      Laws.press_reads(t, j, v)
