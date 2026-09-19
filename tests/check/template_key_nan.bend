# a template applied to two F32 trees that differ in one mantissa bit got
# one specialization: term_show keyed both as `nan`, since f32_show prints
# every NaN payload the same way, so contradiction's Pick reduced to
# seed's Unit and a proof of Empty checked. The key now skips the F32
# sugar and tells the bit patterns apart.
type Empty is Data:

type Unit is Data:
  Unit{}

type Bit is Data:
  True{}
  False{}

type Word is Data:
  WNil{}
  WCon{b: Bit, w: Word}

type Float is Data:
  F32{w: Word}

def EmptyIfBit0(x: Float) -> Type:
  match x:
    case F32{WNil{}}:
      Unit
    case F32{WCon{False{}, w}}:
      Unit
    case F32{WCon{True{}, w}}:
      Empty

def Pick(~x: Float) -> Type:
  EmptyIfBit0(x)

# bits 0x7FC00000: exponent all ones, mantissa != 0, bit 0 clear -> Unit
def seed() -> Pick(~F32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}):
  Unit{}

# bits 0x7FC00001: exponent all ones, mantissa != 0, bit 0 set -> Empty
def contradiction() -> Pick(~F32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}):
  seed

#|Error:
#|- expected : Empty
#|- observed : Unit
#|Location: contradiction
#|39 | def contradiction() -> Pick(~F32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}):
#|40>|   seed
#|41 | 
#|exit 1
