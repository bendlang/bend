module main where

data Eq {A : Set} (x : A) : A -> Set where
  refl : Eq x x
{-# BUILTIN EQUALITY Eq #-}

data Nat : Set where
  Z : Nat
  S : Nat -> Nat

add : Nat -> Nat -> Nat
add Z b = b
add (S a) b = S (add a b)

n0 : Nat
n0 = Z
n1 : Nat
n1 = S n0
n2 : Nat
n2 = S n1
n3 : Nat
n3 = S n2
n4 : Nat
n4 = S n3
n5 : Nat
n5 = S n4
n6 : Nat
n6 = S n5
n7 : Nat
n7 = S n6
n8 : Nat
n8 = S n7
n9 : Nat
n9 = S n8
n10 : Nat
n10 = S n9
n11 : Nat
n11 = S n10
n12 : Nat
n12 = S n11
n13 : Nat
n13 = S n12

data Bool : Set where
  T : Bool
  F : Bool

and : Bool -> Bool -> Bool
and T b = b
and F b = F

data Tree : Set where
  L : Tree
  N : Tree -> Tree -> Tree

full : Nat -> Tree
full Z = L
full (S p) = N (full p) (full p)

mirror : Tree -> Tree
mirror L = L
mirror (N l r) = N (mirror r) (mirror l)

alltrue : Tree -> Bool
alltrue L = T
alltrue (N l r) = and (alltrue l) (alltrue r)

ft0 : Eq (alltrue (full n7)) T
ft0 = refl

mt0 : Eq (mirror (full n6)) (full n6)
mt0 = refl

ft1 : Eq (alltrue (full n12)) T
ft1 = refl

mt1 : Eq (mirror (full n9)) (full n9)
mt1 = refl

ft2 : Eq (alltrue (full n11)) T
ft2 = refl

mt2 : Eq (mirror (full n7)) (full n7)
mt2 = refl

ft3 : Eq (alltrue (full n10)) T
ft3 = refl

mt3 : Eq (mirror (full n10)) (full n10)
mt3 = refl

ft4 : Eq (alltrue (full n9)) T
ft4 = refl

mt4 : Eq (mirror (full n8)) (full n8)
mt4 = refl

ft5 : Eq (alltrue (full n8)) T
ft5 = refl

mt5 : Eq (mirror (full n6)) (full n6)
mt5 = refl

ft6 : Eq (alltrue (full n7)) T
ft6 = refl

mt6 : Eq (mirror (full n9)) (full n9)
mt6 = refl

ft7 : Eq (alltrue (full n12)) T
ft7 = refl

mt7 : Eq (mirror (full n7)) (full n7)
mt7 = refl

ft8 : Eq (alltrue (full n11)) T
ft8 = refl

mt8 : Eq (mirror (full n10)) (full n10)
mt8 = refl

ft9 : Eq (alltrue (full n10)) T
ft9 = refl

mt9 : Eq (mirror (full n8)) (full n8)
mt9 = refl

ft10 : Eq (alltrue (full n9)) T
ft10 = refl

mt10 : Eq (mirror (full n6)) (full n6)
mt10 = refl

ft11 : Eq (alltrue (full n8)) T
ft11 = refl

mt11 : Eq (mirror (full n9)) (full n9)
mt11 = refl

ft12 : Eq (alltrue (full n7)) T
ft12 = refl

mt12 : Eq (mirror (full n7)) (full n7)
mt12 = refl

ft13 : Eq (alltrue (full n12)) T
ft13 = refl

mt13 : Eq (mirror (full n10)) (full n10)
mt13 = refl

ft14 : Eq (alltrue (full n11)) T
ft14 = refl

mt14 : Eq (mirror (full n8)) (full n8)
mt14 = refl

ft15 : Eq (alltrue (full n10)) T
ft15 = refl

mt15 : Eq (mirror (full n6)) (full n6)
mt15 = refl

ft16 : Eq (alltrue (full n9)) T
ft16 = refl

mt16 : Eq (mirror (full n9)) (full n9)
mt16 = refl

ft17 : Eq (alltrue (full n8)) T
ft17 = refl

mt17 : Eq (mirror (full n7)) (full n7)
mt17 = refl

ft18 : Eq (alltrue (full n7)) T
ft18 = refl

mt18 : Eq (mirror (full n10)) (full n10)
mt18 = refl

ft19 : Eq (alltrue (full n12)) T
ft19 = refl

mt19 : Eq (mirror (full n8)) (full n8)
mt19 = refl

ft20 : Eq (alltrue (full n11)) T
ft20 = refl

mt20 : Eq (mirror (full n6)) (full n6)
mt20 = refl

ft21 : Eq (alltrue (full n10)) T
ft21 = refl

mt21 : Eq (mirror (full n9)) (full n9)
mt21 = refl

ft22 : Eq (alltrue (full n9)) T
ft22 = refl

mt22 : Eq (mirror (full n7)) (full n7)
mt22 = refl

ft23 : Eq (alltrue (full n8)) T
ft23 = refl

mt23 : Eq (mirror (full n10)) (full n10)
mt23 = refl

ft24 : Eq (alltrue (full n7)) T
ft24 = refl

mt24 : Eq (mirror (full n8)) (full n8)
mt24 = refl

ft25 : Eq (alltrue (full n12)) T
ft25 = refl

mt25 : Eq (mirror (full n6)) (full n6)
mt25 = refl

ft26 : Eq (alltrue (full n11)) T
ft26 = refl

mt26 : Eq (mirror (full n9)) (full n9)
mt26 = refl

ft27 : Eq (alltrue (full n10)) T
ft27 = refl

mt27 : Eq (mirror (full n7)) (full n7)
mt27 = refl

ft28 : Eq (alltrue (full n9)) T
ft28 = refl

mt28 : Eq (mirror (full n10)) (full n10)
mt28 = refl

ft29 : Eq (alltrue (full n8)) T
ft29 = refl

mt29 : Eq (mirror (full n8)) (full n8)
mt29 = refl

ft30 : Eq (alltrue (full n7)) T
ft30 = refl

mt30 : Eq (mirror (full n6)) (full n6)
mt30 = refl

ft31 : Eq (alltrue (full n12)) T
ft31 = refl

mt31 : Eq (mirror (full n9)) (full n9)
mt31 = refl

ft32 : Eq (alltrue (full n11)) T
ft32 = refl

mt32 : Eq (mirror (full n7)) (full n7)
mt32 = refl

ft33 : Eq (alltrue (full n10)) T
ft33 = refl

mt33 : Eq (mirror (full n10)) (full n10)
mt33 = refl

ft34 : Eq (alltrue (full n9)) T
ft34 = refl

mt34 : Eq (mirror (full n8)) (full n8)
mt34 = refl

ft35 : Eq (alltrue (full n8)) T
ft35 = refl

mt35 : Eq (mirror (full n6)) (full n6)
mt35 = refl

ft36 : Eq (alltrue (full n7)) T
ft36 = refl

mt36 : Eq (mirror (full n9)) (full n9)
mt36 = refl

ft37 : Eq (alltrue (full n12)) T
ft37 = refl

mt37 : Eq (mirror (full n7)) (full n7)
mt37 = refl

ft38 : Eq (alltrue (full n11)) T
ft38 = refl

mt38 : Eq (mirror (full n10)) (full n10)
mt38 = refl

ft39 : Eq (alltrue (full n10)) T
ft39 = refl

mt39 : Eq (mirror (full n8)) (full n8)
mt39 = refl

ft40 : Eq (alltrue (full n9)) T
ft40 = refl

mt40 : Eq (mirror (full n6)) (full n6)
mt40 = refl

ft41 : Eq (alltrue (full n8)) T
ft41 = refl

mt41 : Eq (mirror (full n9)) (full n9)
mt41 = refl

ft42 : Eq (alltrue (full n7)) T
ft42 = refl

mt42 : Eq (mirror (full n7)) (full n7)
mt42 = refl

ft43 : Eq (alltrue (full n12)) T
ft43 = refl

mt43 : Eq (mirror (full n10)) (full n10)
mt43 = refl

ft44 : Eq (alltrue (full n11)) T
ft44 = refl

mt44 : Eq (mirror (full n8)) (full n8)
mt44 = refl

ft45 : Eq (alltrue (full n10)) T
ft45 = refl

mt45 : Eq (mirror (full n6)) (full n6)
mt45 = refl

ft46 : Eq (alltrue (full n9)) T
ft46 = refl

mt46 : Eq (mirror (full n9)) (full n9)
mt46 = refl

ft47 : Eq (alltrue (full n8)) T
ft47 = refl

mt47 : Eq (mirror (full n7)) (full n7)
mt47 = refl

ft48 : Eq (alltrue (full n7)) T
ft48 = refl

mt48 : Eq (mirror (full n10)) (full n10)
mt48 = refl

ft49 : Eq (alltrue (full n12)) T
ft49 = refl

mt49 : Eq (mirror (full n8)) (full n8)
mt49 = refl

ft50 : Eq (alltrue (full n11)) T
ft50 = refl

mt50 : Eq (mirror (full n6)) (full n6)
mt50 = refl

ft51 : Eq (alltrue (full n10)) T
ft51 = refl

mt51 : Eq (mirror (full n9)) (full n9)
mt51 = refl

ft52 : Eq (alltrue (full n9)) T
ft52 = refl

mt52 : Eq (mirror (full n7)) (full n7)
mt52 = refl

ft53 : Eq (alltrue (full n8)) T
ft53 = refl

mt53 : Eq (mirror (full n10)) (full n10)
mt53 = refl

ft54 : Eq (alltrue (full n7)) T
ft54 = refl

mt54 : Eq (mirror (full n8)) (full n8)
mt54 = refl

ft55 : Eq (alltrue (full n12)) T
ft55 = refl

mt55 : Eq (mirror (full n6)) (full n6)
mt55 = refl

ft56 : Eq (alltrue (full n11)) T
ft56 = refl

mt56 : Eq (mirror (full n9)) (full n9)
mt56 = refl

ft57 : Eq (alltrue (full n10)) T
ft57 = refl

mt57 : Eq (mirror (full n7)) (full n7)
mt57 = refl

ft58 : Eq (alltrue (full n9)) T
ft58 = refl

mt58 : Eq (mirror (full n10)) (full n10)
mt58 = refl

ft59 : Eq (alltrue (full n8)) T
ft59 = refl

mt59 : Eq (mirror (full n8)) (full n8)
mt59 = refl

ft60 : Eq (alltrue (full n7)) T
ft60 = refl

mt60 : Eq (mirror (full n6)) (full n6)
mt60 = refl

ft61 : Eq (alltrue (full n12)) T
ft61 = refl

mt61 : Eq (mirror (full n9)) (full n9)
mt61 = refl

ft62 : Eq (alltrue (full n11)) T
ft62 = refl

mt62 : Eq (mirror (full n7)) (full n7)
mt62 = refl

ft63 : Eq (alltrue (full n10)) T
ft63 = refl

mt63 : Eq (mirror (full n10)) (full n10)
mt63 = refl

ft64 : Eq (alltrue (full n9)) T
ft64 = refl

mt64 : Eq (mirror (full n8)) (full n8)
mt64 = refl

ft65 : Eq (alltrue (full n8)) T
ft65 = refl

mt65 : Eq (mirror (full n6)) (full n6)
mt65 = refl

ft66 : Eq (alltrue (full n7)) T
ft66 = refl

mt66 : Eq (mirror (full n9)) (full n9)
mt66 = refl

ft67 : Eq (alltrue (full n12)) T
ft67 = refl

mt67 : Eq (mirror (full n7)) (full n7)
mt67 = refl

ft68 : Eq (alltrue (full n11)) T
ft68 = refl

mt68 : Eq (mirror (full n10)) (full n10)
mt68 = refl

ft69 : Eq (alltrue (full n10)) T
ft69 = refl

mt69 : Eq (mirror (full n8)) (full n8)
mt69 = refl

ft70 : Eq (alltrue (full n9)) T
ft70 = refl

mt70 : Eq (mirror (full n6)) (full n6)
mt70 = refl

ft71 : Eq (alltrue (full n8)) T
ft71 = refl

mt71 : Eq (mirror (full n9)) (full n9)
mt71 = refl

ft72 : Eq (alltrue (full n7)) T
ft72 = refl

mt72 : Eq (mirror (full n7)) (full n7)
mt72 = refl

ft73 : Eq (alltrue (full n12)) T
ft73 = refl

mt73 : Eq (mirror (full n10)) (full n10)
mt73 = refl

ft74 : Eq (alltrue (full n11)) T
ft74 = refl

mt74 : Eq (mirror (full n8)) (full n8)
mt74 = refl

ft75 : Eq (alltrue (full n10)) T
ft75 = refl

mt75 : Eq (mirror (full n6)) (full n6)
mt75 = refl

ft76 : Eq (alltrue (full n9)) T
ft76 = refl

mt76 : Eq (mirror (full n9)) (full n9)
mt76 = refl

ft77 : Eq (alltrue (full n8)) T
ft77 = refl

mt77 : Eq (mirror (full n7)) (full n7)
mt77 = refl

ft78 : Eq (alltrue (full n7)) T
ft78 = refl

mt78 : Eq (mirror (full n10)) (full n10)
mt78 = refl

ft79 : Eq (alltrue (full n12)) T
ft79 = refl

mt79 : Eq (mirror (full n8)) (full n8)
mt79 = refl

ft80 : Eq (alltrue (full n11)) T
ft80 = refl

mt80 : Eq (mirror (full n6)) (full n6)
mt80 = refl

ft81 : Eq (alltrue (full n10)) T
ft81 = refl

mt81 : Eq (mirror (full n9)) (full n9)
mt81 = refl

ft82 : Eq (alltrue (full n9)) T
ft82 = refl

mt82 : Eq (mirror (full n7)) (full n7)
mt82 = refl

ft83 : Eq (alltrue (full n8)) T
ft83 = refl

mt83 : Eq (mirror (full n10)) (full n10)
mt83 = refl

ft84 : Eq (alltrue (full n7)) T
ft84 = refl

mt84 : Eq (mirror (full n8)) (full n8)
mt84 = refl

ft85 : Eq (alltrue (full n12)) T
ft85 = refl

mt85 : Eq (mirror (full n6)) (full n6)
mt85 = refl

ft86 : Eq (alltrue (full n11)) T
ft86 = refl

mt86 : Eq (mirror (full n9)) (full n9)
mt86 = refl

ft87 : Eq (alltrue (full n10)) T
ft87 = refl

mt87 : Eq (mirror (full n7)) (full n7)
mt87 = refl

ft88 : Eq (alltrue (full n9)) T
ft88 = refl

mt88 : Eq (mirror (full n10)) (full n10)
mt88 = refl

ft89 : Eq (alltrue (full n8)) T
ft89 = refl

mt89 : Eq (mirror (full n8)) (full n8)
mt89 = refl

ft90 : Eq (alltrue (full n7)) T
ft90 = refl

mt90 : Eq (mirror (full n6)) (full n6)
mt90 = refl

ft91 : Eq (alltrue (full n12)) T
ft91 = refl

mt91 : Eq (mirror (full n9)) (full n9)
mt91 = refl

ft92 : Eq (alltrue (full n11)) T
ft92 = refl

mt92 : Eq (mirror (full n7)) (full n7)
mt92 = refl

ft93 : Eq (alltrue (full n10)) T
ft93 = refl

mt93 : Eq (mirror (full n10)) (full n10)
mt93 = refl

ft94 : Eq (alltrue (full n9)) T
ft94 = refl

mt94 : Eq (mirror (full n8)) (full n8)
mt94 = refl

ft95 : Eq (alltrue (full n8)) T
ft95 = refl

mt95 : Eq (mirror (full n6)) (full n6)
mt95 = refl

ft96 : Eq (alltrue (full n7)) T
ft96 = refl

mt96 : Eq (mirror (full n9)) (full n9)
mt96 = refl

ft97 : Eq (alltrue (full n12)) T
ft97 = refl

mt97 : Eq (mirror (full n7)) (full n7)
mt97 = refl

ft98 : Eq (alltrue (full n11)) T
ft98 = refl

mt98 : Eq (mirror (full n10)) (full n10)
mt98 = refl

ft99 : Eq (alltrue (full n10)) T
ft99 = refl

mt99 : Eq (mirror (full n8)) (full n8)
mt99 = refl

ft100 : Eq (alltrue (full n9)) T
ft100 = refl

mt100 : Eq (mirror (full n6)) (full n6)
mt100 = refl

ft101 : Eq (alltrue (full n8)) T
ft101 = refl

mt101 : Eq (mirror (full n9)) (full n9)
mt101 = refl

ft102 : Eq (alltrue (full n7)) T
ft102 = refl

mt102 : Eq (mirror (full n7)) (full n7)
mt102 = refl

ft103 : Eq (alltrue (full n12)) T
ft103 = refl

mt103 : Eq (mirror (full n10)) (full n10)
mt103 = refl

ft104 : Eq (alltrue (full n11)) T
ft104 = refl

mt104 : Eq (mirror (full n8)) (full n8)
mt104 = refl

ft105 : Eq (alltrue (full n10)) T
ft105 = refl

mt105 : Eq (mirror (full n6)) (full n6)
mt105 = refl

ft106 : Eq (alltrue (full n9)) T
ft106 = refl

mt106 : Eq (mirror (full n9)) (full n9)
mt106 = refl

ft107 : Eq (alltrue (full n8)) T
ft107 = refl

mt107 : Eq (mirror (full n7)) (full n7)
mt107 = refl

ft108 : Eq (alltrue (full n7)) T
ft108 = refl

mt108 : Eq (mirror (full n10)) (full n10)
mt108 = refl

ft109 : Eq (alltrue (full n12)) T
ft109 = refl

mt109 : Eq (mirror (full n8)) (full n8)
mt109 = refl

ft110 : Eq (alltrue (full n11)) T
ft110 = refl

mt110 : Eq (mirror (full n6)) (full n6)
mt110 = refl

ft111 : Eq (alltrue (full n10)) T
ft111 = refl

mt111 : Eq (mirror (full n9)) (full n9)
mt111 = refl

ft112 : Eq (alltrue (full n9)) T
ft112 = refl

mt112 : Eq (mirror (full n7)) (full n7)
mt112 = refl

ft113 : Eq (alltrue (full n8)) T
ft113 = refl

mt113 : Eq (mirror (full n10)) (full n10)
mt113 = refl

ft114 : Eq (alltrue (full n7)) T
ft114 = refl

mt114 : Eq (mirror (full n8)) (full n8)
mt114 = refl

ft115 : Eq (alltrue (full n12)) T
ft115 = refl

mt115 : Eq (mirror (full n6)) (full n6)
mt115 = refl

ft116 : Eq (alltrue (full n11)) T
ft116 = refl

mt116 : Eq (mirror (full n9)) (full n9)
mt116 = refl

ft117 : Eq (alltrue (full n10)) T
ft117 = refl

mt117 : Eq (mirror (full n7)) (full n7)
mt117 = refl

ft118 : Eq (alltrue (full n9)) T
ft118 = refl

mt118 : Eq (mirror (full n10)) (full n10)
mt118 = refl

ft119 : Eq (alltrue (full n8)) T
ft119 = refl

mt119 : Eq (mirror (full n8)) (full n8)
mt119 = refl

ft120 : Eq (alltrue (full n7)) T
ft120 = refl

mt120 : Eq (mirror (full n6)) (full n6)
mt120 = refl

ft121 : Eq (alltrue (full n12)) T
ft121 = refl

mt121 : Eq (mirror (full n9)) (full n9)
mt121 = refl

ft122 : Eq (alltrue (full n11)) T
ft122 = refl

mt122 : Eq (mirror (full n7)) (full n7)
mt122 = refl

ft123 : Eq (alltrue (full n10)) T
ft123 = refl

mt123 : Eq (mirror (full n10)) (full n10)
mt123 = refl

ft124 : Eq (alltrue (full n9)) T
ft124 = refl

mt124 : Eq (mirror (full n8)) (full n8)
mt124 = refl

ft125 : Eq (alltrue (full n8)) T
ft125 = refl

mt125 : Eq (mirror (full n6)) (full n6)
mt125 = refl

ft126 : Eq (alltrue (full n7)) T
ft126 = refl

mt126 : Eq (mirror (full n9)) (full n9)
mt126 = refl

ft127 : Eq (alltrue (full n12)) T
ft127 = refl

mt127 : Eq (mirror (full n7)) (full n7)
mt127 = refl

ft128 : Eq (alltrue (full n11)) T
ft128 = refl

mt128 : Eq (mirror (full n10)) (full n10)
mt128 = refl

ft129 : Eq (alltrue (full n10)) T
ft129 = refl

mt129 : Eq (mirror (full n8)) (full n8)
mt129 = refl

ft130 : Eq (alltrue (full n9)) T
ft130 = refl

mt130 : Eq (mirror (full n6)) (full n6)
mt130 = refl

ft131 : Eq (alltrue (full n8)) T
ft131 = refl

mt131 : Eq (mirror (full n9)) (full n9)
mt131 = refl

ft132 : Eq (alltrue (full n7)) T
ft132 = refl

mt132 : Eq (mirror (full n7)) (full n7)
mt132 = refl

ft133 : Eq (alltrue (full n12)) T
ft133 = refl

mt133 : Eq (mirror (full n10)) (full n10)
mt133 = refl

ft134 : Eq (alltrue (full n11)) T
ft134 = refl

mt134 : Eq (mirror (full n8)) (full n8)
mt134 = refl

ft135 : Eq (alltrue (full n10)) T
ft135 = refl

mt135 : Eq (mirror (full n6)) (full n6)
mt135 = refl

ft136 : Eq (alltrue (full n9)) T
ft136 = refl

mt136 : Eq (mirror (full n9)) (full n9)
mt136 = refl

ft137 : Eq (alltrue (full n8)) T
ft137 = refl

mt137 : Eq (mirror (full n7)) (full n7)
mt137 = refl

ft138 : Eq (alltrue (full n7)) T
ft138 = refl

mt138 : Eq (mirror (full n10)) (full n10)
mt138 = refl

ft139 : Eq (alltrue (full n12)) T
ft139 = refl

mt139 : Eq (mirror (full n8)) (full n8)
mt139 = refl

ft140 : Eq (alltrue (full n11)) T
ft140 = refl

mt140 : Eq (mirror (full n6)) (full n6)
mt140 = refl

ft141 : Eq (alltrue (full n10)) T
ft141 = refl

mt141 : Eq (mirror (full n9)) (full n9)
mt141 = refl

ft142 : Eq (alltrue (full n9)) T
ft142 = refl

mt142 : Eq (mirror (full n7)) (full n7)
mt142 = refl

ft143 : Eq (alltrue (full n8)) T
ft143 = refl

mt143 : Eq (mirror (full n10)) (full n10)
mt143 = refl

ft144 : Eq (alltrue (full n7)) T
ft144 = refl

mt144 : Eq (mirror (full n8)) (full n8)
mt144 = refl

ft145 : Eq (alltrue (full n12)) T
ft145 = refl

mt145 : Eq (mirror (full n6)) (full n6)
mt145 = refl

ft146 : Eq (alltrue (full n11)) T
ft146 = refl

mt146 : Eq (mirror (full n9)) (full n9)
mt146 = refl

ft147 : Eq (alltrue (full n10)) T
ft147 = refl

mt147 : Eq (mirror (full n7)) (full n7)
mt147 = refl

ft148 : Eq (alltrue (full n9)) T
ft148 = refl

mt148 : Eq (mirror (full n10)) (full n10)
mt148 = refl

ft149 : Eq (alltrue (full n8)) T
ft149 = refl

mt149 : Eq (mirror (full n8)) (full n8)
mt149 = refl

ft150 : Eq (alltrue (full n7)) T
ft150 = refl

mt150 : Eq (mirror (full n6)) (full n6)
mt150 = refl

ft151 : Eq (alltrue (full n12)) T
ft151 = refl

mt151 : Eq (mirror (full n9)) (full n9)
mt151 = refl

ft152 : Eq (alltrue (full n11)) T
ft152 = refl

mt152 : Eq (mirror (full n7)) (full n7)
mt152 = refl

ft153 : Eq (alltrue (full n10)) T
ft153 = refl

mt153 : Eq (mirror (full n10)) (full n10)
mt153 = refl

ft154 : Eq (alltrue (full n9)) T
ft154 = refl

mt154 : Eq (mirror (full n8)) (full n8)
mt154 = refl

ft155 : Eq (alltrue (full n8)) T
ft155 = refl

mt155 : Eq (mirror (full n6)) (full n6)
mt155 = refl

ft156 : Eq (alltrue (full n7)) T
ft156 = refl

mt156 : Eq (mirror (full n9)) (full n9)
mt156 = refl

ft157 : Eq (alltrue (full n12)) T
ft157 = refl

mt157 : Eq (mirror (full n7)) (full n7)
mt157 = refl

ft158 : Eq (alltrue (full n11)) T
ft158 = refl

mt158 : Eq (mirror (full n10)) (full n10)
mt158 = refl

ft159 : Eq (alltrue (full n10)) T
ft159 = refl

mt159 : Eq (mirror (full n8)) (full n8)
mt159 = refl

ft160 : Eq (alltrue (full n9)) T
ft160 = refl

mt160 : Eq (mirror (full n6)) (full n6)
mt160 = refl

ft161 : Eq (alltrue (full n8)) T
ft161 = refl

mt161 : Eq (mirror (full n9)) (full n9)
mt161 = refl

ft162 : Eq (alltrue (full n7)) T
ft162 = refl

mt162 : Eq (mirror (full n7)) (full n7)
mt162 = refl

ft163 : Eq (alltrue (full n12)) T
ft163 = refl

mt163 : Eq (mirror (full n10)) (full n10)
mt163 = refl

ft164 : Eq (alltrue (full n11)) T
ft164 = refl

mt164 : Eq (mirror (full n8)) (full n8)
mt164 = refl

ft165 : Eq (alltrue (full n10)) T
ft165 = refl

mt165 : Eq (mirror (full n6)) (full n6)
mt165 = refl

ft166 : Eq (alltrue (full n9)) T
ft166 = refl

mt166 : Eq (mirror (full n9)) (full n9)
mt166 = refl

ft167 : Eq (alltrue (full n8)) T
ft167 = refl

mt167 : Eq (mirror (full n7)) (full n7)
mt167 = refl

ft168 : Eq (alltrue (full n7)) T
ft168 = refl

mt168 : Eq (mirror (full n10)) (full n10)
mt168 = refl

ft169 : Eq (alltrue (full n12)) T
ft169 = refl

mt169 : Eq (mirror (full n8)) (full n8)
mt169 = refl

ft170 : Eq (alltrue (full n11)) T
ft170 = refl

mt170 : Eq (mirror (full n6)) (full n6)
mt170 = refl

ft171 : Eq (alltrue (full n10)) T
ft171 = refl

mt171 : Eq (mirror (full n9)) (full n9)
mt171 = refl

ft172 : Eq (alltrue (full n9)) T
ft172 = refl

mt172 : Eq (mirror (full n7)) (full n7)
mt172 = refl

ft173 : Eq (alltrue (full n8)) T
ft173 = refl

mt173 : Eq (mirror (full n10)) (full n10)
mt173 = refl

ft174 : Eq (alltrue (full n7)) T
ft174 = refl

mt174 : Eq (mirror (full n8)) (full n8)
mt174 = refl

ft175 : Eq (alltrue (full n12)) T
ft175 = refl

mt175 : Eq (mirror (full n6)) (full n6)
mt175 = refl

ft176 : Eq (alltrue (full n11)) T
ft176 = refl

mt176 : Eq (mirror (full n9)) (full n9)
mt176 = refl

ft177 : Eq (alltrue (full n10)) T
ft177 = refl

mt177 : Eq (mirror (full n7)) (full n7)
mt177 = refl

ft178 : Eq (alltrue (full n9)) T
ft178 = refl

mt178 : Eq (mirror (full n10)) (full n10)
mt178 = refl

ft179 : Eq (alltrue (full n8)) T
ft179 = refl

mt179 : Eq (mirror (full n8)) (full n8)
mt179 = refl

ft180 : Eq (alltrue (full n7)) T
ft180 = refl

mt180 : Eq (mirror (full n6)) (full n6)
mt180 = refl

ft181 : Eq (alltrue (full n12)) T
ft181 = refl

mt181 : Eq (mirror (full n9)) (full n9)
mt181 = refl

ft182 : Eq (alltrue (full n11)) T
ft182 = refl

mt182 : Eq (mirror (full n7)) (full n7)
mt182 = refl

ft183 : Eq (alltrue (full n10)) T
ft183 = refl

mt183 : Eq (mirror (full n10)) (full n10)
mt183 = refl

ft184 : Eq (alltrue (full n9)) T
ft184 = refl

mt184 : Eq (mirror (full n8)) (full n8)
mt184 = refl

ft185 : Eq (alltrue (full n8)) T
ft185 = refl

mt185 : Eq (mirror (full n6)) (full n6)
mt185 = refl

ft186 : Eq (alltrue (full n7)) T
ft186 = refl

mt186 : Eq (mirror (full n9)) (full n9)
mt186 = refl

ft187 : Eq (alltrue (full n12)) T
ft187 = refl

mt187 : Eq (mirror (full n7)) (full n7)
mt187 = refl

ft188 : Eq (alltrue (full n11)) T
ft188 = refl

mt188 : Eq (mirror (full n10)) (full n10)
mt188 = refl

ft189 : Eq (alltrue (full n10)) T
ft189 = refl

mt189 : Eq (mirror (full n8)) (full n8)
mt189 = refl

ft190 : Eq (alltrue (full n9)) T
ft190 = refl

mt190 : Eq (mirror (full n6)) (full n6)
mt190 = refl

ft191 : Eq (alltrue (full n8)) T
ft191 = refl

mt191 : Eq (mirror (full n9)) (full n9)
mt191 = refl

ft192 : Eq (alltrue (full n7)) T
ft192 = refl

mt192 : Eq (mirror (full n7)) (full n7)
mt192 = refl

ft193 : Eq (alltrue (full n12)) T
ft193 = refl

mt193 : Eq (mirror (full n10)) (full n10)
mt193 = refl

ft194 : Eq (alltrue (full n11)) T
ft194 = refl

mt194 : Eq (mirror (full n8)) (full n8)
mt194 = refl

ft195 : Eq (alltrue (full n10)) T
ft195 = refl

mt195 : Eq (mirror (full n6)) (full n6)
mt195 = refl

ft196 : Eq (alltrue (full n9)) T
ft196 = refl

mt196 : Eq (mirror (full n9)) (full n9)
mt196 = refl

ft197 : Eq (alltrue (full n8)) T
ft197 = refl

mt197 : Eq (mirror (full n7)) (full n7)
mt197 = refl

ft198 : Eq (alltrue (full n7)) T
ft198 = refl

mt198 : Eq (mirror (full n10)) (full n10)
mt198 = refl

ft199 : Eq (alltrue (full n12)) T
ft199 = refl

mt199 : Eq (mirror (full n8)) (full n8)
mt199 = refl

ft200 : Eq (alltrue (full n11)) T
ft200 = refl

mt200 : Eq (mirror (full n6)) (full n6)
mt200 = refl

ft201 : Eq (alltrue (full n10)) T
ft201 = refl

mt201 : Eq (mirror (full n9)) (full n9)
mt201 = refl

ft202 : Eq (alltrue (full n9)) T
ft202 = refl

mt202 : Eq (mirror (full n7)) (full n7)
mt202 = refl

ft203 : Eq (alltrue (full n8)) T
ft203 = refl

mt203 : Eq (mirror (full n10)) (full n10)
mt203 = refl

ft204 : Eq (alltrue (full n7)) T
ft204 = refl

mt204 : Eq (mirror (full n8)) (full n8)
mt204 = refl

ft205 : Eq (alltrue (full n12)) T
ft205 = refl

mt205 : Eq (mirror (full n6)) (full n6)
mt205 = refl

ft206 : Eq (alltrue (full n11)) T
ft206 = refl

mt206 : Eq (mirror (full n9)) (full n9)
mt206 = refl

ft207 : Eq (alltrue (full n10)) T
ft207 = refl

mt207 : Eq (mirror (full n7)) (full n7)
mt207 = refl

ft208 : Eq (alltrue (full n9)) T
ft208 = refl

mt208 : Eq (mirror (full n10)) (full n10)
mt208 = refl

ft209 : Eq (alltrue (full n8)) T
ft209 = refl

mt209 : Eq (mirror (full n8)) (full n8)
mt209 = refl

ft210 : Eq (alltrue (full n7)) T
ft210 = refl

mt210 : Eq (mirror (full n6)) (full n6)
mt210 = refl

ft211 : Eq (alltrue (full n12)) T
ft211 = refl

mt211 : Eq (mirror (full n9)) (full n9)
mt211 = refl

ft212 : Eq (alltrue (full n11)) T
ft212 = refl

mt212 : Eq (mirror (full n7)) (full n7)
mt212 = refl

ft213 : Eq (alltrue (full n10)) T
ft213 = refl

mt213 : Eq (mirror (full n10)) (full n10)
mt213 = refl

ft214 : Eq (alltrue (full n9)) T
ft214 = refl

mt214 : Eq (mirror (full n8)) (full n8)
mt214 = refl

ft215 : Eq (alltrue (full n8)) T
ft215 = refl

mt215 : Eq (mirror (full n6)) (full n6)
mt215 = refl

ft216 : Eq (alltrue (full n7)) T
ft216 = refl

mt216 : Eq (mirror (full n9)) (full n9)
mt216 = refl

ft217 : Eq (alltrue (full n12)) T
ft217 = refl

mt217 : Eq (mirror (full n7)) (full n7)
mt217 = refl

ft218 : Eq (alltrue (full n11)) T
ft218 = refl

mt218 : Eq (mirror (full n10)) (full n10)
mt218 = refl

ft219 : Eq (alltrue (full n10)) T
ft219 = refl

mt219 : Eq (mirror (full n8)) (full n8)
mt219 = refl

ft220 : Eq (alltrue (full n9)) T
ft220 = refl

mt220 : Eq (mirror (full n6)) (full n6)
mt220 = refl

ft221 : Eq (alltrue (full n8)) T
ft221 = refl

mt221 : Eq (mirror (full n9)) (full n9)
mt221 = refl

ft222 : Eq (alltrue (full n7)) T
ft222 = refl

mt222 : Eq (mirror (full n7)) (full n7)
mt222 = refl

ft223 : Eq (alltrue (full n12)) T
ft223 = refl

mt223 : Eq (mirror (full n10)) (full n10)
mt223 = refl

ft224 : Eq (alltrue (full n11)) T
ft224 = refl

mt224 : Eq (mirror (full n8)) (full n8)
mt224 = refl

ft225 : Eq (alltrue (full n10)) T
ft225 = refl

mt225 : Eq (mirror (full n6)) (full n6)
mt225 = refl

ft226 : Eq (alltrue (full n9)) T
ft226 = refl

mt226 : Eq (mirror (full n9)) (full n9)
mt226 = refl

ft227 : Eq (alltrue (full n8)) T
ft227 = refl

mt227 : Eq (mirror (full n7)) (full n7)
mt227 = refl

ft228 : Eq (alltrue (full n7)) T
ft228 = refl

mt228 : Eq (mirror (full n10)) (full n10)
mt228 = refl

ft229 : Eq (alltrue (full n12)) T
ft229 = refl

mt229 : Eq (mirror (full n8)) (full n8)
mt229 = refl

ft230 : Eq (alltrue (full n11)) T
ft230 = refl

mt230 : Eq (mirror (full n6)) (full n6)
mt230 = refl

ft231 : Eq (alltrue (full n10)) T
ft231 = refl

mt231 : Eq (mirror (full n9)) (full n9)
mt231 = refl

ft232 : Eq (alltrue (full n9)) T
ft232 = refl

mt232 : Eq (mirror (full n7)) (full n7)
mt232 = refl

ft233 : Eq (alltrue (full n8)) T
ft233 = refl

mt233 : Eq (mirror (full n10)) (full n10)
mt233 = refl

ft234 : Eq (alltrue (full n7)) T
ft234 = refl

mt234 : Eq (mirror (full n8)) (full n8)
mt234 = refl

ft235 : Eq (alltrue (full n12)) T
ft235 = refl

mt235 : Eq (mirror (full n6)) (full n6)
mt235 = refl

ft236 : Eq (alltrue (full n11)) T
ft236 = refl

mt236 : Eq (mirror (full n9)) (full n9)
mt236 = refl

ft237 : Eq (alltrue (full n10)) T
ft237 = refl

mt237 : Eq (mirror (full n7)) (full n7)
mt237 = refl

ft238 : Eq (alltrue (full n9)) T
ft238 = refl

mt238 : Eq (mirror (full n10)) (full n10)
mt238 = refl

ft239 : Eq (alltrue (full n8)) T
ft239 = refl

mt239 : Eq (mirror (full n8)) (full n8)
mt239 = refl

ft240 : Eq (alltrue (full n7)) T
ft240 = refl

mt240 : Eq (mirror (full n6)) (full n6)
mt240 = refl

ft241 : Eq (alltrue (full n12)) T
ft241 = refl

mt241 : Eq (mirror (full n9)) (full n9)
mt241 = refl

ft242 : Eq (alltrue (full n11)) T
ft242 = refl

mt242 : Eq (mirror (full n7)) (full n7)
mt242 = refl

ft243 : Eq (alltrue (full n10)) T
ft243 = refl

mt243 : Eq (mirror (full n10)) (full n10)
mt243 = refl

ft244 : Eq (alltrue (full n9)) T
ft244 = refl

mt244 : Eq (mirror (full n8)) (full n8)
mt244 = refl

ft245 : Eq (alltrue (full n8)) T
ft245 = refl

mt245 : Eq (mirror (full n6)) (full n6)
mt245 = refl

ft246 : Eq (alltrue (full n7)) T
ft246 = refl

mt246 : Eq (mirror (full n9)) (full n9)
mt246 = refl

ft247 : Eq (alltrue (full n12)) T
ft247 = refl

mt247 : Eq (mirror (full n7)) (full n7)
mt247 = refl

ft248 : Eq (alltrue (full n11)) T
ft248 = refl

mt248 : Eq (mirror (full n10)) (full n10)
mt248 = refl

ft249 : Eq (alltrue (full n10)) T
ft249 = refl

mt249 : Eq (mirror (full n8)) (full n8)
mt249 = refl

ft250 : Eq (alltrue (full n9)) T
ft250 = refl

mt250 : Eq (mirror (full n6)) (full n6)
mt250 = refl

ft251 : Eq (alltrue (full n8)) T
ft251 = refl

mt251 : Eq (mirror (full n9)) (full n9)
mt251 = refl

ft252 : Eq (alltrue (full n7)) T
ft252 = refl

mt252 : Eq (mirror (full n7)) (full n7)
mt252 = refl

ft253 : Eq (alltrue (full n12)) T
ft253 = refl

mt253 : Eq (mirror (full n10)) (full n10)
mt253 = refl

ft254 : Eq (alltrue (full n11)) T
ft254 = refl

mt254 : Eq (mirror (full n8)) (full n8)
mt254 = refl

ft255 : Eq (alltrue (full n10)) T
ft255 = refl

mt255 : Eq (mirror (full n6)) (full n6)
mt255 = refl

ft256 : Eq (alltrue (full n9)) T
ft256 = refl

mt256 : Eq (mirror (full n9)) (full n9)
mt256 = refl

ft257 : Eq (alltrue (full n8)) T
ft257 = refl

mt257 : Eq (mirror (full n7)) (full n7)
mt257 = refl

ft258 : Eq (alltrue (full n7)) T
ft258 = refl

mt258 : Eq (mirror (full n10)) (full n10)
mt258 = refl

ft259 : Eq (alltrue (full n12)) T
ft259 = refl

mt259 : Eq (mirror (full n8)) (full n8)
mt259 = refl

ft260 : Eq (alltrue (full n11)) T
ft260 = refl

mt260 : Eq (mirror (full n6)) (full n6)
mt260 = refl

ft261 : Eq (alltrue (full n10)) T
ft261 = refl

mt261 : Eq (mirror (full n9)) (full n9)
mt261 = refl

ft262 : Eq (alltrue (full n9)) T
ft262 = refl

mt262 : Eq (mirror (full n7)) (full n7)
mt262 = refl

ft263 : Eq (alltrue (full n8)) T
ft263 = refl

mt263 : Eq (mirror (full n10)) (full n10)
mt263 = refl

ft264 : Eq (alltrue (full n7)) T
ft264 = refl

mt264 : Eq (mirror (full n8)) (full n8)
mt264 = refl

ft265 : Eq (alltrue (full n12)) T
ft265 = refl

mt265 : Eq (mirror (full n6)) (full n6)
mt265 = refl

ft266 : Eq (alltrue (full n11)) T
ft266 = refl

mt266 : Eq (mirror (full n9)) (full n9)
mt266 = refl

ft267 : Eq (alltrue (full n10)) T
ft267 = refl

mt267 : Eq (mirror (full n7)) (full n7)
mt267 = refl

ft268 : Eq (alltrue (full n9)) T
ft268 = refl

mt268 : Eq (mirror (full n10)) (full n10)
mt268 = refl

ft269 : Eq (alltrue (full n8)) T
ft269 = refl

mt269 : Eq (mirror (full n8)) (full n8)
mt269 = refl

ft270 : Eq (alltrue (full n7)) T
ft270 = refl

mt270 : Eq (mirror (full n6)) (full n6)
mt270 = refl

ft271 : Eq (alltrue (full n12)) T
ft271 = refl

mt271 : Eq (mirror (full n9)) (full n9)
mt271 = refl

ft272 : Eq (alltrue (full n11)) T
ft272 = refl

mt272 : Eq (mirror (full n7)) (full n7)
mt272 = refl

ft273 : Eq (alltrue (full n10)) T
ft273 = refl

mt273 : Eq (mirror (full n10)) (full n10)
mt273 = refl

ft274 : Eq (alltrue (full n9)) T
ft274 = refl

mt274 : Eq (mirror (full n8)) (full n8)
mt274 = refl

ft275 : Eq (alltrue (full n8)) T
ft275 = refl

mt275 : Eq (mirror (full n6)) (full n6)
mt275 = refl

ft276 : Eq (alltrue (full n7)) T
ft276 = refl

mt276 : Eq (mirror (full n9)) (full n9)
mt276 = refl

ft277 : Eq (alltrue (full n12)) T
ft277 = refl

mt277 : Eq (mirror (full n7)) (full n7)
mt277 = refl

ft278 : Eq (alltrue (full n11)) T
ft278 = refl

mt278 : Eq (mirror (full n10)) (full n10)
mt278 = refl

ft279 : Eq (alltrue (full n10)) T
ft279 = refl

mt279 : Eq (mirror (full n8)) (full n8)
mt279 = refl

ft280 : Eq (alltrue (full n9)) T
ft280 = refl

mt280 : Eq (mirror (full n6)) (full n6)
mt280 = refl

ft281 : Eq (alltrue (full n8)) T
ft281 = refl

mt281 : Eq (mirror (full n9)) (full n9)
mt281 = refl

ft282 : Eq (alltrue (full n7)) T
ft282 = refl

mt282 : Eq (mirror (full n7)) (full n7)
mt282 = refl

ft283 : Eq (alltrue (full n12)) T
ft283 = refl

mt283 : Eq (mirror (full n10)) (full n10)
mt283 = refl

ft284 : Eq (alltrue (full n11)) T
ft284 = refl

mt284 : Eq (mirror (full n8)) (full n8)
mt284 = refl

ft285 : Eq (alltrue (full n10)) T
ft285 = refl

mt285 : Eq (mirror (full n6)) (full n6)
mt285 = refl

ft286 : Eq (alltrue (full n9)) T
ft286 = refl

mt286 : Eq (mirror (full n9)) (full n9)
mt286 = refl

ft287 : Eq (alltrue (full n8)) T
ft287 = refl

mt287 : Eq (mirror (full n7)) (full n7)
mt287 = refl

ft288 : Eq (alltrue (full n7)) T
ft288 = refl

mt288 : Eq (mirror (full n10)) (full n10)
mt288 = refl

ft289 : Eq (alltrue (full n12)) T
ft289 = refl

mt289 : Eq (mirror (full n8)) (full n8)
mt289 = refl

ft290 : Eq (alltrue (full n11)) T
ft290 = refl

mt290 : Eq (mirror (full n6)) (full n6)
mt290 = refl

ft291 : Eq (alltrue (full n10)) T
ft291 = refl

mt291 : Eq (mirror (full n9)) (full n9)
mt291 = refl

ft292 : Eq (alltrue (full n9)) T
ft292 = refl

mt292 : Eq (mirror (full n7)) (full n7)
mt292 = refl

ft293 : Eq (alltrue (full n8)) T
ft293 = refl

mt293 : Eq (mirror (full n10)) (full n10)
mt293 = refl

ft294 : Eq (alltrue (full n7)) T
ft294 = refl

mt294 : Eq (mirror (full n8)) (full n8)
mt294 = refl

ft295 : Eq (alltrue (full n12)) T
ft295 = refl

mt295 : Eq (mirror (full n6)) (full n6)
mt295 = refl

ft296 : Eq (alltrue (full n11)) T
ft296 = refl

mt296 : Eq (mirror (full n9)) (full n9)
mt296 = refl

ft297 : Eq (alltrue (full n10)) T
ft297 = refl

mt297 : Eq (mirror (full n7)) (full n7)
mt297 = refl

ft298 : Eq (alltrue (full n9)) T
ft298 = refl

mt298 : Eq (mirror (full n10)) (full n10)
mt298 = refl

ft299 : Eq (alltrue (full n8)) T
ft299 = refl

mt299 : Eq (mirror (full n8)) (full n8)
mt299 = refl

ft300 : Eq (alltrue (full n7)) T
ft300 = refl

mt300 : Eq (mirror (full n6)) (full n6)
mt300 = refl

ft301 : Eq (alltrue (full n12)) T
ft301 = refl

mt301 : Eq (mirror (full n9)) (full n9)
mt301 = refl

ft302 : Eq (alltrue (full n11)) T
ft302 = refl

mt302 : Eq (mirror (full n7)) (full n7)
mt302 = refl

ft303 : Eq (alltrue (full n10)) T
ft303 = refl

mt303 : Eq (mirror (full n10)) (full n10)
mt303 = refl

ft304 : Eq (alltrue (full n9)) T
ft304 = refl

mt304 : Eq (mirror (full n8)) (full n8)
mt304 = refl

ft305 : Eq (alltrue (full n8)) T
ft305 = refl

mt305 : Eq (mirror (full n6)) (full n6)
mt305 = refl

ft306 : Eq (alltrue (full n7)) T
ft306 = refl

mt306 : Eq (mirror (full n9)) (full n9)
mt306 = refl

ft307 : Eq (alltrue (full n12)) T
ft307 = refl

mt307 : Eq (mirror (full n7)) (full n7)
mt307 = refl

ft308 : Eq (alltrue (full n11)) T
ft308 = refl

mt308 : Eq (mirror (full n10)) (full n10)
mt308 = refl

ft309 : Eq (alltrue (full n10)) T
ft309 = refl

mt309 : Eq (mirror (full n8)) (full n8)
mt309 = refl

ft310 : Eq (alltrue (full n9)) T
ft310 = refl

mt310 : Eq (mirror (full n6)) (full n6)
mt310 = refl

ft311 : Eq (alltrue (full n8)) T
ft311 = refl

mt311 : Eq (mirror (full n9)) (full n9)
mt311 = refl

ft312 : Eq (alltrue (full n7)) T
ft312 = refl

mt312 : Eq (mirror (full n7)) (full n7)
mt312 = refl

ft313 : Eq (alltrue (full n12)) T
ft313 = refl

mt313 : Eq (mirror (full n10)) (full n10)
mt313 = refl

ft314 : Eq (alltrue (full n11)) T
ft314 = refl

mt314 : Eq (mirror (full n8)) (full n8)
mt314 = refl

ft315 : Eq (alltrue (full n10)) T
ft315 = refl

mt315 : Eq (mirror (full n6)) (full n6)
mt315 = refl

ft316 : Eq (alltrue (full n9)) T
ft316 = refl

mt316 : Eq (mirror (full n9)) (full n9)
mt316 = refl

ft317 : Eq (alltrue (full n8)) T
ft317 = refl

mt317 : Eq (mirror (full n7)) (full n7)
mt317 = refl

ft318 : Eq (alltrue (full n7)) T
ft318 = refl

mt318 : Eq (mirror (full n10)) (full n10)
mt318 = refl

ft319 : Eq (alltrue (full n12)) T
ft319 = refl

mt319 : Eq (mirror (full n8)) (full n8)
mt319 = refl

ft320 : Eq (alltrue (full n11)) T
ft320 = refl

mt320 : Eq (mirror (full n6)) (full n6)
mt320 = refl

ft321 : Eq (alltrue (full n10)) T
ft321 = refl

mt321 : Eq (mirror (full n9)) (full n9)
mt321 = refl

ft322 : Eq (alltrue (full n9)) T
ft322 = refl

mt322 : Eq (mirror (full n7)) (full n7)
mt322 = refl

ft323 : Eq (alltrue (full n8)) T
ft323 = refl

mt323 : Eq (mirror (full n10)) (full n10)
mt323 = refl

ft324 : Eq (alltrue (full n7)) T
ft324 = refl

mt324 : Eq (mirror (full n8)) (full n8)
mt324 = refl

ft325 : Eq (alltrue (full n12)) T
ft325 = refl

mt325 : Eq (mirror (full n6)) (full n6)
mt325 = refl

ft326 : Eq (alltrue (full n11)) T
ft326 = refl

mt326 : Eq (mirror (full n9)) (full n9)
mt326 = refl

ft327 : Eq (alltrue (full n10)) T
ft327 = refl

mt327 : Eq (mirror (full n7)) (full n7)
mt327 = refl

ft328 : Eq (alltrue (full n9)) T
ft328 = refl

mt328 : Eq (mirror (full n10)) (full n10)
mt328 = refl

ft329 : Eq (alltrue (full n8)) T
ft329 = refl

mt329 : Eq (mirror (full n8)) (full n8)
mt329 = refl

ft330 : Eq (alltrue (full n7)) T
ft330 = refl

mt330 : Eq (mirror (full n6)) (full n6)
mt330 = refl

ft331 : Eq (alltrue (full n12)) T
ft331 = refl

mt331 : Eq (mirror (full n9)) (full n9)
mt331 = refl

ft332 : Eq (alltrue (full n11)) T
ft332 = refl

mt332 : Eq (mirror (full n7)) (full n7)
mt332 = refl

ft333 : Eq (alltrue (full n10)) T
ft333 = refl

mt333 : Eq (mirror (full n10)) (full n10)
mt333 = refl

ft334 : Eq (alltrue (full n9)) T
ft334 = refl

mt334 : Eq (mirror (full n8)) (full n8)
mt334 = refl

ft335 : Eq (alltrue (full n8)) T
ft335 = refl

mt335 : Eq (mirror (full n6)) (full n6)
mt335 = refl

ft336 : Eq (alltrue (full n7)) T
ft336 = refl

mt336 : Eq (mirror (full n9)) (full n9)
mt336 = refl

ft337 : Eq (alltrue (full n12)) T
ft337 = refl

mt337 : Eq (mirror (full n7)) (full n7)
mt337 = refl

ft338 : Eq (alltrue (full n11)) T
ft338 = refl

mt338 : Eq (mirror (full n10)) (full n10)
mt338 = refl

ft339 : Eq (alltrue (full n10)) T
ft339 = refl

mt339 : Eq (mirror (full n8)) (full n8)
mt339 = refl

ft340 : Eq (alltrue (full n9)) T
ft340 = refl

mt340 : Eq (mirror (full n6)) (full n6)
mt340 = refl

ft341 : Eq (alltrue (full n8)) T
ft341 = refl

mt341 : Eq (mirror (full n9)) (full n9)
mt341 = refl

ft342 : Eq (alltrue (full n7)) T
ft342 = refl

mt342 : Eq (mirror (full n7)) (full n7)
mt342 = refl

ft343 : Eq (alltrue (full n12)) T
ft343 = refl

mt343 : Eq (mirror (full n10)) (full n10)
mt343 = refl

ft344 : Eq (alltrue (full n11)) T
ft344 = refl

mt344 : Eq (mirror (full n8)) (full n8)
mt344 = refl

ft345 : Eq (alltrue (full n10)) T
ft345 = refl

mt345 : Eq (mirror (full n6)) (full n6)
mt345 = refl

ft346 : Eq (alltrue (full n9)) T
ft346 = refl

mt346 : Eq (mirror (full n9)) (full n9)
mt346 = refl

ft347 : Eq (alltrue (full n8)) T
ft347 = refl

mt347 : Eq (mirror (full n7)) (full n7)
mt347 = refl

ft348 : Eq (alltrue (full n7)) T
ft348 = refl

mt348 : Eq (mirror (full n10)) (full n10)
mt348 = refl

ft349 : Eq (alltrue (full n12)) T
ft349 = refl

mt349 : Eq (mirror (full n8)) (full n8)
mt349 = refl

ft350 : Eq (alltrue (full n11)) T
ft350 = refl

mt350 : Eq (mirror (full n6)) (full n6)
mt350 = refl

ft351 : Eq (alltrue (full n10)) T
ft351 = refl

mt351 : Eq (mirror (full n9)) (full n9)
mt351 = refl

ft352 : Eq (alltrue (full n9)) T
ft352 = refl

mt352 : Eq (mirror (full n7)) (full n7)
mt352 = refl

ft353 : Eq (alltrue (full n8)) T
ft353 = refl

mt353 : Eq (mirror (full n10)) (full n10)
mt353 = refl

ft354 : Eq (alltrue (full n7)) T
ft354 = refl

mt354 : Eq (mirror (full n8)) (full n8)
mt354 = refl

ft355 : Eq (alltrue (full n12)) T
ft355 = refl

mt355 : Eq (mirror (full n6)) (full n6)
mt355 = refl

ft356 : Eq (alltrue (full n11)) T
ft356 = refl

mt356 : Eq (mirror (full n9)) (full n9)
mt356 = refl

ft357 : Eq (alltrue (full n10)) T
ft357 = refl

mt357 : Eq (mirror (full n7)) (full n7)
mt357 = refl

ft358 : Eq (alltrue (full n9)) T
ft358 = refl

mt358 : Eq (mirror (full n10)) (full n10)
mt358 = refl

ft359 : Eq (alltrue (full n8)) T
ft359 = refl

mt359 : Eq (mirror (full n8)) (full n8)
mt359 = refl

ft360 : Eq (alltrue (full n7)) T
ft360 = refl

mt360 : Eq (mirror (full n6)) (full n6)
mt360 = refl

ft361 : Eq (alltrue (full n12)) T
ft361 = refl

mt361 : Eq (mirror (full n9)) (full n9)
mt361 = refl

ft362 : Eq (alltrue (full n11)) T
ft362 = refl

mt362 : Eq (mirror (full n7)) (full n7)
mt362 = refl

ft363 : Eq (alltrue (full n10)) T
ft363 = refl

mt363 : Eq (mirror (full n10)) (full n10)
mt363 = refl

ft364 : Eq (alltrue (full n9)) T
ft364 = refl

mt364 : Eq (mirror (full n8)) (full n8)
mt364 = refl

ft365 : Eq (alltrue (full n8)) T
ft365 = refl

mt365 : Eq (mirror (full n6)) (full n6)
mt365 = refl

ft366 : Eq (alltrue (full n7)) T
ft366 = refl

mt366 : Eq (mirror (full n9)) (full n9)
mt366 = refl

ft367 : Eq (alltrue (full n12)) T
ft367 = refl

mt367 : Eq (mirror (full n7)) (full n7)
mt367 = refl

ft368 : Eq (alltrue (full n11)) T
ft368 = refl

mt368 : Eq (mirror (full n10)) (full n10)
mt368 = refl

ft369 : Eq (alltrue (full n10)) T
ft369 = refl

mt369 : Eq (mirror (full n8)) (full n8)
mt369 = refl

ft370 : Eq (alltrue (full n9)) T
ft370 = refl

mt370 : Eq (mirror (full n6)) (full n6)
mt370 = refl

ft371 : Eq (alltrue (full n8)) T
ft371 = refl

mt371 : Eq (mirror (full n9)) (full n9)
mt371 = refl

ft372 : Eq (alltrue (full n7)) T
ft372 = refl

mt372 : Eq (mirror (full n7)) (full n7)
mt372 = refl

ft373 : Eq (alltrue (full n12)) T
ft373 = refl

mt373 : Eq (mirror (full n10)) (full n10)
mt373 = refl

ft374 : Eq (alltrue (full n11)) T
ft374 = refl

mt374 : Eq (mirror (full n8)) (full n8)
mt374 = refl

ft375 : Eq (alltrue (full n10)) T
ft375 = refl

mt375 : Eq (mirror (full n6)) (full n6)
mt375 = refl

ft376 : Eq (alltrue (full n9)) T
ft376 = refl

mt376 : Eq (mirror (full n9)) (full n9)
mt376 = refl

ft377 : Eq (alltrue (full n8)) T
ft377 = refl

mt377 : Eq (mirror (full n7)) (full n7)
mt377 = refl

ft378 : Eq (alltrue (full n7)) T
ft378 = refl

mt378 : Eq (mirror (full n10)) (full n10)
mt378 = refl

ft379 : Eq (alltrue (full n12)) T
ft379 = refl

mt379 : Eq (mirror (full n8)) (full n8)
mt379 = refl

ft380 : Eq (alltrue (full n11)) T
ft380 = refl

mt380 : Eq (mirror (full n6)) (full n6)
mt380 = refl

ft381 : Eq (alltrue (full n10)) T
ft381 = refl

mt381 : Eq (mirror (full n9)) (full n9)
mt381 = refl

ft382 : Eq (alltrue (full n9)) T
ft382 = refl

mt382 : Eq (mirror (full n7)) (full n7)
mt382 = refl

ft383 : Eq (alltrue (full n8)) T
ft383 = refl

mt383 : Eq (mirror (full n10)) (full n10)
mt383 = refl

ft384 : Eq (alltrue (full n7)) T
ft384 = refl

mt384 : Eq (mirror (full n8)) (full n8)
mt384 = refl

ft385 : Eq (alltrue (full n12)) T
ft385 = refl

mt385 : Eq (mirror (full n6)) (full n6)
mt385 = refl

ft386 : Eq (alltrue (full n11)) T
ft386 = refl

mt386 : Eq (mirror (full n9)) (full n9)
mt386 = refl

ft387 : Eq (alltrue (full n10)) T
ft387 = refl

mt387 : Eq (mirror (full n7)) (full n7)
mt387 = refl

ft388 : Eq (alltrue (full n9)) T
ft388 = refl

mt388 : Eq (mirror (full n10)) (full n10)
mt388 = refl

ft389 : Eq (alltrue (full n8)) T
ft389 = refl

mt389 : Eq (mirror (full n8)) (full n8)
mt389 = refl

ft390 : Eq (alltrue (full n7)) T
ft390 = refl

mt390 : Eq (mirror (full n6)) (full n6)
mt390 = refl

ft391 : Eq (alltrue (full n12)) T
ft391 = refl

mt391 : Eq (mirror (full n9)) (full n9)
mt391 = refl

ft392 : Eq (alltrue (full n11)) T
ft392 = refl

mt392 : Eq (mirror (full n7)) (full n7)
mt392 = refl

ft393 : Eq (alltrue (full n10)) T
ft393 = refl

mt393 : Eq (mirror (full n10)) (full n10)
mt393 = refl

ft394 : Eq (alltrue (full n9)) T
ft394 = refl

mt394 : Eq (mirror (full n8)) (full n8)
mt394 = refl

ft395 : Eq (alltrue (full n8)) T
ft395 = refl

mt395 : Eq (mirror (full n6)) (full n6)
mt395 = refl

ft396 : Eq (alltrue (full n7)) T
ft396 = refl

mt396 : Eq (mirror (full n9)) (full n9)
mt396 = refl

ft397 : Eq (alltrue (full n12)) T
ft397 = refl

mt397 : Eq (mirror (full n7)) (full n7)
mt397 = refl

ft398 : Eq (alltrue (full n11)) T
ft398 = refl

mt398 : Eq (mirror (full n10)) (full n10)
mt398 = refl

ft399 : Eq (alltrue (full n10)) T
ft399 = refl

mt399 : Eq (mirror (full n8)) (full n8)
mt399 = refl

