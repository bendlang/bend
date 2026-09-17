theory main
  imports Main
begin

datatype Nat = Z | S Nat

fun add :: "Nat => Nat => Nat" where
  "add Z b = b"
| "add (S a) b = S (add a b)"

definition n0 :: "Nat" where "n0 = Z"
definition n1 :: "Nat" where "n1 = S n0"
definition n2 :: "Nat" where "n2 = S n1"
definition n3 :: "Nat" where "n3 = S n2"
definition n4 :: "Nat" where "n4 = S n3"
definition n5 :: "Nat" where "n5 = S n4"
definition n6 :: "Nat" where "n6 = S n5"
definition n7 :: "Nat" where "n7 = S n6"
definition n8 :: "Nat" where "n8 = S n7"
definition n9 :: "Nat" where "n9 = S n8"
definition n10 :: "Nat" where "n10 = S n9"
definition n11 :: "Nat" where "n11 = S n10"
definition n12 :: "Nat" where "n12 = S n11"
definition n13 :: "Nat" where "n13 = S n12"

datatype Boolb = T | F

fun andb2 :: "Boolb => Boolb => Boolb" where
  "andb2 T b = b"
| "andb2 F b = F"

datatype Tree = L | N Tree Tree

fun full :: "Nat => Tree" where
  "full Z = L"
| "full (S p) = N (full p) (full p)"

fun mirror :: "Tree => Tree" where
  "mirror L = L"
| "mirror (N l r) = N (mirror r) (mirror l)"

fun alltrue :: "Tree => Boolb" where
  "alltrue L = T"
| "alltrue (N l r) = andb2 (alltrue l) (alltrue r)"

