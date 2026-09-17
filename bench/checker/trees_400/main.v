Inductive Nat : Type :=
  | Z : Nat
  | S : Nat -> Nat.

Fixpoint add (a b : Nat) : Nat :=
  match a with
  | Z => b
  | S a => S (add a b)
  end.

Definition n0 : Nat := Z.
Definition n1 : Nat := S n0.
Definition n2 : Nat := S n1.
Definition n3 : Nat := S n2.
Definition n4 : Nat := S n3.
Definition n5 : Nat := S n4.
Definition n6 : Nat := S n5.
Definition n7 : Nat := S n6.
Definition n8 : Nat := S n7.
Definition n9 : Nat := S n8.
Definition n10 : Nat := S n9.
Definition n11 : Nat := S n10.
Definition n12 : Nat := S n11.
Definition n13 : Nat := S n12.

Inductive Boolb : Type :=
  | T : Boolb
  | F : Boolb.

Definition andb2 (a b : Boolb) : Boolb :=
  match a with
  | T => b
  | F => F
  end.

Inductive Tree : Type :=
  | L : Tree
  | N : Tree -> Tree -> Tree.

Fixpoint full (n : Nat) : Tree :=
  match n with
  | Z => L
  | S p => N (full p) (full p)
  end.

Fixpoint mirror (t : Tree) : Tree :=
  match t with
  | L => L
  | N l r => N (mirror r) (mirror l)
  end.

Fixpoint alltrue (t : Tree) : Boolb :=
  match t with
  | L => T
  | N l r => andb2 (alltrue l) (alltrue r)
  end.

