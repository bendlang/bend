# A small logistics team processes a queue of delivery-note snippet identifiers.
# Implement removal of a requested prefix, stopping at an empty queue.
# Processing two requests must leave the same queue size as their combined request.
import Base

def count(xs: +List<Nat>) -> Nat:
  match xs:
    case Nil{}: 0n
    case Con{x, rest}: 1n+count(rest)

law trim:
  for xs: +List<Nat>
  for n: Nat
  +List<Nat>

law trim_empty:
  for n: Nat
  {trim(Nil{}, n) == Nil{} : +List<Nat>}

law trim_zero:
  for xs: +List<Nat>
  {trim(xs, 0n) == xs : +List<Nat>}

law trim_next:
  for x: Nat
  for xs: +List<Nat>
  for n: Nat
  {trim(Con{x, xs}, 1n+n) == trim(xs, n) : +List<Nat>}

law combined_requests:
  for xs: +List<Nat>
  for first: Nat
  for second: Nat
  {count(trim(trim(xs, first), second)) == count(trim(xs, Nat.add(first, second))) : Nat}

# solution

def trim(xs, n):
  match xs:
    case Nil{}: Nil{}
    case Con{x, rest}:
      match n:
        case 0n: Con{x, rest}
        case 1n+p: trim(rest, p)

def trim_empty(n): {==}

def trim_zero(xs):
  match xs:
    case Nil{}: {==}
    case Con{x, rest}: {==}

def trim_next(x, xs, n): {==}

def combined_requests(xs, first, second):
  match xs:
    case Nil{}: {==}
    case Con{x, rest}:
      match first:
        case 0n: {==}
        case 1n+p: combined_requests(rest, p, second)
