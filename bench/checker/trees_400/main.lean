set_option maxRecDepth 100000

namespace Bench

inductive Nat : Type where
  | Z : Nat
  | S : Nat → Nat

def add : Nat → Nat → Nat
  | .Z, b => b
  | .S a, b => .S (add a b)

def n0 : Nat := .Z
def n1 : Nat := .S n0
def n2 : Nat := .S n1
def n3 : Nat := .S n2
def n4 : Nat := .S n3
def n5 : Nat := .S n4
def n6 : Nat := .S n5
def n7 : Nat := .S n6
def n8 : Nat := .S n7
def n9 : Nat := .S n8
def n10 : Nat := .S n9
def n11 : Nat := .S n10
def n12 : Nat := .S n11
def n13 : Nat := .S n12

inductive Bool' : Type where
  | T : Bool'
  | F : Bool'

def and' : Bool' → Bool' → Bool'
  | .T, b => b
  | .F, _ => .F

inductive Tree : Type where
  | L : Tree
  | N : Tree → Tree → Tree

def full : Nat → Tree
  | .Z => .L
  | .S p => .N (full p) (full p)

def mirror : Tree → Tree
  | .L => .L
  | .N l r => .N (mirror r) (mirror l)

def alltrue : Tree → Bool'
  | .L => .T
  | .N l r => and' (alltrue l) (alltrue r)

theorem ft0 : alltrue (full n7) = .T := rfl

theorem mt0 : mirror (full n6) = full n6 := rfl

theorem ft1 : alltrue (full n12) = .T := rfl

theorem mt1 : mirror (full n9) = full n9 := rfl

theorem ft2 : alltrue (full n11) = .T := rfl

theorem mt2 : mirror (full n7) = full n7 := rfl

theorem ft3 : alltrue (full n10) = .T := rfl

theorem mt3 : mirror (full n10) = full n10 := rfl

theorem ft4 : alltrue (full n9) = .T := rfl

theorem mt4 : mirror (full n8) = full n8 := rfl

theorem ft5 : alltrue (full n8) = .T := rfl

theorem mt5 : mirror (full n6) = full n6 := rfl

theorem ft6 : alltrue (full n7) = .T := rfl

theorem mt6 : mirror (full n9) = full n9 := rfl

theorem ft7 : alltrue (full n12) = .T := rfl

theorem mt7 : mirror (full n7) = full n7 := rfl

theorem ft8 : alltrue (full n11) = .T := rfl

theorem mt8 : mirror (full n10) = full n10 := rfl

theorem ft9 : alltrue (full n10) = .T := rfl

theorem mt9 : mirror (full n8) = full n8 := rfl

theorem ft10 : alltrue (full n9) = .T := rfl

theorem mt10 : mirror (full n6) = full n6 := rfl

theorem ft11 : alltrue (full n8) = .T := rfl

theorem mt11 : mirror (full n9) = full n9 := rfl

theorem ft12 : alltrue (full n7) = .T := rfl

theorem mt12 : mirror (full n7) = full n7 := rfl

theorem ft13 : alltrue (full n12) = .T := rfl

theorem mt13 : mirror (full n10) = full n10 := rfl

theorem ft14 : alltrue (full n11) = .T := rfl

theorem mt14 : mirror (full n8) = full n8 := rfl

theorem ft15 : alltrue (full n10) = .T := rfl

theorem mt15 : mirror (full n6) = full n6 := rfl

theorem ft16 : alltrue (full n9) = .T := rfl

theorem mt16 : mirror (full n9) = full n9 := rfl

theorem ft17 : alltrue (full n8) = .T := rfl

theorem mt17 : mirror (full n7) = full n7 := rfl

theorem ft18 : alltrue (full n7) = .T := rfl

theorem mt18 : mirror (full n10) = full n10 := rfl

theorem ft19 : alltrue (full n12) = .T := rfl

theorem mt19 : mirror (full n8) = full n8 := rfl

theorem ft20 : alltrue (full n11) = .T := rfl

theorem mt20 : mirror (full n6) = full n6 := rfl

theorem ft21 : alltrue (full n10) = .T := rfl

theorem mt21 : mirror (full n9) = full n9 := rfl

theorem ft22 : alltrue (full n9) = .T := rfl

theorem mt22 : mirror (full n7) = full n7 := rfl

theorem ft23 : alltrue (full n8) = .T := rfl

theorem mt23 : mirror (full n10) = full n10 := rfl

theorem ft24 : alltrue (full n7) = .T := rfl

theorem mt24 : mirror (full n8) = full n8 := rfl

theorem ft25 : alltrue (full n12) = .T := rfl

theorem mt25 : mirror (full n6) = full n6 := rfl

theorem ft26 : alltrue (full n11) = .T := rfl

theorem mt26 : mirror (full n9) = full n9 := rfl

theorem ft27 : alltrue (full n10) = .T := rfl

theorem mt27 : mirror (full n7) = full n7 := rfl

theorem ft28 : alltrue (full n9) = .T := rfl

theorem mt28 : mirror (full n10) = full n10 := rfl

theorem ft29 : alltrue (full n8) = .T := rfl

theorem mt29 : mirror (full n8) = full n8 := rfl

theorem ft30 : alltrue (full n7) = .T := rfl

theorem mt30 : mirror (full n6) = full n6 := rfl

theorem ft31 : alltrue (full n12) = .T := rfl

theorem mt31 : mirror (full n9) = full n9 := rfl

theorem ft32 : alltrue (full n11) = .T := rfl

theorem mt32 : mirror (full n7) = full n7 := rfl

theorem ft33 : alltrue (full n10) = .T := rfl

theorem mt33 : mirror (full n10) = full n10 := rfl

theorem ft34 : alltrue (full n9) = .T := rfl

theorem mt34 : mirror (full n8) = full n8 := rfl

theorem ft35 : alltrue (full n8) = .T := rfl

theorem mt35 : mirror (full n6) = full n6 := rfl

theorem ft36 : alltrue (full n7) = .T := rfl

theorem mt36 : mirror (full n9) = full n9 := rfl

theorem ft37 : alltrue (full n12) = .T := rfl

theorem mt37 : mirror (full n7) = full n7 := rfl

theorem ft38 : alltrue (full n11) = .T := rfl

theorem mt38 : mirror (full n10) = full n10 := rfl

theorem ft39 : alltrue (full n10) = .T := rfl

theorem mt39 : mirror (full n8) = full n8 := rfl

theorem ft40 : alltrue (full n9) = .T := rfl

theorem mt40 : mirror (full n6) = full n6 := rfl