Lemma ft0 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt0 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft1 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt1 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft2 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt2 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft3 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt3 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft4 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt4 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft5 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt5 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft6 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt6 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft7 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt7 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft8 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt8 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft9 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt9 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft10 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt10 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft11 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt11 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft12 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt12 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft13 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt13 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft14 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt14 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft15 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt15 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft16 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt16 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft17 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt17 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft18 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt18 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft19 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt19 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft20 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt20 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft21 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt21 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft22 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt22 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft23 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt23 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft24 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt24 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft25 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt25 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft26 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt26 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft27 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt27 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft28 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt28 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft29 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt29 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft30 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt30 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft31 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt31 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft32 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt32 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft33 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt33 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft34 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt34 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft35 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt35 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft36 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt36 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft37 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt37 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft38 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt38 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft39 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt39 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft40 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt40 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft41 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt41 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft42 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt42 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft43 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt43 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft44 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt44 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft45 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt45 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft46 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt46 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft47 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt47 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft48 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt48 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft49 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt49 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft50 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt50 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft51 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt51 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft52 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt52 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft53 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt53 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft54 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt54 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft55 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt55 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft56 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt56 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft57 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt57 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft58 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt58 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft59 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt59 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft60 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt60 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft61 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt61 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft62 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt62 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft63 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt63 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft64 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt64 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft65 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt65 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft66 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt66 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft67 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt67 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft68 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt68 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft69 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt69 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft70 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt70 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft71 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt71 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft72 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt72 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft73 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt73 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft74 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt74 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft75 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt75 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft76 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt76 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft77 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt77 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft78 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt78 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft79 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt79 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft80 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt80 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft81 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt81 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft82 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt82 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft83 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt83 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft84 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt84 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft85 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt85 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft86 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt86 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft87 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt87 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft88 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt88 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft89 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt89 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft90 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt90 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft91 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt91 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft92 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt92 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft93 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt93 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft94 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt94 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft95 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt95 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft96 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt96 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft97 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt97 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft98 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt98 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft99 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt99 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft100 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt100 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft101 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt101 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft102 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt102 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft103 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt103 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft104 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt104 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft105 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt105 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft106 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt106 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft107 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt107 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft108 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt108 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft109 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt109 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft110 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt110 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft111 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt111 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft112 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt112 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft113 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt113 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft114 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt114 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft115 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt115 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft116 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt116 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft117 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt117 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft118 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt118 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft119 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt119 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft120 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt120 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft121 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt121 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft122 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt122 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft123 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt123 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft124 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt124 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft125 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt125 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft126 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt126 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft127 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt127 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft128 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt128 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft129 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt129 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft130 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt130 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft131 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt131 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft132 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt132 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft133 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt133 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft134 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt134 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft135 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt135 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft136 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt136 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft137 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt137 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft138 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt138 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft139 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt139 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft140 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt140 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft141 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt141 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft142 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt142 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft143 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt143 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft144 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt144 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft145 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt145 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft146 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt146 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft147 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt147 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft148 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt148 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft149 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt149 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft150 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt150 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft151 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt151 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft152 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt152 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft153 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt153 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft154 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt154 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft155 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt155 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft156 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt156 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft157 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt157 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft158 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt158 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft159 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt159 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft160 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt160 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft161 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt161 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft162 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt162 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft163 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt163 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft164 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt164 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft165 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt165 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft166 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt166 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft167 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt167 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft168 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt168 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft169 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt169 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft170 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt170 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft171 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt171 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft172 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt172 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft173 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt173 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft174 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt174 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft175 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt175 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft176 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt176 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft177 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt177 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft178 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt178 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft179 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt179 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft180 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt180 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft181 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt181 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft182 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt182 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft183 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt183 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft184 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt184 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft185 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt185 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft186 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt186 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft187 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt187 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft188 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt188 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft189 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt189 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft190 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt190 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft191 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt191 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft192 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt192 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft193 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt193 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft194 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt194 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft195 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt195 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft196 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt196 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft197 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt197 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft198 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt198 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft199 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt199 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft200 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt200 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft201 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt201 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft202 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt202 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft203 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt203 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft204 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt204 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft205 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt205 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft206 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt206 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft207 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt207 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft208 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt208 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft209 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt209 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft210 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt210 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft211 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt211 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft212 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt212 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft213 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt213 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft214 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt214 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft215 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt215 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft216 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt216 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft217 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt217 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft218 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt218 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft219 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt219 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft220 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt220 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft221 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt221 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft222 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt222 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft223 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt223 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft224 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt224 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft225 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt225 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft226 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt226 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft227 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt227 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft228 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt228 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft229 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt229 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft230 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt230 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft231 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt231 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft232 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt232 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft233 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt233 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft234 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt234 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft235 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt235 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft236 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt236 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft237 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt237 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft238 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt238 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft239 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt239 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft240 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt240 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft241 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt241 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft242 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt242 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft243 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt243 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft244 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt244 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft245 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt245 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft246 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt246 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft247 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt247 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft248 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt248 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft249 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt249 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft250 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt250 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft251 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt251 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft252 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt252 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft253 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt253 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft254 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt254 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft255 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt255 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft256 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt256 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft257 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt257 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft258 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt258 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft259 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt259 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft260 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt260 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft261 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt261 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft262 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt262 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft263 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt263 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft264 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt264 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft265 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt265 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft266 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt266 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft267 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt267 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft268 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt268 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft269 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt269 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft270 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt270 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft271 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt271 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft272 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt272 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft273 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt273 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft274 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt274 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft275 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt275 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft276 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt276 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft277 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt277 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft278 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt278 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft279 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt279 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft280 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt280 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft281 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt281 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft282 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt282 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft283 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt283 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft284 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt284 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft285 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt285 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft286 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt286 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft287 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt287 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft288 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt288 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft289 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt289 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft290 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt290 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft291 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt291 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft292 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt292 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft293 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt293 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft294 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt294 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft295 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt295 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft296 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt296 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft297 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt297 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft298 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt298 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft299 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt299 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft300 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt300 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft301 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt301 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft302 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt302 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft303 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt303 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft304 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt304 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft305 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt305 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft306 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt306 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft307 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt307 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft308 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt308 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft309 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt309 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft310 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt310 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft311 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt311 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft312 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt312 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft313 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt313 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft314 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt314 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft315 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt315 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft316 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt316 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft317 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt317 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft318 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt318 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft319 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt319 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft320 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt320 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft321 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt321 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft322 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt322 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft323 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt323 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft324 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt324 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft325 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt325 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft326 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt326 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft327 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt327 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft328 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt328 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft329 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt329 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft330 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt330 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft331 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt331 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft332 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt332 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft333 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt333 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft334 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt334 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft335 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt335 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft336 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt336 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft337 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt337 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft338 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt338 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft339 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt339 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft340 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt340 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft341 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt341 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft342 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt342 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft343 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt343 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft344 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt344 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft345 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt345 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft346 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt346 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft347 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt347 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft348 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt348 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft349 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt349 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft350 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt350 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft351 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt351 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft352 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt352 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft353 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt353 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft354 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt354 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft355 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt355 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft356 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt356 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft357 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt357 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft358 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt358 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft359 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt359 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft360 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt360 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft361 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt361 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft362 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt362 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft363 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt363 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft364 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt364 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft365 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt365 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft366 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt366 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft367 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt367 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft368 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt368 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft369 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt369 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft370 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt370 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft371 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt371 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft372 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt372 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft373 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt373 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft374 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt374 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft375 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt375 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft376 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt376 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft377 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt377 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft378 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt378 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft379 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt379 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft380 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt380 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft381 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt381 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft382 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt382 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft383 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt383 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft384 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt384 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft385 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt385 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft386 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt386 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft387 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt387 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft388 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt388 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft389 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt389 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft390 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt390 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft391 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt391 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft392 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt392 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft393 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt393 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft394 : alltrue (full n9) = T.
Proof. reflexivity. Qed.

Lemma mt394 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

Lemma ft395 : alltrue (full n8) = T.
Proof. reflexivity. Qed.

Lemma mt395 : mirror (full n6) = full n6.
Proof. reflexivity. Qed.

Lemma ft396 : alltrue (full n7) = T.
Proof. reflexivity. Qed.

Lemma mt396 : mirror (full n9) = full n9.
Proof. reflexivity. Qed.

Lemma ft397 : alltrue (full n12) = T.
Proof. reflexivity. Qed.

Lemma mt397 : mirror (full n7) = full n7.
Proof. reflexivity. Qed.

Lemma ft398 : alltrue (full n11) = T.
Proof. reflexivity. Qed.

Lemma mt398 : mirror (full n10) = full n10.
Proof. reflexivity. Qed.

Lemma ft399 : alltrue (full n10) = T.
Proof. reflexivity. Qed.

Lemma mt399 : mirror (full n8) = full n8.
Proof. reflexivity. Qed.

