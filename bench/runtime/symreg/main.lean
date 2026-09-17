-- Single-threaded Lean twin of main.bend. Same
-- algorithms over the same expression-tree ADT: expr_gen materializes
-- each depth-5 candidate AST from the xorshift32 stream (inductive
-- Expr), expr_eval is the recursive pattern-matching interpreter
-- (Bend's eval walks the tree; value recursion, order and u32
-- numerics are identical), expr_size adds the
-- parsimony penalty, batch_run folds the tournament, seed_climb
-- hill-climbs the winner. All UInt32.
-- Expected at popDepth=18, dataPoints=110: 2383953211.
def popDepth : UInt32 := 18
def dataPoints : UInt32 := 110
def climbRounds : UInt32 := 32

inductive Expr where
  | var : Expr
  | lit : UInt32 → Expr
  | add : Expr → Expr → Expr
  | sub : Expr → Expr → Expr
  | mul : Expr → Expr → Expr
  | xor : Expr → Expr → Expr
  deriving Inhabited

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< 13)
  let d := b ^^^ (b >>> 17)
  d ^^^ (d <<< 5)

def value_select (t x y : UInt32) : UInt32 := if t == 0 then x else y

def value_difference (a b : UInt32) : UInt32 :=
  value_select (if a < b then 1 else 0) (a - b) (b - a)

-- materialize a candidate AST straight off the hash stream
partial def expr_gen (d h : UInt32) : Expr :=
  if d == 0 then
    if ((h >>> 8) &&& 1) == 0 then Expr.var else Expr.lit (h &&& 255)
  else
    let a := expr_gen (d - 1) (word_prng (h ^^^ 2654435761))
    let b := expr_gen (d - 1) (word_prng (h + 340573321))
    match h % 4 with
    | 0 => Expr.add a b
    | 1 => Expr.sub a b
    | 2 => Expr.mul a b
    | _ => Expr.xor a b

-- pattern-matching interpreter: value of the candidate at x
def expr_eval (e : Expr) (x : UInt32) : UInt32 :=
  match e with
  | Expr.var => x
  | Expr.lit v => v
  | Expr.add a b => expr_eval a x + expr_eval b x
  | Expr.sub a b => expr_eval a x - expr_eval b x
  | Expr.mul a b => expr_eval a x * expr_eval b x
  | Expr.xor a b => expr_eval a x ^^^ expr_eval b x

-- parsimony: AST node count
def expr_size (e : Expr) : UInt32 :=
  match e with
  | Expr.var => 1
  | Expr.lit _ => 1
  | Expr.add a b => 1 + (expr_size a + expr_size b)
  | Expr.sub a b => 1 + (expr_size a + expr_size b)
  | Expr.mul a b => 1 + (expr_size a + expr_size b)
  | Expr.xor a b => 1 + (expr_size a + expr_size b)

-- dataset fold: error sum over x = 0..j-1, then the parsimony penalty
partial def fitness_loop (j : UInt32) (e : Expr) (acc : UInt32) : UInt32 :=
  if j == 0 then acc + expr_size e * 8 else
    let x := j - 1
    let p := expr_eval e x
    let t := x * x + (3 * x + 7)
    fitness_loop x e (acc + value_difference p t)

structure Sel where
  fit : UInt32
  seed : UInt32
  sum : UInt32
  deriving Inhabited

def candidate_evaluate (s pts : UInt32) : Sel :=
  let t := expr_gen 5 (word_prng s)
  let f := fitness_loop pts t 0
  ⟨f, s, f ^^^ (s * 2654435761)⟩

-- tournament: keep the lower-fitness candidate, sum the checksums
def winner_pick (a b : Sel) : Sel :=
  let w : UInt32 := if a.fit < b.fit then 1 else 0
  ⟨value_select w b.fit a.fit, value_select w b.seed a.seed, a.sum + b.sum⟩

partial def batch_run (d s pts : UInt32) : Sel :=
  if d == 0 then candidate_evaluate (word_prng s) pts else
    let a := batch_run (d - 1) (s * 1664525 + 1) pts
    let b := batch_run (d - 1) (s * 214013 + 3) pts
    winner_pick a b

-- hill-climb the tournament winner: mutate the seed, keep improvements
partial def seed_climb (r bs bf pts : UInt32) : UInt32 :=
  if r == 0 then bf ^^^ (bs * 2654435761) else
    let w0 := candidate_evaluate (word_prng (bs ^^^ (r * 40503))) pts
    let w : UInt32 := if w0.fit < bf then 1 else 0
    seed_climb (r - 1) (value_select w bs w0.seed) (value_select w bf w0.fit) pts

def benchmark_run : UInt32 :=
  let w1 := batch_run popDepth 42 dataPoints
  seed_climb climbRounds w1.seed w1.fit dataPoints + w1.sum

def main : IO Unit := IO.println benchmark_run