theorem ft41 : alltrue (full n8) = .T := rfl

theorem mt41 : mirror (full n9) = full n9 := rfl

theorem ft42 : alltrue (full n7) = .T := rfl

theorem mt42 : mirror (full n7) = full n7 := rfl

theorem ft43 : alltrue (full n12) = .T := rfl

theorem mt43 : mirror (full n10) = full n10 := rfl

theorem ft44 : alltrue (full n11) = .T := rfl

theorem mt44 : mirror (full n8) = full n8 := rfl

theorem ft45 : alltrue (full n10) = .T := rfl

theorem mt45 : mirror (full n6) = full n6 := rfl

theorem ft46 : alltrue (full n9) = .T := rfl

theorem mt46 : mirror (full n9) = full n9 := rfl

theorem ft47 : alltrue (full n8) = .T := rfl

theorem mt47 : mirror (full n7) = full n7 := rfl

theorem ft48 : alltrue (full n7) = .T := rfl

theorem mt48 : mirror (full n10) = full n10 := rfl

theorem ft49 : alltrue (full n12) = .T := rfl

theorem mt49 : mirror (full n8) = full n8 := rfl

theorem ft50 : alltrue (full n11) = .T := rfl

theorem mt50 : mirror (full n6) = full n6 := rfl

theorem ft51 : alltrue (full n10) = .T := rfl

theorem mt51 : mirror (full n9) = full n9 := rfl

theorem ft52 : alltrue (full n9) = .T := rfl

theorem mt52 : mirror (full n7) = full n7 := rfl

theorem ft53 : alltrue (full n8) = .T := rfl

theorem mt53 : mirror (full n10) = full n10 := rfl

theorem ft54 : alltrue (full n7) = .T := rfl

theorem mt54 : mirror (full n8) = full n8 := rfl

theorem ft55 : alltrue (full n12) = .T := rfl

theorem mt55 : mirror (full n6) = full n6 := rfl

theorem ft56 : alltrue (full n11) = .T := rfl

theorem mt56 : mirror (full n9) = full n9 := rfl

theorem ft57 : alltrue (full n10) = .T := rfl

theorem mt57 : mirror (full n7) = full n7 := rfl

theorem ft58 : alltrue (full n9) = .T := rfl

theorem mt58 : mirror (full n10) = full n10 := rfl

theorem ft59 : alltrue (full n8) = .T := rfl

theorem mt59 : mirror (full n8) = full n8 := rfl

theorem ft60 : alltrue (full n7) = .T := rfl

theorem mt60 : mirror (full n6) = full n6 := rfl

theorem ft61 : alltrue (full n12) = .T := rfl

theorem mt61 : mirror (full n9) = full n9 := rfl

theorem ft62 : alltrue (full n11) = .T := rfl

theorem mt62 : mirror (full n7) = full n7 := rfl

theorem ft63 : alltrue (full n10) = .T := rfl

theorem mt63 : mirror (full n10) = full n10 := rfl

theorem ft64 : alltrue (full n9) = .T := rfl

theorem mt64 : mirror (full n8) = full n8 := rfl

theorem ft65 : alltrue (full n8) = .T := rfl

theorem mt65 : mirror (full n6) = full n6 := rfl

theorem ft66 : alltrue (full n7) = .T := rfl

theorem mt66 : mirror (full n9) = full n9 := rfl

theorem ft67 : alltrue (full n12) = .T := rfl

theorem mt67 : mirror (full n7) = full n7 := rfl

theorem ft68 : alltrue (full n11) = .T := rfl

theorem mt68 : mirror (full n10) = full n10 := rfl

theorem ft69 : alltrue (full n10) = .T := rfl

theorem mt69 : mirror (full n8) = full n8 := rfl

theorem ft70 : alltrue (full n9) = .T := rfl

theorem mt70 : mirror (full n6) = full n6 := rfl

theorem ft71 : alltrue (full n8) = .T := rfl

theorem mt71 : mirror (full n9) = full n9 := rfl

theorem ft72 : alltrue (full n7) = .T := rfl

theorem mt72 : mirror (full n7) = full n7 := rfl

theorem ft73 : alltrue (full n12) = .T := rfl

theorem mt73 : mirror (full n10) = full n10 := rfl

theorem ft74 : alltrue (full n11) = .T := rfl

theorem mt74 : mirror (full n8) = full n8 := rfl

theorem ft75 : alltrue (full n10) = .T := rfl

theorem mt75 : mirror (full n6) = full n6 := rfl

theorem ft76 : alltrue (full n9) = .T := rfl

theorem mt76 : mirror (full n9) = full n9 := rfl

theorem ft77 : alltrue (full n8) = .T := rfl

theorem mt77 : mirror (full n7) = full n7 := rfl

theorem ft78 : alltrue (full n7) = .T := rfl

theorem mt78 : mirror (full n10) = full n10 := rfl

theorem ft79 : alltrue (full n12) = .T := rfl

theorem mt79 : mirror (full n8) = full n8 := rfl

theorem ft80 : alltrue (full n11) = .T := rfl

theorem mt80 : mirror (full n6) = full n6 := rfl

theorem ft81 : alltrue (full n10) = .T := rfl

theorem mt81 : mirror (full n9) = full n9 := rfl

theorem ft82 : alltrue (full n9) = .T := rfl

theorem mt82 : mirror (full n7) = full n7 := rfl

theorem ft83 : alltrue (full n8) = .T := rfl

theorem mt83 : mirror (full n10) = full n10 := rfl

theorem ft84 : alltrue (full n7) = .T := rfl

theorem mt84 : mirror (full n8) = full n8 := rfl

theorem ft85 : alltrue (full n12) = .T := rfl

theorem mt85 : mirror (full n6) = full n6 := rfl

theorem ft86 : alltrue (full n11) = .T := rfl

theorem mt86 : mirror (full n9) = full n9 := rfl

theorem ft87 : alltrue (full n10) = .T := rfl

theorem mt87 : mirror (full n7) = full n7 := rfl

theorem ft88 : alltrue (full n9) = .T := rfl

theorem mt88 : mirror (full n10) = full n10 := rfl

theorem ft89 : alltrue (full n8) = .T := rfl

theorem mt89 : mirror (full n8) = full n8 := rfl

theorem ft90 : alltrue (full n7) = .T := rfl

theorem mt90 : mirror (full n6) = full n6 := rfl

theorem ft91 : alltrue (full n12) = .T := rfl

theorem mt91 : mirror (full n9) = full n9 := rfl