lemma ft0: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt0: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft1: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt1: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft2: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt2: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft3: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt3: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft4: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt4: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft5: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt5: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft6: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt6: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft7: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt7: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft8: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt8: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft9: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt9: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft10: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt10: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft11: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt11: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft12: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt12: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft13: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt13: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft14: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt14: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft15: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt15: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft16: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt16: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft17: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt17: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft18: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt18: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft19: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt19: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft20: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt20: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft21: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt21: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft22: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt22: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft23: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt23: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft24: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt24: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft25: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt25: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft26: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt26: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft27: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt27: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft28: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt28: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft29: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt29: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft30: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt30: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft31: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt31: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft32: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt32: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft33: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt33: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft34: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt34: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft35: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt35: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft36: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt36: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft37: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt37: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft38: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt38: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft39: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt39: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft40: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt40: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft41: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt41: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft42: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt42: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft43: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt43: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft44: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt44: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft45: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt45: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft46: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt46: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft47: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt47: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft48: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt48: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft49: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt49: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft50: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt50: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft51: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt51: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft52: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt52: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft53: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt53: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft54: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt54: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft55: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt55: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft56: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt56: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft57: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt57: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft58: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt58: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft59: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt59: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft60: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt60: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft61: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt61: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft62: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt62: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft63: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt63: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft64: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt64: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft65: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt65: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft66: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt66: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft67: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt67: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft68: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt68: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft69: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt69: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft70: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt70: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft71: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt71: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft72: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt72: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft73: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt73: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft74: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt74: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft75: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt75: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft76: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt76: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft77: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt77: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft78: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt78: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft79: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt79: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft80: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt80: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft81: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt81: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft82: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt82: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft83: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt83: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft84: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt84: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft85: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt85: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft86: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt86: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft87: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt87: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft88: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt88: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft89: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt89: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft90: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt90: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft91: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt91: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft92: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt92: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft93: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt93: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft94: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt94: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft95: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt95: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft96: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt96: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft97: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt97: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft98: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt98: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft99: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt99: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft100: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt100: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft101: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt101: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft102: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt102: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft103: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt103: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft104: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt104: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft105: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt105: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft106: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt106: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft107: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt107: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft108: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt108: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft109: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt109: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft110: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt110: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft111: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt111: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft112: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt112: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft113: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt113: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft114: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt114: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft115: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt115: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft116: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt116: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft117: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt117: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft118: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt118: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft119: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt119: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft120: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt120: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft121: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt121: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft122: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt122: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft123: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt123: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft124: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt124: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft125: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt125: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft126: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt126: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft127: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt127: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft128: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt128: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft129: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt129: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft130: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt130: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft131: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt131: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft132: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt132: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft133: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt133: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft134: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt134: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft135: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt135: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft136: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt136: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft137: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt137: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft138: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt138: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft139: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt139: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft140: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt140: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft141: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt141: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft142: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt142: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft143: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt143: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft144: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt144: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft145: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt145: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft146: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt146: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft147: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt147: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft148: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt148: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft149: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt149: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft150: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt150: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft151: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt151: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft152: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt152: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft153: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt153: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft154: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt154: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft155: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt155: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft156: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt156: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft157: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt157: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft158: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt158: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft159: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt159: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft160: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt160: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft161: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt161: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft162: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt162: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft163: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt163: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft164: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt164: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft165: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt165: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft166: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt166: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft167: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt167: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft168: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt168: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft169: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt169: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft170: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt170: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft171: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt171: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft172: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt172: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft173: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt173: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft174: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt174: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft175: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt175: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft176: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt176: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft177: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt177: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft178: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt178: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft179: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt179: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft180: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt180: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft181: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt181: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft182: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt182: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft183: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt183: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft184: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt184: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft185: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt185: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft186: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt186: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft187: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt187: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft188: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt188: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft189: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt189: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft190: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt190: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft191: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt191: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft192: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt192: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft193: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt193: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft194: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt194: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft195: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt195: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft196: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt196: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft197: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt197: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft198: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt198: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft199: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt199: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft200: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt200: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft201: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt201: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft202: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt202: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft203: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt203: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft204: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt204: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft205: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt205: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft206: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt206: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft207: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt207: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft208: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt208: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft209: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt209: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft210: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt210: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft211: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt211: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft212: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt212: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft213: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt213: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft214: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt214: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft215: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt215: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft216: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt216: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft217: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt217: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft218: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt218: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft219: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt219: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft220: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt220: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft221: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt221: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft222: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt222: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft223: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt223: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft224: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt224: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft225: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt225: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft226: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt226: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft227: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt227: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft228: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt228: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft229: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt229: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft230: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt230: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft231: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt231: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft232: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt232: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft233: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt233: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft234: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt234: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft235: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt235: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft236: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt236: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft237: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt237: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft238: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt238: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft239: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt239: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft240: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt240: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft241: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt241: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft242: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt242: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft243: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt243: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft244: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt244: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft245: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt245: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft246: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt246: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft247: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt247: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft248: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt248: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft249: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt249: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft250: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt250: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft251: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt251: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft252: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt252: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft253: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt253: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft254: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt254: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft255: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt255: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft256: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt256: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft257: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt257: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft258: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt258: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft259: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt259: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft260: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt260: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft261: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt261: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft262: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt262: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft263: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt263: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft264: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt264: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft265: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt265: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft266: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt266: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft267: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt267: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft268: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt268: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft269: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt269: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft270: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt270: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft271: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt271: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft272: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt272: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft273: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt273: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft274: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt274: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft275: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt275: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft276: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt276: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft277: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt277: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft278: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt278: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft279: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt279: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft280: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt280: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft281: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt281: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft282: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt282: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft283: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt283: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft284: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt284: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft285: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt285: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft286: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt286: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft287: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt287: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft288: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt288: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft289: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt289: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft290: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt290: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft291: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt291: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft292: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt292: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft293: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt293: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft294: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt294: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft295: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt295: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft296: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt296: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft297: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt297: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft298: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt298: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft299: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt299: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft300: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt300: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft301: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt301: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft302: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt302: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft303: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt303: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft304: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt304: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft305: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt305: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft306: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt306: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft307: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt307: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft308: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt308: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft309: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt309: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft310: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt310: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft311: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt311: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft312: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt312: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft313: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt313: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft314: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt314: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft315: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt315: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft316: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt316: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft317: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt317: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft318: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt318: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft319: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt319: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft320: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt320: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft321: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt321: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft322: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt322: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft323: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt323: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft324: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt324: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft325: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt325: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft326: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt326: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft327: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt327: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft328: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt328: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft329: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt329: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft330: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt330: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft331: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt331: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft332: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt332: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft333: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt333: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft334: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt334: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft335: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt335: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft336: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt336: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft337: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt337: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft338: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt338: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft339: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt339: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft340: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt340: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft341: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt341: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft342: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt342: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft343: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt343: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft344: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt344: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft345: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt345: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft346: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt346: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft347: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt347: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft348: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt348: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft349: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt349: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft350: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt350: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft351: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt351: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft352: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt352: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft353: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt353: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft354: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt354: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft355: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt355: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft356: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt356: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft357: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt357: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft358: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt358: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft359: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt359: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft360: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt360: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft361: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt361: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft362: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt362: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft363: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt363: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft364: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt364: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft365: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt365: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft366: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt366: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft367: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt367: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft368: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt368: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft369: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt369: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft370: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt370: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft371: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt371: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft372: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt372: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft373: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt373: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft374: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt374: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft375: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt375: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft376: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt376: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft377: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt377: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft378: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt378: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft379: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt379: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft380: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt380: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft381: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt381: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft382: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt382: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft383: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt383: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft384: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt384: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft385: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt385: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft386: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt386: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft387: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt387: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft388: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt388: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft389: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt389: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft390: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt390: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft391: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt391: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft392: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt392: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft393: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt393: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft394: "alltrue (full n9) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt394: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft395: "alltrue (full n8) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt395: "mirror (full n6) = full n6"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft396: "alltrue (full n7) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt396: "mirror (full n9) = full n9"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft397: "alltrue (full n12) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt397: "mirror (full n7) = full n7"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft398: "alltrue (full n11) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt398: "mirror (full n10) = full n10"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma ft399: "alltrue (full n10) = T"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

lemma mt399: "mirror (full n8) = full n8"
  by (simp add: n0_def n1_def n2_def n3_def n4_def n5_def n6_def n7_def n8_def n9_def n10_def n11_def n12_def n13_def)

end
