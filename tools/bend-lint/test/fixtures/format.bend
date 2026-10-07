# bend-lint fixture: format
import Base

type Sample is Data:
  SampleValue{}

def choose(x: Sample,y: Sample) -> Sample:
  x

def text() -> String:
  "a,b=c # still text; escaped quote: \"x,y=z\""

def marker() -> Char:
  '='

def proof(-x: Sample) -> {x==x : Sample}:
  {==}

def main() -> Sample:
  a : Sample=SampleValue{} # preserve,this=comment
  b : Sample  =SampleValue{}
  f : Sample -> Sample=y=>y
  f(choose(a,b))
