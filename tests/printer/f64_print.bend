# a pure main's F64 prints as the literal that reads it back: a point
# before an e, and -0 keeps its sign
import Base

def main() -> F64 & F64 & F64:
  (0.1f64, F64.neg(0.0f64), 1.0e300f64)

#|(0.1f64, -0.0f64, 1.0e+300f64)