theorem ft92 : alltrue (full n11) = .T := rfl

theorem mt92 : mirror (full n7) = full n7 := rfl

theorem ft93 : alltrue (full n10) = .T := rfl

theorem mt93 : mirror (full n10) = full n10 := rfl

theorem ft94 : alltrue (full n9) = .T := rfl

theorem mt94 : mirror (full n8) = full n8 := rfl

theorem ft95 : alltrue (full n8) = .T := rfl

theorem mt95 : mirror (full n6) = full n6 := rfl

theorem ft96 : alltrue (full n7) = .T := rfl

theorem mt96 : mirror (full n9) = full n9 := rfl

theorem ft97 : alltrue (full n12) = .T := rfl

theorem mt97 : mirror (full n7) = full n7 := rfl

theorem ft98 : alltrue (full n11) = .T := rfl

theorem mt98 : mirror (full n10) = full n10 := rfl

theorem ft99 : alltrue (full n10) = .T := rfl

theorem mt99 : mirror (full n8) = full n8 := rfl

theorem ft100 : alltrue (full n9) = .T := rfl

theorem mt100 : mirror (full n6) = full n6 := rfl

theorem ft101 : alltrue (full n8) = .T := rfl

theorem mt101 : mirror (full n9) = full n9 := rfl

theorem ft102 : alltrue (full n7) = .T := rfl

theorem mt102 : mirror (full n7) = full n7 := rfl

theorem ft103 : alltrue (full n12) = .T := rfl

theorem mt103 : mirror (full n10) = full n10 := rfl

theorem ft104 : alltrue (full n11) = .T := rfl

theorem mt104 : mirror (full n8) = full n8 := rfl

theorem ft105 : alltrue (full n10) = .T := rfl

theorem mt105 : mirror (full n6) = full n6 := rfl

theorem ft106 : alltrue (full n9) = .T := rfl

theorem mt106 : mirror (full n9) = full n9 := rfl

theorem ft107 : alltrue (full n8) = .T := rfl

theorem mt107 : mirror (full n7) = full n7 := rfl

theorem ft108 : alltrue (full n7) = .T := rfl

theorem mt108 : mirror (full n10) = full n10 := rfl

theorem ft109 : alltrue (full n12) = .T := rfl

theorem mt109 : mirror (full n8) = full n8 := rfl

theorem ft110 : alltrue (full n11) = .T := rfl

theorem mt110 : mirror (full n6) = full n6 := rfl

theorem ft111 : alltrue (full n10) = .T := rfl

theorem mt111 : mirror (full n9) = full n9 := rfl

theorem ft112 : alltrue (full n9) = .T := rfl

theorem mt112 : mirror (full n7) = full n7 := rfl

theorem ft113 : alltrue (full n8) = .T := rfl

theorem mt113 : mirror (full n10) = full n10 := rfl

theorem ft114 : alltrue (full n7) = .T := rfl

theorem mt114 : mirror (full n8) = full n8 := rfl

theorem ft115 : alltrue (full n12) = .T := rfl

theorem mt115 : mirror (full n6) = full n6 := rfl

theorem ft116 : alltrue (full n11) = .T := rfl

theorem mt116 : mirror (full n9) = full n9 := rfl

theorem ft117 : alltrue (full n10) = .T := rfl

theorem mt117 : mirror (full n7) = full n7 := rfl

theorem ft118 : alltrue (full n9) = .T := rfl

theorem mt118 : mirror (full n10) = full n10 := rfl

theorem ft119 : alltrue (full n8) = .T := rfl

theorem mt119 : mirror (full n8) = full n8 := rfl

theorem ft120 : alltrue (full n7) = .T := rfl

theorem mt120 : mirror (full n6) = full n6 := rfl

theorem ft121 : alltrue (full n12) = .T := rfl

theorem mt121 : mirror (full n9) = full n9 := rfl

theorem ft122 : alltrue (full n11) = .T := rfl

theorem mt122 : mirror (full n7) = full n7 := rfl

theorem ft123 : alltrue (full n10) = .T := rfl

theorem mt123 : mirror (full n10) = full n10 := rfl

theorem ft124 : alltrue (full n9) = .T := rfl

theorem mt124 : mirror (full n8) = full n8 := rfl

theorem ft125 : alltrue (full n8) = .T := rfl

theorem mt125 : mirror (full n6) = full n6 := rfl

theorem ft126 : alltrue (full n7) = .T := rfl

theorem mt126 : mirror (full n9) = full n9 := rfl

theorem ft127 : alltrue (full n12) = .T := rfl

theorem mt127 : mirror (full n7) = full n7 := rfl

theorem ft128 : alltrue (full n11) = .T := rfl

theorem mt128 : mirror (full n10) = full n10 := rfl

theorem ft129 : alltrue (full n10) = .T := rfl

theorem mt129 : mirror (full n8) = full n8 := rfl

theorem ft130 : alltrue (full n9) = .T := rfl

theorem mt130 : mirror (full n6) = full n6 := rfl

theorem ft131 : alltrue (full n8) = .T := rfl

theorem mt131 : mirror (full n9) = full n9 := rfl

theorem ft132 : alltrue (full n7) = .T := rfl

theorem mt132 : mirror (full n7) = full n7 := rfl

theorem ft133 : alltrue (full n12) = .T := rfl

theorem mt133 : mirror (full n10) = full n10 := rfl

theorem ft134 : alltrue (full n11) = .T := rfl

theorem mt134 : mirror (full n8) = full n8 := rfl

theorem ft135 : alltrue (full n10) = .T := rfl

theorem mt135 : mirror (full n6) = full n6 := rfl

theorem ft136 : alltrue (full n9) = .T := rfl

theorem mt136 : mirror (full n9) = full n9 := rfl

theorem ft137 : alltrue (full n8) = .T := rfl

theorem mt137 : mirror (full n7) = full n7 := rfl

theorem ft138 : alltrue (full n7) = .T := rfl

theorem mt138 : mirror (full n10) = full n10 := rfl

theorem ft139 : alltrue (full n12) = .T := rfl

theorem mt139 : mirror (full n8) = full n8 := rfl

theorem ft140 : alltrue (full n11) = .T := rfl

theorem mt140 : mirror (full n6) = full n6 := rfl

theorem ft141 : alltrue (full n10) = .T := rfl

theorem mt141 : mirror (full n9) = full n9 := rfl

theorem ft142 : alltrue (full n9) = .T := rfl

theorem mt142 : mirror (full n7) = full n7 := rfl

theorem ft143 : alltrue (full n8) = .T := rfl

