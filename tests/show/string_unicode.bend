# the printer shows a String of code points past ASCII as the literal
# itself: the edge encodes UTF-8, so the shower no longer spells the
# bytes (its own utf8 encoder is gone, and a lane that kept it would
# print "OlÃ¡")
import Base

law main:
  String

def main():
  "Olá 日本 🙂"

#|"Olá 日本 🙂"
