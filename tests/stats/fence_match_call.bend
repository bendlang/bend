# bend3's term_subst fence, scale layer: a match on the RESULT of a
# call, 128 def-call boundaries deep -- the quadratic-substitution
# counter is gone (no --stats), the boundary chain itself carries on
# base Nat and answers on every lane (the acc guard's 0/k arms become
# is_lt's Bool)
import Base

law n0:
  Nat

def n0():
  0n

law n1:
  Nat

def n1():
  Succ{n0()}

law n2:
  Nat

def n2():
  Succ{n1()}

law n3:
  Nat

def n3():
  Succ{n2()}

law n4:
  Nat

def n4():
  Succ{n3()}

law n5:
  Nat

def n5():
  Succ{n4()}

law n6:
  Nat

def n6():
  Succ{n5()}

law n7:
  Nat

def n7():
  Succ{n6()}

law n8:
  Nat

def n8():
  Succ{n7()}

law n9:
  Nat

def n9():
  Succ{n8()}

law n10:
  Nat

def n10():
  Succ{n9()}

law n11:
  Nat

def n11():
  Succ{n10()}

law n12:
  Nat

def n12():
  Succ{n11()}

law n13:
  Nat

def n13():
  Succ{n12()}

law n14:
  Nat

def n14():
  Succ{n13()}

law n15:
  Nat

def n15():
  Succ{n14()}

law n16:
  Nat

def n16():
  Succ{n15()}

law n17:
  Nat

def n17():
  Succ{n16()}

law n18:
  Nat

def n18():
  Succ{n17()}

law n19:
  Nat

def n19():
  Succ{n18()}

law n20:
  Nat

def n20():
  Succ{n19()}

law n21:
  Nat

def n21():
  Succ{n20()}

law n22:
  Nat

def n22():
  Succ{n21()}

law n23:
  Nat

def n23():
  Succ{n22()}

law n24:
  Nat

def n24():
  Succ{n23()}

law n25:
  Nat

def n25():
  Succ{n24()}

law n26:
  Nat

def n26():
  Succ{n25()}

law n27:
  Nat

def n27():
  Succ{n26()}

law n28:
  Nat

def n28():
  Succ{n27()}

law n29:
  Nat

def n29():
  Succ{n28()}

law n30:
  Nat

def n30():
  Succ{n29()}

law n31:
  Nat

def n31():
  Succ{n30()}

law n32:
  Nat

def n32():
  Succ{n31()}

law n33:
  Nat

def n33():
  Succ{n32()}

law n34:
  Nat

def n34():
  Succ{n33()}

law n35:
  Nat

def n35():
  Succ{n34()}

law n36:
  Nat

def n36():
  Succ{n35()}

law n37:
  Nat

def n37():
  Succ{n36()}

law n38:
  Nat

def n38():
  Succ{n37()}

law n39:
  Nat

def n39():
  Succ{n38()}

law n40:
  Nat

def n40():
  Succ{n39()}

law n41:
  Nat

def n41():
  Succ{n40()}

law n42:
  Nat

def n42():
  Succ{n41()}

law n43:
  Nat

def n43():
  Succ{n42()}

law n44:
  Nat

def n44():
  Succ{n43()}

law n45:
  Nat

def n45():
  Succ{n44()}

law n46:
  Nat

def n46():
  Succ{n45()}

law n47:
  Nat

def n47():
  Succ{n46()}

law n48:
  Nat

def n48():
  Succ{n47()}

law n49:
  Nat

def n49():
  Succ{n48()}

law n50:
  Nat

def n50():
  Succ{n49()}

law n51:
  Nat

def n51():
  Succ{n50()}

law n52:
  Nat

def n52():
  Succ{n51()}

law n53:
  Nat

def n53():
  Succ{n52()}

law n54:
  Nat

def n54():
  Succ{n53()}

law n55:
  Nat

def n55():
  Succ{n54()}

law n56:
  Nat

def n56():
  Succ{n55()}

law n57:
  Nat

def n57():
  Succ{n56()}

law n58:
  Nat

def n58():
  Succ{n57()}

law n59:
  Nat

def n59():
  Succ{n58()}

law n60:
  Nat

def n60():
  Succ{n59()}

law n61:
  Nat

def n61():
  Succ{n60()}

law n62:
  Nat

def n62():
  Succ{n61()}

law n63:
  Nat

def n63():
  Succ{n62()}

law n64:
  Nat

def n64():
  Succ{n63()}

law n65:
  Nat

def n65():
  Succ{n64()}

law n66:
  Nat

def n66():
  Succ{n65()}

law n67:
  Nat