theorem mt143 : mirror (full n10) = full n10 := rfl

theorem ft144 : alltrue (full n7) = .T := rfl

theorem mt144 : mirror (full n8) = full n8 := rfl

theorem ft145 : alltrue (full n12) = .T := rfl

theorem mt145 : mirror (full n6) = full n6 := rfl

theorem ft146 : alltrue (full n11) = .T := rfl

theorem mt146 : mirror (full n9) = full n9 := rfl

theorem ft147 : alltrue (full n10) = .T := rfl

theorem mt147 : mirror (full n7) = full n7 := rfl

theorem ft148 : alltrue (full n9) = .T := rfl

theorem mt148 : mirror (full n10) = full n10 := rfl

theorem ft149 : alltrue (full n8) = .T := rfl

theorem mt149 : mirror (full n8) = full n8 := rfl

theorem ft150 : alltrue (full n7) = .T := rfl

theorem mt150 : mirror (full n6) = full n6 := rfl

theorem ft151 : alltrue (full n12) = .T := rfl

theorem mt151 : mirror (full n9) = full n9 := rfl

theorem ft152 : alltrue (full n11) = .T := rfl

theorem mt152 : mirror (full n7) = full n7 := rfl

theorem ft153 : alltrue (full n10) = .T := rfl

theorem mt153 : mirror (full n10) = full n10 := rfl

theorem ft154 : alltrue (full n9) = .T := rfl

theorem mt154 : mirror (full n8) = full n8 := rfl

theorem ft155 : alltrue (full n8) = .T := rfl

theorem mt155 : mirror (full n6) = full n6 := rfl

theorem ft156 : alltrue (full n7) = .T := rfl

theorem mt156 : mirror (full n9) = full n9 := rfl

theorem ft157 : alltrue (full n12) = .T := rfl

theorem mt157 : mirror (full n7) = full n7 := rfl

theorem ft158 : alltrue (full n11) = .T := rfl

theorem mt158 : mirror (full n10) = full n10 := rfl

theorem ft159 : alltrue (full n10) = .T := rfl

theorem mt159 : mirror (full n8) = full n8 := rfl

theorem ft160 : alltrue (full n9) = .T := rfl

theorem mt160 : mirror (full n6) = full n6 := rfl

theorem ft161 : alltrue (full n8) = .T := rfl

theorem mt161 : mirror (full n9) = full n9 := rfl

theorem ft162 : alltrue (full n7) = .T := rfl

theorem mt162 : mirror (full n7) = full n7 := rfl

theorem ft163 : alltrue (full n12) = .T := rfl

theorem mt163 : mirror (full n10) = full n10 := rfl

theorem ft164 : alltrue (full n11) = .T := rfl

theorem mt164 : mirror (full n8) = full n8 := rfl

theorem ft165 : alltrue (full n10) = .T := rfl

theorem mt165 : mirror (full n6) = full n6 := rfl

theorem ft166 : alltrue (full n9) = .T := rfl

theorem mt166 : mirror (full n9) = full n9 := rfl

theorem ft167 : alltrue (full n8) = .T := rfl

theorem mt167 : mirror (full n7) = full n7 := rfl

theorem ft168 : alltrue (full n7) = .T := rfl

theorem mt168 : mirror (full n10) = full n10 := rfl

theorem ft169 : alltrue (full n12) = .T := rfl

theorem mt169 : mirror (full n8) = full n8 := rfl

theorem ft170 : alltrue (full n11) = .T := rfl

theorem mt170 : mirror (full n6) = full n6 := rfl

theorem ft171 : alltrue (full n10) = .T := rfl

theorem mt171 : mirror (full n9) = full n9 := rfl

theorem ft172 : alltrue (full n9) = .T := rfl

theorem mt172 : mirror (full n7) = full n7 := rfl

theorem ft173 : alltrue (full n8) = .T := rfl

theorem mt173 : mirror (full n10) = full n10 := rfl

theorem ft174 : alltrue (full n7) = .T := rfl

theorem mt174 : mirror (full n8) = full n8 := rfl

theorem ft175 : alltrue (full n12) = .T := rfl

theorem mt175 : mirror (full n6) = full n6 := rfl

theorem ft176 : alltrue (full n11) = .T := rfl

theorem mt176 : mirror (full n9) = full n9 := rfl

theorem ft177 : alltrue (full n10) = .T := rfl

theorem mt177 : mirror (full n7) = full n7 := rfl

theorem ft178 : alltrue (full n9) = .T := rfl

theorem mt178 : mirror (full n10) = full n10 := rfl

theorem ft179 : alltrue (full n8) = .T := rfl

theorem mt179 : mirror (full n8) = full n8 := rfl

theorem ft180 : alltrue (full n7) = .T := rfl

theorem mt180 : mirror (full n6) = full n6 := rfl

theorem ft181 : alltrue (full n12) = .T := rfl

theorem mt181 : mirror (full n9) = full n9 := rfl

theorem ft182 : alltrue (full n11) = .T := rfl

theorem mt182 : mirror (full n7) = full n7 := rfl

theorem ft183 : alltrue (full n10) = .T := rfl

theorem mt183 : mirror (full n10) = full n10 := rfl

theorem ft184 : alltrue (full n9) = .T := rfl

theorem mt184 : mirror (full n8) = full n8 := rfl

theorem ft185 : alltrue (full n8) = .T := rfl

theorem mt185 : mirror (full n6) = full n6 := rfl

theorem ft186 : alltrue (full n7) = .T := rfl

theorem mt186 : mirror (full n9) = full n9 := rfl

theorem ft187 : alltrue (full n12) = .T := rfl

theorem mt187 : mirror (full n7) = full n7 := rfl

theorem ft188 : alltrue (full n11) = .T := rfl

theorem mt188 : mirror (full n10) = full n10 := rfl

theorem ft189 : alltrue (full n10) = .T := rfl

theorem mt189 : mirror (full n8) = full n8 := rfl

theorem ft190 : alltrue (full n9) = .T := rfl

theorem mt190 : mirror (full n6) = full n6 := rfl

theorem ft191 : alltrue (full n8) = .T := rfl

theorem mt191 : mirror (full n9) = full n9 := rfl

theorem ft192 : alltrue (full n7) = .T := rfl

theorem mt192 : mirror (full n7) = full n7 := rfl

theorem ft193 : alltrue (full n12) = .T := rfl

theorem mt193 : mirror (full n10) = full n10 := rfl

theorem ft194 : alltrue (full n11) = .T := rfl

theorem mt194 : mirror (full n8) = full n8 := rfl

