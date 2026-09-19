# compare: cmp hands back both originals with the verdict; order/eq and the
# relations are unsigned code-point order; a proper prefix sorts first;
# unequal lengths are never equal; Map keeps working over the comparator
import Base

def main() -> ((String & String) & Cmp) & ((Cmp & (Cmp & Cmp)) & ((Bool & Bool) & (Bool & (Bool & (Bool & Nat))))):
  (String.cmp("abc", "abd"),
   ((String.order("ab", "abc"), (String.order("abc", "ab"), String.order("b", "abc"))),
    ((String.eq("same", "same"), String.eq("same", "samé")),
     (String.is_lt("", "a"),
      (String.is_ge("a", "a"),
       (String.is_gt("Z", "a"),
        Pair.snd(Map<&2, Nat>, Nat, Map.get(Nat, 0n,
          Map.set(&2, Nat, Map.set(&2, Nat, Map.new(&2, Nat), "ab", 1n), "abc", 2n),
          "abc"))))))))

#|((("abc", "abd"), LT{}), (LT{}, GT{}, GT{}), (True{}, False{}), True{}, True{}, False{}, 2n)
