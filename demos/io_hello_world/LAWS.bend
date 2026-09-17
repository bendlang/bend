# The law of the hello world: what main prints. A hello world has no
# pure part, so the claim is closed. PROOF.bend must prove it.
import Base
import ./main.bend as Hello

# LAW: main is the printing of "Hello, world!".
law prints_hello:
  {Hello.main() == IO.print("Hello, world!") : IO(Unit)}