theorem ft195 : alltrue (full n10) = .T := rfl

theorem mt195 : mirror (full n6) = full n6 := rfl

theorem ft196 : alltrue (full n9) = .T := rfl

theorem mt196 : mirror (full n9) = full n9 := rfl

theorem ft197 : alltrue (full n8) = .T := rfl

theorem mt197 : mirror (full n7) = full n7 := rfl

theorem ft198 : alltrue (full n7) = .T := rfl

theorem mt198 : mirror (full n10) = full n10 := rfl

theorem ft199 : alltrue (full n12) = .T := rfl

theorem mt199 : mirror (full n8) = full n8 := rfl

theorem ft200 : alltrue (full n11) = .T := rfl

theorem mt200 : mirror (full n6) = full n6 := rfl

theorem ft201 : alltrue (full n10) = .T := rfl

theorem mt201 : mirror (full n9) = full n9 := rfl

theorem ft202 : alltrue (full n9) = .T := rfl

theorem mt202 : mirror (full n7) = full n7 := rfl

theorem ft203 : alltrue (full n8) = .T := rfl

theorem mt203 : mirror (full n10) = full n10 := rfl

theorem ft204 : alltrue (full n7) = .T := rfl

theorem mt204 : mirror (full n8) = full n8 := rfl

theorem ft205 : alltrue (full n12) = .T := rfl

theorem mt205 : mirror (full n6) = full n6 := rfl

theorem ft206 : alltrue (full n11) = .T := rfl

theorem mt206 : mirror (full n9) = full n9 := rfl

theorem ft207 : alltrue (full n10) = .T := rfl

theorem mt207 : mirror (full n7) = full n7 := rfl

theorem ft208 : alltrue (full n9) = .T := rfl

theorem mt208 : mirror (full n10) = full n10 := rfl

theorem ft209 : alltrue (full n8) = .T := rfl

theorem mt209 : mirror (full n8) = full n8 := rfl

theorem ft210 : alltrue (full n7) = .T := rfl

theorem mt210 : mirror (full n6) = full n6 := rfl

theorem ft211 : alltrue (full n12) = .T := rfl

theorem mt211 : mirror (full n9) = full n9 := rfl

theorem ft212 : alltrue (full n11) = .T := rfl

theorem mt212 : mirror (full n7) = full n7 := rfl

theorem ft213 : alltrue (full n10) = .T := rfl

theorem mt213 : mirror (full n10) = full n10 := rfl

theorem ft214 : alltrue (full n9) = .T := rfl

theorem mt214 : mirror (full n8) = full n8 := rfl

theorem ft215 : alltrue (full n8) = .T := rfl

theorem mt215 : mirror (full n6) = full n6 := rfl

theorem ft216 : alltrue (full n7) = .T := rfl

theorem mt216 : mirror (full n9) = full n9 := rfl

theorem ft217 : alltrue (full n12) = .T := rfl

theorem mt217 : mirror (full n7) = full n7 := rfl

theorem ft218 : alltrue (full n11) = .T := rfl

theorem mt218 : mirror (full n10) = full n10 := rfl

theorem ft219 : alltrue (full n10) = .T := rfl

theorem mt219 : mirror (full n8) = full n8 := rfl

theorem ft220 : alltrue (full n9) = .T := rfl

theorem mt220 : mirror (full n6) = full n6 := rfl

theorem ft221 : alltrue (full n8) = .T := rfl

theorem mt221 : mirror (full n9) = full n9 := rfl

theorem ft222 : alltrue (full n7) = .T := rfl

theorem mt222 : mirror (full n7) = full n7 := rfl

theorem ft223 : alltrue (full n12) = .T := rfl

theorem mt223 : mirror (full n10) = full n10 := rfl

theorem ft224 : alltrue (full n11) = .T := rfl

theorem mt224 : mirror (full n8) = full n8 := rfl

theorem ft225 : alltrue (full n10) = .T := rfl

theorem mt225 : mirror (full n6) = full n6 := rfl

theorem ft226 : alltrue (full n9) = .T := rfl

theorem mt226 : mirror (full n9) = full n9 := rfl

theorem ft227 : alltrue (full n8) = .T := rfl

theorem mt227 : mirror (full n7) = full n7 := rfl

theorem ft228 : alltrue (full n7) = .T := rfl

theorem mt228 : mirror (full n10) = full n10 := rfl

theorem ft229 : alltrue (full n12) = .T := rfl

theorem mt229 : mirror (full n8) = full n8 := rfl

theorem ft230 : alltrue (full n11) = .T := rfl

theorem mt230 : mirror (full n6) = full n6 := rfl

theorem ft231 : alltrue (full n10) = .T := rfl

theorem mt231 : mirror (full n9) = full n9 := rfl

theorem ft232 : alltrue (full n9) = .T := rfl

theorem mt232 : mirror (full n7) = full n7 := rfl

theorem ft233 : alltrue (full n8) = .T := rfl

theorem mt233 : mirror (full n10) = full n10 := rfl

theorem ft234 : alltrue (full n7) = .T := rfl

theorem mt234 : mirror (full n8) = full n8 := rfl

theorem ft235 : alltrue (full n12) = .T := rfl

theorem mt235 : mirror (full n6) = full n6 := rfl

theorem ft236 : alltrue (full n11) = .T := rfl

theorem mt236 : mirror (full n9) = full n9 := rfl

theorem ft237 : alltrue (full n10) = .T := rfl

theorem mt237 : mirror (full n7) = full n7 := rfl

theorem ft238 : alltrue (full n9) = .T := rfl

theorem mt238 : mirror (full n10) = full n10 := rfl

theorem ft239 : alltrue (full n8) = .T := rfl

theorem mt239 : mirror (full n8) = full n8 := rfl

theorem ft240 : alltrue (full n7) = .T := rfl

theorem mt240 : mirror (full n6) = full n6 := rfl

theorem ft241 : alltrue (full n12) = .T := rfl

theorem mt241 : mirror (full n9) = full n9 := rfl

theorem ft242 : alltrue (full n11) = .T := rfl

theorem mt242 : mirror (full n7) = full n7 := rfl

theorem ft243 : alltrue (full n10) = .T := rfl

theorem mt243 : mirror (full n10) = full n10 := rfl

theorem ft244 : alltrue (full n9) = .T := rfl

theorem mt244 : mirror (full n8) = full n8 := rfl

theorem ft245 : alltrue (full n8) = .T := rfl

theorem mt245 : mirror (full n6) = full n6 := rfl

