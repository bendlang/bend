# a string literal is one Lit node in the checker; it unfolds a character
# at a time where a chain is read: a comparison sees "ab" as
# SCon{'a', "b"}, "" as SNil{}, a match reads a literal pattern and a
# literal scrutinee, and the evaluator steps through a literal's length.
# a character is any u32, so a literal may spell a surrogate pair.
import Base

law ab_is_chain:
  {"ab" == SCon{'a', "b"} : String}

def ab_is_chain():
  {==}

law empty_is_nil:
  {"" == SNil{} : String}

def empty_is_nil():
  {==}

law length_three:
  {String.length("abc") == 3n : Nat}

def length_three():
  {==}

law append_lits:
  {String.append("ab", "cd") == "abcd" : String}

def append_lits():
  {==}

law eq_lits:
  {String.eq("héllo", "héllo") == True{} : Bool}

def eq_lits():
  {==}

law surrogates_two:
  {String.length("\u{d83d}\u{de00}") == 2n : Nat}

def surrogates_two():
  {==}

def classify(s: String) -> Nat:
  match s:
    case "":
      0n
    case "one":
      1n
    case "two":
      2n
    case _:
      9n

law classify_two:
  {classify("two") == 2n : Nat}

def classify_two():
  {==}

law classify_more:
  {classify("twoo") == 9n : Nat}

def classify_more():
  {==}

def main() -> List<&2, Nat>:
  [classify(""), classify("one"), classify("two"), classify("x"), String.length("😀é")]

#|[0n, 1n, 2n, 9n, 2n]
