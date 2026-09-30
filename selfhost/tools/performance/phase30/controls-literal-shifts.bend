# Checked source controls for literal-count native shifts.
import Base

@unsafe
def left_0(+x: U32) -> U32:
  U32.shln(x, 0n)

@unsafe
def left_1(+x: U32) -> U32:
  U32.shln(x, 1n)

@unsafe
def left_8(+x: U32) -> U32:
  U32.shln(x, 8n)

@unsafe
def left_31(+x: U32) -> U32:
  U32.shln(x, 31n)

@unsafe
def left_32(+x: U32) -> U32:
  U32.shln(x, 32n)

@unsafe
def left_33(+x: U32) -> U32:
  U32.shln(x, 33n)

@unsafe
def left_4294967295(+x: U32) -> U32:
  U32.shln(x, 4294967295n)

@unsafe
def left_dynamic(+x: U32, +n: Nat) -> U32:
  U32.shln(x, n)

@unsafe
def left_annotated(+x: U32) -> U32:
  U32.shln(x, (8n : Nat))

@unsafe
def right_0(+x: U32) -> U32:
  U32.shrn(x, 0n)

@unsafe
def right_1(+x: U32) -> U32:
  U32.shrn(x, 1n)

@unsafe
def right_8(+x: U32) -> U32:
  U32.shrn(x, 8n)

@unsafe
def right_31(+x: U32) -> U32:
  U32.shrn(x, 31n)

@unsafe
def right_32(+x: U32) -> U32:
  U32.shrn(x, 32n)

@unsafe
def right_33(+x: U32) -> U32:
  U32.shrn(x, 33n)

@unsafe
def right_4294967295(+x: U32) -> U32:
  U32.shrn(x, 4294967295n)

@unsafe
def right_dynamic(+x: U32, +n: Nat) -> U32:
  U32.shrn(x, n)

@unsafe
def right_annotated(+x: U32) -> U32:
  U32.shrn(x, (8n : Nat))