theorem ft246 : alltrue (full n7) = .T := rfl

theorem mt246 : mirror (full n9) = full n9 := rfl

theorem ft247 : alltrue (full n12) = .T := rfl

theorem mt247 : mirror (full n7) = full n7 := rfl

theorem ft248 : alltrue (full n11) = .T := rfl

theorem mt248 : mirror (full n10) = full n10 := rfl

theorem ft249 : alltrue (full n10) = .T := rfl

theorem mt249 : mirror (full n8) = full n8 := rfl

theorem ft250 : alltrue (full n9) = .T := rfl

theorem mt250 : mirror (full n6) = full n6 := rfl

theorem ft251 : alltrue (full n8) = .T := rfl

theorem mt251 : mirror (full n9) = full n9 := rfl

theorem ft252 : alltrue (full n7) = .T := rfl

theorem mt252 : mirror (full n7) = full n7 := rfl

theorem ft253 : alltrue (full n12) = .T := rfl

theorem mt253 : mirror (full n10) = full n10 := rfl

theorem ft254 : alltrue (full n11) = .T := rfl

theorem mt254 : mirror (full n8) = full n8 := rfl

theorem ft255 : alltrue (full n10) = .T := rfl

theorem mt255 : mirror (full n6) = full n6 := rfl

theorem ft256 : alltrue (full n9) = .T := rfl

theorem mt256 : mirror (full n9) = full n9 := rfl

theorem ft257 : alltrue (full n8) = .T := rfl

theorem mt257 : mirror (full n7) = full n7 := rfl

theorem ft258 : alltrue (full n7) = .T := rfl

theorem mt258 : mirror (full n10) = full n10 := rfl

theorem ft259 : alltrue (full n12) = .T := rfl

theorem mt259 : mirror (full n8) = full n8 := rfl

theorem ft260 : alltrue (full n11) = .T := rfl

theorem mt260 : mirror (full n6) = full n6 := rfl

theorem ft261 : alltrue (full n10) = .T := rfl

theorem mt261 : mirror (full n9) = full n9 := rfl

theorem ft262 : alltrue (full n9) = .T := rfl

theorem mt262 : mirror (full n7) = full n7 := rfl

theorem ft263 : alltrue (full n8) = .T := rfl

theorem mt263 : mirror (full n10) = full n10 := rfl

theorem ft264 : alltrue (full n7) = .T := rfl

theorem mt264 : mirror (full n8) = full n8 := rfl

theorem ft265 : alltrue (full n12) = .T := rfl

theorem mt265 : mirror (full n6) = full n6 := rfl

theorem ft266 : alltrue (full n11) = .T := rfl

theorem mt266 : mirror (full n9) = full n9 := rfl

theorem ft267 : alltrue (full n10) = .T := rfl

theorem mt267 : mirror (full n7) = full n7 := rfl

theorem ft268 : alltrue (full n9) = .T := rfl

theorem mt268 : mirror (full n10) = full n10 := rfl

theorem ft269 : alltrue (full n8) = .T := rfl

theorem mt269 : mirror (full n8) = full n8 := rfl

theorem ft270 : alltrue (full n7) = .T := rfl

theorem mt270 : mirror (full n6) = full n6 := rfl

theorem ft271 : alltrue (full n12) = .T := rfl

theorem mt271 : mirror (full n9) = full n9 := rfl

theorem ft272 : alltrue (full n11) = .T := rfl

theorem mt272 : mirror (full n7) = full n7 := rfl

theorem ft273 : alltrue (full n10) = .T := rfl

theorem mt273 : mirror (full n10) = full n10 := rfl

theorem ft274 : alltrue (full n9) = .T := rfl

theorem mt274 : mirror (full n8) = full n8 := rfl

theorem ft275 : alltrue (full n8) = .T := rfl

theorem mt275 : mirror (full n6) = full n6 := rfl

theorem ft276 : alltrue (full n7) = .T := rfl

theorem mt276 : mirror (full n9) = full n9 := rfl

theorem ft277 : alltrue (full n12) = .T := rfl

theorem mt277 : mirror (full n7) = full n7 := rfl

theorem ft278 : alltrue (full n11) = .T := rfl

theorem mt278 : mirror (full n10) = full n10 := rfl

theorem ft279 : alltrue (full n10) = .T := rfl

theorem mt279 : mirror (full n8) = full n8 := rfl

theorem ft280 : alltrue (full n9) = .T := rfl

theorem mt280 : mirror (full n6) = full n6 := rfl

theorem ft281 : alltrue (full n8) = .T := rfl

theorem mt281 : mirror (full n9) = full n9 := rfl

theorem ft282 : alltrue (full n7) = .T := rfl

theorem mt282 : mirror (full n7) = full n7 := rfl

theorem ft283 : alltrue (full n12) = .T := rfl

theorem mt283 : mirror (full n10) = full n10 := rfl

theorem ft284 : alltrue (full n11) = .T := rfl

theorem mt284 : mirror (full n8) = full n8 := rfl

theorem ft285 : alltrue (full n10) = .T := rfl

theorem mt285 : mirror (full n6) = full n6 := rfl

theorem ft286 : alltrue (full n9) = .T := rfl

theorem mt286 : mirror (full n9) = full n9 := rfl

theorem ft287 : alltrue (full n8) = .T := rfl

theorem mt287 : mirror (full n7) = full n7 := rfl

theorem ft288 : alltrue (full n7) = .T := rfl

theorem mt288 : mirror (full n10) = full n10 := rfl

theorem ft289 : alltrue (full n12) = .T := rfl

theorem mt289 : mirror (full n8) = full n8 := rfl

theorem ft290 : alltrue (full n11) = .T := rfl

theorem mt290 : mirror (full n6) = full n6 := rfl

theorem ft291 : alltrue (full n10) = .T := rfl

theorem mt291 : mirror (full n9) = full n9 := rfl

theorem ft292 : alltrue (full n9) = .T := rfl

theorem mt292 : mirror (full n7) = full n7 := rfl

theorem ft293 : alltrue (full n8) = .T := rfl

theorem mt293 : mirror (full n10) = full n10 := rfl

theorem ft294 : alltrue (full n7) = .T := rfl

theorem mt294 : mirror (full n8) = full n8 := rfl

theorem ft295 : alltrue (full n12) = .T := rfl

theorem mt295 : mirror (full n6) = full n6 := rfl

theorem ft296 : alltrue (full n11) = .T := rfl

theorem mt296 : mirror (full n9) = full n9 := rfl

theorem ft297 : alltrue (full n10) = .T := rfl

