# a type def whose unfolding calls itself again (F = F -> Empty, G's
# domain, H(A) = H(A) -> A) has no finite η-long form, so --verdict
# sends a term of it whole instead of expanding it forever (#1164); a
# finite function type still goes η-long, also when its unfolding calls
# its def at other arguments (Endo, Fun, V, C)
import Base

def F() -> Type:
  @-x: F -> Empty

def id_f(x: F) -> F:
  x

def om(f: @-x: F -> Empty) -> Empty:
  f(f)

def keep(f: @-x: F -> Empty) -> @-x: F -> Empty:
  f

def G() -> Type:
  (G -> U32) -> U32

def run(g: G, k: G -> U32) -> U32:
  g(k)

def H(A: Type) -> Type:
  @-x: H(A) -> A

def keep_h(f: H(U32)) -> H(U32):
  f

def id_h(-A: Type, x: H(A)) -> H(A):
  x

# H3's unfolding calls H3 at the variable its own ∀ binds, one ∀ deeper
# each time: the same type, up to that variable
def H3(A: Type) -> Type:
  @-B: Type -> @-x: H3(B) -> A

def keep_h3(f: H3(U32)) -> H3(U32):
  f

def Endo(A: Type) -> Type:
  A -> A

def same_endo(f: Endo(Endo(U32))) -> {f == (x => f(x)) : Endo(Endo(U32))}:
  {==}

def Fun(n: Nat) -> Type:
  match n:
    case 0n: U32
    case 1n+p: U32 -> Fun(p)

def same_fun(f: Fun(2n)) -> {f == (x => f(x)) : Fun(2n)}:
  {==}

def Fn() -> Type:
  U32 -> U32

def same_fn(f: Fn) -> {f == (x => f(x)) : Fn}:
  {==}

# P is no def that calls itself: it goes η-long down to the F
def P() -> Type:
  (U32 -> U32) -> F

def same_p(p: P) -> {p == (k => p(k)) : P}:
  {==}

# K calls itself at ever larger arguments: no repeat, but no end
def K(n: Nat) -> Type:
  @-x: K((1n + n : Nat)) -> U32

def keep_k(f: K(0n)) -> K(0n):
  f

# W(z, z => z) is finite: the W(z, _ => z) inside it is another type,
# told apart only if the scope's z is not read as a variable W binds
def Sel(n: Nat, A: Type) -> Type:
  match n:
    case 0n: U32
    case 1n+p: A

def W(a: Nat, f: Nat -> Nat) -> Type:
  Sel(f(1n), @-x: W(a, z => a) -> U32)

def same_w(z: Nat, g: W(z, z => z)) -> {g == (y => g(y)) : W(z, z => z)}:
  {==}

# F written out goes η-long one level, down to its F
def same_lit(f: @-x: F -> Empty) -> {f == (x => f(x)) : @-x: F -> Empty}:
  {==}

# V's first argument grows while its second shrinks: finite
def Two(A: Type) -> Type:
  A -> A

def V(A: Type, n: Nat) -> Type:
  match n:
    case 0n: A
    case 1n+p: A -> V(Two(A), p)

def same_v(f: V(U32, 2n)) -> {f == (x => f(x)) : V(U32, 2n)}:
  {==}

# C counts up in one argument and down in the other: finite
def C(i: Nat, n: Nat) -> Type:
  match n:
    case 0n: U32
    case 1n+p: U32 -> C((1n + i : Nat), p)

def same_c(f: C(0n, 2n)) -> {f == (x => f(x)) : C(0n, 2n)}:
  {==}

# MA and MB grow through each other
def MA(n: Nat) -> Type:
  @-x: MB((1n + n : Nat)) -> U32

def MB(n: Nat) -> Type:
  @-x: MA((1n + n : Nat)) -> U32

def keep_m(f: MA(0n)) -> MA(0n):
  f

# Dbl(24n) unfolds to 2^24 paths over 25 types: each is walked once
def Dbl(n: Nat) -> Type:
  match n:
    case 0n: F
    case 1n+p: Dbl(p) -> Dbl(p)

def R() -> Type:
  @-x: Dbl(24n) -> @-y: R -> Empty

def keep_r(f: R) -> R:
  f

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
