# Parallel sum -- the proof: induction on the depth; seq_add splits the loop
# over 2^p + 2^p numbers into the loops over each half.
import Base
import ./main.bend as Par
import ./LAWS.bend as Laws

def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_assoc(a: Nat, -b: Nat, -c: Nat) -> {Nat.add(a, Nat.add(b, c)) == Nat.add(Nat.add(a, b), c) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, b, c) : {1n+Nat.add(p, Nat.add(b, c)) == 1n+_ : Nat}
      {==}

def seq_add(n: Nat, +m: Nat, +i: Nat)
  -> {Nat.add(Par.seq(m, i), Par.seq(n, Nat.add(m, i))) == Par.seq(Nat.add(n, m), i) : Nat}:
  match n:
    case 0n:
      add_zero(Par.seq(m, i))
    case 1n++q:
      %seq_add(q, m, i) : {Nat.add(Par.seq(m, i), Nat.add(Par.seq(q, Nat.add(m, i)), Nat.add(q, Nat.add(m, i)))) == Nat.add(_, Nat.add(Nat.add(q, m), i)) : Nat}
      %add_assoc(q, m, i) : {Nat.add(Par.seq(m, i), Nat.add(Par.seq(q, Nat.add(m, i)), Nat.add(q, Nat.add(m, i)))) == Nat.add(Nat.add(Par.seq(m, i), Par.seq(q, Nat.add(m, i))), _) : Nat}
      add_assoc(Par.seq(m, i), Par.seq(q, Nat.add(m, i)), Nat.add(q, Nat.add(m, i)))

def Laws.tree_is_seq(d, i):
  match d:
    case 0n:
      {==}
    case 1n++p:
      %seq_add(Par.pow2(p), Par.pow2(p), i) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(Par.pow2(p), i))) == _ : Nat}
      %Laws.tree_is_seq(p, i) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(Par.pow2(p), i))) == Nat.add(_, Par.seq(Par.pow2(p), Nat.add(Par.pow2(p), i))) : Nat}
      %Laws.tree_is_seq(p, Nat.add(Par.pow2(p), i)) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(Par.pow2(p), i))) == Nat.add(Par.sum(p, i), _) : Nat}
      {==}