theorem mt297 : mirror (full n7) = full n7 := rfl

theorem ft298 : alltrue (full n9) = .T := rfl

theorem mt298 : mirror (full n10) = full n10 := rfl

theorem ft299 : alltrue (full n8) = .T := rfl

theorem mt299 : mirror (full n8) = full n8 := rfl

theorem ft300 : alltrue (full n7) = .T := rfl

theorem mt300 : mirror (full n6) = full n6 := rfl

theorem ft301 : alltrue (full n12) = .T := rfl

theorem mt301 : mirror (full n9) = full n9 := rfl

theorem ft302 : alltrue (full n11) = .T := rfl

theorem mt302 : mirror (full n7) = full n7 := rfl

theorem ft303 : alltrue (full n10) = .T := rfl

theorem mt303 : mirror (full n10) = full n10 := rfl

theorem ft304 : alltrue (full n9) = .T := rfl

theorem mt304 : mirror (full n8) = full n8 := rfl

theorem ft305 : alltrue (full n8) = .T := rfl

theorem mt305 : mirror (full n6) = full n6 := rfl

theorem ft306 : alltrue (full n7) = .T := rfl

theorem mt306 : mirror (full n9) = full n9 := rfl

theorem ft307 : alltrue (full n12) = .T := rfl

theorem mt307 : mirror (full n7) = full n7 := rfl

theorem ft308 : alltrue (full n11) = .T := rfl

theorem mt308 : mirror (full n10) = full n10 := rfl

theorem ft309 : alltrue (full n10) = .T := rfl

theorem mt309 : mirror (full n8) = full n8 := rfl

theorem ft310 : alltrue (full n9) = .T := rfl

theorem mt310 : mirror (full n6) = full n6 := rfl

theorem ft311 : alltrue (full n8) = .T := rfl

theorem mt311 : mirror (full n9) = full n9 := rfl

theorem ft312 : alltrue (full n7) = .T := rfl

theorem mt312 : mirror (full n7) = full n7 := rfl

theorem ft313 : alltrue (full n12) = .T := rfl

theorem mt313 : mirror (full n10) = full n10 := rfl

theorem ft314 : alltrue (full n11) = .T := rfl

theorem mt314 : mirror (full n8) = full n8 := rfl

theorem ft315 : alltrue (full n10) = .T := rfl

theorem mt315 : mirror (full n6) = full n6 := rfl

theorem ft316 : alltrue (full n9) = .T := rfl

theorem mt316 : mirror (full n9) = full n9 := rfl

theorem ft317 : alltrue (full n8) = .T := rfl

theorem mt317 : mirror (full n7) = full n7 := rfl

theorem ft318 : alltrue (full n7) = .T := rfl

theorem mt318 : mirror (full n10) = full n10 := rfl

theorem ft319 : alltrue (full n12) = .T := rfl

theorem mt319 : mirror (full n8) = full n8 := rfl

theorem ft320 : alltrue (full n11) = .T := rfl

theorem mt320 : mirror (full n6) = full n6 := rfl

theorem ft321 : alltrue (full n10) = .T := rfl

theorem mt321 : mirror (full n9) = full n9 := rfl

theorem ft322 : alltrue (full n9) = .T := rfl

theorem mt322 : mirror (full n7) = full n7 := rfl

theorem ft323 : alltrue (full n8) = .T := rfl

theorem mt323 : mirror (full n10) = full n10 := rfl

theorem ft324 : alltrue (full n7) = .T := rfl

theorem mt324 : mirror (full n8) = full n8 := rfl

theorem ft325 : alltrue (full n12) = .T := rfl

theorem mt325 : mirror (full n6) = full n6 := rfl

theorem ft326 : alltrue (full n11) = .T := rfl

theorem mt326 : mirror (full n9) = full n9 := rfl

theorem ft327 : alltrue (full n10) = .T := rfl

theorem mt327 : mirror (full n7) = full n7 := rfl

theorem ft328 : alltrue (full n9) = .T := rfl

theorem mt328 : mirror (full n10) = full n10 := rfl

theorem ft329 : alltrue (full n8) = .T := rfl

theorem mt329 : mirror (full n8) = full n8 := rfl

theorem ft330 : alltrue (full n7) = .T := rfl

theorem mt330 : mirror (full n6) = full n6 := rfl

theorem ft331 : alltrue (full n12) = .T := rfl

theorem mt331 : mirror (full n9) = full n9 := rfl

theorem ft332 : alltrue (full n11) = .T := rfl

theorem mt332 : mirror (full n7) = full n7 := rfl

theorem ft333 : alltrue (full n10) = .T := rfl

theorem mt333 : mirror (full n10) = full n10 := rfl

theorem ft334 : alltrue (full n9) = .T := rfl

theorem mt334 : mirror (full n8) = full n8 := rfl

theorem ft335 : alltrue (full n8) = .T := rfl

theorem mt335 : mirror (full n6) = full n6 := rfl

theorem ft336 : alltrue (full n7) = .T := rfl

theorem mt336 : mirror (full n9) = full n9 := rfl

theorem ft337 : alltrue (full n12) = .T := rfl

theorem mt337 : mirror (full n7) = full n7 := rfl

theorem ft338 : alltrue (full n11) = .T := rfl

theorem mt338 : mirror (full n10) = full n10 := rfl

theorem ft339 : alltrue (full n10) = .T := rfl

theorem mt339 : mirror (full n8) = full n8 := rfl

theorem ft340 : alltrue (full n9) = .T := rfl

theorem mt340 : mirror (full n6) = full n6 := rfl

theorem ft341 : alltrue (full n8) = .T := rfl

theorem mt341 : mirror (full n9) = full n9 := rfl

theorem ft342 : alltrue (full n7) = .T := rfl

theorem mt342 : mirror (full n7) = full n7 := rfl

theorem ft343 : alltrue (full n12) = .T := rfl

theorem mt343 : mirror (full n10) = full n10 := rfl

theorem ft344 : alltrue (full n11) = .T := rfl

theorem mt344 : mirror (full n8) = full n8 := rfl

theorem ft345 : alltrue (full n10) = .T := rfl

theorem mt345 : mirror (full n6) = full n6 := rfl

theorem ft346 : alltrue (full n9) = .T := rfl

theorem mt346 : mirror (full n9) = full n9 := rfl

theorem ft347 : alltrue (full n8) = .T := rfl

theorem mt347 : mirror (full n7) = full n7 := rfl

theorem ft348 : alltrue (full n7) = .T := rfl

theorem mt348 : mirror (full n10) = full n10 := rfl

