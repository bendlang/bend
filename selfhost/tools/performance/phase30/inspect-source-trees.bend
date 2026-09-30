import Base

def flip_bool(flag: Bool) -> Bool:
  match flag:
    case False{}: True{}
    case True{}: False{}

def and_not_bool(flag: Bool, +value: Bool) -> Bool:
  match flag:
    case False{}: False{}
    case True{}: flip_bool(value)

@unsafe
def bool_tree(+n: Nat, +state: U32) -> Bool:
  match n:
    case 0n: U32.is_lt(U32.and(state, 7), 3)
    case 1n+p:
      left right = bool_tree(p, U32.inc(state)) bool_tree(p, U32.mul(state, 3))
      and_not_bool(left, right)

@unsafe
def nat_tree(+n: Nat, +state: U32) -> Nat:
  match n:
    case 0n: U32.to_nat(state)
    case 1n+p:
      left right = nat_tree(p, U32.inc(state)) nat_tree(p, U32.mul(state, 3))
      U32.to_nat(U32.sub(U32.from_nat(left), U32.from_nat(right)))

@unsafe
def select_nat(flag: Bool, +left: Nat) -> Nat:
  match flag:
    case True{}: left
    case False{}: 0n

@unsafe
def nat_state_tree(+n: Nat, +state: Nat) -> Nat:
  match n:
    case 0n: state
    case 1n+p:
      left right = nat_state_tree(p, state) nat_state_tree(p, 0n)
      select_nat(U32.is_eq(U32.from_nat(right), 0), left)

@unsafe
def parent_capture(+n: Nat, +state: U32) -> U32:
  match n:
    case 0n: state
    case 1n+p:
      left right = parent_capture(p, U32.inc(state)) parent_capture(p, U32.mul(state, 3))
      U32.add(U32.sub(left, right), state)

@unsafe
def one_child(+n: Nat, +state: U32) -> U32:
  match n:
    case 0n: state
    case 1n+p:
      +left = one_child(p, U32.inc(state))
      U32.add(left, left)

@unsafe
def three_children(+n: Nat, +state: U32) -> U32:
  match n:
    case 0n: state
    case 1n+p:
      left right extra = three_children(p, U32.inc(state)) three_children(p, U32.mul(state, 3)) three_children(p, U32.xor(state, 85))
      U32.sub(U32.add(left, extra), right)

@unsafe
def changed_predecessor(+n: Nat, +state: U32) -> U32:
  match n:
    case 0n: state
    case 1n+p:
      left right = changed_predecessor(p, U32.inc(state)) changed_predecessor(0n, U32.mul(state, 3))
      U32.sub(left, right)

@unsafe
def float_tree(+n: Nat, +state: F32) -> F32:
  match n:
    case 0n: state
    case 1n+p:
      left right = float_tree(p, F32.add(state, 0.5)) float_tree(p, F32.mul(state, 3.0))
      F32.sub(left, right)

type TreeResult is Data:
  TreeResultValue{+word: U32}

def result_word(value: TreeResult) -> U32:
  match value:
    case TreeResultValue{word}: word

@unsafe
def record_tree(+n: Nat, +state: U32) -> TreeResult:
  match n:
    case 0n: TreeResultValue{state}
    case 1n+p:
      left right = record_tree(p, U32.inc(state)) record_tree(p, U32.mul(state, 3))
      TreeResultValue{U32.sub(result_word(left), result_word(right))}

def record_value(n: Nat, state: U32) -> U32:
  result_word(record_tree(n, state))

# Separate source lets intentionally remain outside the strict parallel shape.
@unsafe
def sequential_tree(+n: Nat, +state: U32) -> U32:
  match n:
    case 0n: state
    case 1n+p:
      +left = sequential_tree(p, U32.inc(state))
      +right = sequential_tree(p, U32.mul(state, 3))
      U32.sub(left, right)

# Native Base helpers are deliberately outside the private source-copy proof.
@unsafe
def native_bool_tree(+n: Nat, +state: U32) -> Bool:
  match n:
    case 0n: U32.is_lt(U32.and(state, 7), 3)
    case 1n+p:
      left right = native_bool_tree(p, U32.inc(state)) native_bool_tree(p, U32.mul(state, 3))
      Bool.and(left, Bool.not(right))
