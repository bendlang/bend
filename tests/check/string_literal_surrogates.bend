# a literal that spells a surrogate is not one JS string's worth of
# Unicode scalar values, so it parses as its constructor chain and still
# means two characters
import Base

def main() -> Nat:
  String.length("\u{d83d}\u{de00}")

#|2n