theorem ft349 : alltrue (full n12) = .T := rfl

theorem mt349 : mirror (full n8) = full n8 := rfl

theorem ft350 : alltrue (full n11) = .T := rfl

theorem mt350 : mirror (full n6) = full n6 := rfl

theorem ft351 : alltrue (full n10) = .T := rfl

theorem mt351 : mirror (full n9) = full n9 := rfl

theorem ft352 : alltrue (full n9) = .T := rfl

theorem mt352 : mirror (full n7) = full n7 := rfl

theorem ft353 : alltrue (full n8) = .T := rfl

theorem mt353 : mirror (full n10) = full n10 := rfl

theorem ft354 : alltrue (full n7) = .T := rfl

theorem mt354 : mirror (full n8) = full n8 := rfl

theorem ft355 : alltrue (full n12) = .T := rfl

theorem mt355 : mirror (full n6) = full n6 := rfl

theorem ft356 : alltrue (full n11) = .T := rfl

theorem mt356 : mirror (full n9) = full n9 := rfl

theorem ft357 : alltrue (full n10) = .T := rfl

theorem mt357 : mirror (full n7) = full n7 := rfl

theorem ft358 : alltrue (full n9) = .T := rfl

theorem mt358 : mirror (full n10) = full n10 := rfl

theorem ft359 : alltrue (full n8) = .T := rfl

theorem mt359 : mirror (full n8) = full n8 := rfl

theorem ft360 : alltrue (full n7) = .T := rfl

theorem mt360 : mirror (full n6) = full n6 := rfl

theorem ft361 : alltrue (full n12) = .T := rfl

theorem mt361 : mirror (full n9) = full n9 := rfl

theorem ft362 : alltrue (full n11) = .T := rfl

theorem mt362 : mirror (full n7) = full n7 := rfl

theorem ft363 : alltrue (full n10) = .T := rfl

theorem mt363 : mirror (full n10) = full n10 := rfl

theorem ft364 : alltrue (full n9) = .T := rfl

theorem mt364 : mirror (full n8) = full n8 := rfl

theorem ft365 : alltrue (full n8) = .T := rfl

theorem mt365 : mirror (full n6) = full n6 := rfl

theorem ft366 : alltrue (full n7) = .T := rfl

theorem mt366 : mirror (full n9) = full n9 := rfl

theorem ft367 : alltrue (full n12) = .T := rfl

theorem mt367 : mirror (full n7) = full n7 := rfl

theorem ft368 : alltrue (full n11) = .T := rfl

theorem mt368 : mirror (full n10) = full n10 := rfl

theorem ft369 : alltrue (full n10) = .T := rfl

theorem mt369 : mirror (full n8) = full n8 := rfl

theorem ft370 : alltrue (full n9) = .T := rfl

theorem mt370 : mirror (full n6) = full n6 := rfl

theorem ft371 : alltrue (full n8) = .T := rfl

theorem mt371 : mirror (full n9) = full n9 := rfl

theorem ft372 : alltrue (full n7) = .T := rfl

theorem mt372 : mirror (full n7) = full n7 := rfl

theorem ft373 : alltrue (full n12) = .T := rfl

theorem mt373 : mirror (full n10) = full n10 := rfl

theorem ft374 : alltrue (full n11) = .T := rfl

theorem mt374 : mirror (full n8) = full n8 := rfl

theorem ft375 : alltrue (full n10) = .T := rfl

theorem mt375 : mirror (full n6) = full n6 := rfl

theorem ft376 : alltrue (full n9) = .T := rfl

theorem mt376 : mirror (full n9) = full n9 := rfl

theorem ft377 : alltrue (full n8) = .T := rfl

theorem mt377 : mirror (full n7) = full n7 := rfl

theorem ft378 : alltrue (full n7) = .T := rfl

theorem mt378 : mirror (full n10) = full n10 := rfl

theorem ft379 : alltrue (full n12) = .T := rfl

theorem mt379 : mirror (full n8) = full n8 := rfl

theorem ft380 : alltrue (full n11) = .T := rfl

theorem mt380 : mirror (full n6) = full n6 := rfl

theorem ft381 : alltrue (full n10) = .T := rfl

theorem mt381 : mirror (full n9) = full n9 := rfl

theorem ft382 : alltrue (full n9) = .T := rfl

theorem mt382 : mirror (full n7) = full n7 := rfl

theorem ft383 : alltrue (full n8) = .T := rfl

theorem mt383 : mirror (full n10) = full n10 := rfl

theorem ft384 : alltrue (full n7) = .T := rfl

theorem mt384 : mirror (full n8) = full n8 := rfl

theorem ft385 : alltrue (full n12) = .T := rfl

theorem mt385 : mirror (full n6) = full n6 := rfl

theorem ft386 : alltrue (full n11) = .T := rfl

theorem mt386 : mirror (full n9) = full n9 := rfl

theorem ft387 : alltrue (full n10) = .T := rfl

theorem mt387 : mirror (full n7) = full n7 := rfl

theorem ft388 : alltrue (full n9) = .T := rfl

theorem mt388 : mirror (full n10) = full n10 := rfl

theorem ft389 : alltrue (full n8) = .T := rfl

theorem mt389 : mirror (full n8) = full n8 := rfl

theorem ft390 : alltrue (full n7) = .T := rfl

theorem mt390 : mirror (full n6) = full n6 := rfl

theorem ft391 : alltrue (full n12) = .T := rfl

theorem mt391 : mirror (full n9) = full n9 := rfl

theorem ft392 : alltrue (full n11) = .T := rfl

theorem mt392 : mirror (full n7) = full n7 := rfl

theorem ft393 : alltrue (full n10) = .T := rfl

theorem mt393 : mirror (full n10) = full n10 := rfl

theorem ft394 : alltrue (full n9) = .T := rfl

theorem mt394 : mirror (full n8) = full n8 := rfl

theorem ft395 : alltrue (full n8) = .T := rfl

theorem mt395 : mirror (full n6) = full n6 := rfl

theorem ft396 : alltrue (full n7) = .T := rfl

theorem mt396 : mirror (full n9) = full n9 := rfl

theorem ft397 : alltrue (full n12) = .T := rfl

theorem mt397 : mirror (full n7) = full n7 := rfl

theorem ft398 : alltrue (full n11) = .T := rfl

theorem mt398 : mirror (full n10) = full n10 := rfl

theorem ft399 : alltrue (full n10) = .T := rfl

theorem mt399 : mirror (full n8) = full n8 := rfl

end Bench
