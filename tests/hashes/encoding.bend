# UTF-8 and raw-byte semantics shared by every frontend.
import Base
import ../../bend2/hashes/main.bend as Hashes

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Hashes.SHA256.text("é🐸"))
    IO.print(Hashes.SHA3_256.text("é🐸"))
    IO.print(Hashes.SHA256.hex([256, 511, 4660]))
    IO.print(Hashes.SHA256.text(""))
    IO.print(Hashes.SM3.text(""))

#|9d8bafad8fa43d0daac8df614f7bea107f53f036088d276640ff510067c872b3
#|d7a0299cca8b5bee43488ea6121789b07ac72a17f2a589d1ac589e6ae26b410f
#|65d848193fae54796276b8087db2cec8b2e5f2e8d353e226359493d3ed2b7365
#|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
#|1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b
