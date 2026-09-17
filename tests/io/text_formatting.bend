# compiled text building: number formatting (U32.MAX) and string
# building (concat, join) as one built line
# ported from bend3: no IO driver -- main returns the built text as a
# pure String (the io corpus rides pure values); the F32.show entries
# become a second U32.show entry (bend has no float text); the C
# lanes await tocl's u32_copy/u32_cmp (reg_word_copy_native pins it);
# the join separator wears + (String is Data, so it duplicates freely)
import Base

law main.out:
  String

def main.out():
  line = String.join([U32.show(4294967295), U32.show(42)], ",")
  String.append(line, String.append(",", String.append("ab", "cd")))

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|4294967295,42,abcd