def n67():
  Succ{n66()}

law n68:
  Nat

def n68():
  Succ{n67()}

law n69:
  Nat

def n69():
  Succ{n68()}

law n70:
  Nat

def n70():
  Succ{n69()}

law n71:
  Nat

def n71():
  Succ{n70()}

law n72:
  Nat

def n72():
  Succ{n71()}

law n73:
  Nat

def n73():
  Succ{n72()}

law n74:
  Nat

def n74():
  Succ{n73()}

law n75:
  Nat

def n75():
  Succ{n74()}

law n76:
  Nat

def n76():
  Succ{n75()}

law n77:
  Nat

def n77():
  Succ{n76()}

law n78:
  Nat

def n78():
  Succ{n77()}

law n79:
  Nat

def n79():
  Succ{n78()}

law n80:
  Nat

def n80():
  Succ{n79()}

law n81:
  Nat

def n81():
  Succ{n80()}

law n82:
  Nat

def n82():
  Succ{n81()}

law n83:
  Nat

def n83():
  Succ{n82()}

law n84:
  Nat

def n84():
  Succ{n83()}

law n85:
  Nat

def n85():
  Succ{n84()}

law n86:
  Nat

def n86():
  Succ{n85()}

law n87:
  Nat

def n87():
  Succ{n86()}

law n88:
  Nat

def n88():
  Succ{n87()}

law n89:
  Nat

def n89():
  Succ{n88()}

law n90:
  Nat

def n90():
  Succ{n89()}

law n91:
  Nat

def n91():
  Succ{n90()}

law n92:
  Nat

def n92():
  Succ{n91()}

law n93:
  Nat

def n93():
  Succ{n92()}

law n94:
  Nat

def n94():
  Succ{n93()}

law n95:
  Nat

def n95():
  Succ{n94()}

law n96:
  Nat

def n96():
  Succ{n95()}

law n97:
  Nat

def n97():
  Succ{n96()}

law n98:
  Nat

def n98():
  Succ{n97()}

law n99:
  Nat

def n99():
  Succ{n98()}

law n100:
  Nat

def n100():
  Succ{n99()}

law n101:
  Nat

def n101():
  Succ{n100()}

law n102:
  Nat

def n102():
  Succ{n101()}

law n103:
  Nat

def n103():
  Succ{n102()}

law n104:
  Nat

def n104():
  Succ{n103()}

law n105:
  Nat

def n105():
  Succ{n104()}

law n106:
  Nat

def n106():
  Succ{n105()}

law n107:
  Nat

def n107():
  Succ{n106()}

law n108:
  Nat

def n108():
  Succ{n107()}

law n109:
  Nat

def n109():
  Succ{n108()}

law n110:
  Nat

def n110():
  Succ{n109()}

law n111:
  Nat

def n111():
  Succ{n110()}

law n112:
  Nat

def n112():
  Succ{n111()}

law n113:
  Nat

def n113():
  Succ{n112()}

law n114:
  Nat

def n114():
  Succ{n113()}

law n115:
  Nat

def n115():
  Succ{n114()}

law n116:
  Nat

def n116():
  Succ{n115()}

law n117:
  Nat

def n117():
  Succ{n116()}

law n118:
  Nat

def n118():
  Succ{n117()}

law n119:
  Nat

def n119():
  Succ{n118()}

law n120:
  Nat

def n120():
  Succ{n119()}

law n121:
  Nat

def n121():
  Succ{n120()}

law n122:
  Nat

def n122():
  Succ{n121()}

law n123:
  Nat

def n123():
  Succ{n122()}

law n124:
  Nat

def n124():
  Succ{n123()}

law n125:
  Nat

def n125():
  Succ{n124()}

law n126:
  Nat

def n126():
  Succ{n125()}

law n127:
  Nat

def n127():
  Succ{n126()}

law n128:
  Nat

def n128():
  Succ{n127()}

law run:
  for n    : Nat
  for +acc : U32
  U32

law run.step:
  for acc : U32
  for z   : Bool
  U32

def run.step(acc, z):
  match z:
    case False{}:
      acc
    case True{}:
      (acc + 1 : U32)

def run(n, acc0):
  match n:
    case Zero{}:
      acc0
    case Succ{p}:
      +acc = {acc0 : U32}
      run(p, run.step(acc, U32.is_lt(acc, 1000)))

law t:
  U32

law t.fin:
  for u: U32
  U32

def t.fin(u):
  match u:
    case U32{w}:
      (U32{w} + 1 : U32)

def t():
  t.fin(run(n128(), 1))

law main.out:
  Nat

def main.out():
  U32.to_nat(t())

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|130n
