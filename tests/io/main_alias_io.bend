# io (io_main_alias_io): io_type resolves main's type to base's IO
# through def aliases, head by head -- Entry unfolds to Program(Unit),
# Program(Unit) to IO(Unit) -- without stepping INTO IO's own body.
# Before this pin, the head was matched on the spelled type, so a main
# asserted at an alias of IO(T) took the value lane: the interpreter
# printed the term IO.print("alias") and the compiled JS printed
# <closure> -- the effects of a legal IO program silently never ran,
# and the two lanes diverged. Now both lanes run the event loop.
import Base

law Program:
  for -A: Type
  Type

def Program(A):
  IO(A)

law Entry:
  Type

def Entry():
  Program(Unit)

law main:
  Entry

def main():
  do IO<Unit>:
    u : Unit <- IO.print("alias")
    IO.print("runs")

#|alias
#|runs
