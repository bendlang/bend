# Parallel sum -- the proof: induction on the depth; seq_add splits the loop
# over 2^p + 2^p numbers into the loops over each half.
import Base
import ./main.bend as Par
import ./SPEC.bend as Spec
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
  -> {Nat.add(Spec.seq(m, i), Spec.seq(n, Nat.add(m, i))) == Spec.seq(Nat.add(n, m), i) : Nat}:
  match n:
    case 0n:
      add_zero(Spec.seq(m, i))
    case 1n++q:
      %seq_add(q, m, i) : {Nat.add(Spec.seq(m, i), Nat.add(Spec.seq(q, Nat.add(m, i)), Nat.add(q, Nat.add(m, i)))) == Nat.add(_, Nat.add(Nat.add(q, m), i)) : Nat}
      %add_assoc(q, m, i) : {Nat.add(Spec.seq(m, i), Nat.add(Spec.seq(q, Nat.add(m, i)), Nat.add(q, Nat.add(m, i)))) == Nat.add(Nat.add(Spec.seq(m, i), Spec.seq(q, Nat.add(m, i))), _) : Nat}
      add_assoc(Spec.seq(m, i), Spec.seq(q, Nat.add(m, i)), Nat.add(q, Nat.add(m, i)))

# sum splits its range with its own pow2, which agrees with the spec's
def pow2_same(d: Nat) -> {Spec.pow2(d) == Par.pow2(d) : Nat}:
  match d:
    case 0n:
      {==}
    case 1n+p:
      %pow2_same(p) : {Nat.add(Spec.pow2(p), Spec.pow2(p)) == Nat.add(_, _) : Nat}
      {==}

def Laws.tree_is_seq(d, i):
  match d:
    case 0n:
      {==}
    case 1n++p:
      %pow2_same(p) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(_, i))) == Spec.seq(Spec.pow2(1n+p), i) : Nat}
      %seq_add(Spec.pow2(p), Spec.pow2(p), i) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(Spec.pow2(p), i))) == _ : Nat}
      %Laws.tree_is_seq(p, i) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(Spec.pow2(p), i))) == Nat.add(_, Spec.seq(Spec.pow2(p), Nat.add(Spec.pow2(p), i))) : Nat}
      %Laws.tree_is_seq(p, Nat.add(Spec.pow2(p), i)) : {Nat.add(Par.sum(p, i), Par.sum(p, Nat.add(Spec.pow2(p), i))) == Nat.add(Par.sum(p, i), _) : Nat}
      {==}
