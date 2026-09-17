# book_adt filtered a datatype's constructors through the residual
# list with includes (the constructors matched so far), so a match over
# an enum of N constructors cost N x N per arm and N^3 in all: 1000
# arms took 0.7 s, all of it in the filter. the residual is a Set for
# the filter now; 4000 arms check in under a second, and the residual
# keeps declaration order, so an every-arm enum match runs alike
import Base

type Big is Data:
  C0{}
  C1{}
  C2{}
  C3{}
  C4{}
  C5{}
  C6{}
  C7{}
  C8{}
  C9{}
  C10{}
  C11{}
  C12{}
  C13{}
  C14{}
  C15{}
  C16{}
  C17{}
  C18{}
  C19{}
  C20{}
  C21{}
  C22{}
  C23{}
  C24{}
  C25{}
  C26{}
  C27{}
  C28{}
  C29{}
  C30{}
  C31{}
  C32{}
  C33{}
  C34{}
  C35{}
  C36{}
  C37{}
  C38{}
  C39{}
  C40{}
  C41{}
  C42{}
  C43{}
  C44{}
  C45{}
  C46{}
  C47{}
  C48{}
  C49{}
  C50{}
  C51{}
  C52{}
  C53{}
  C54{}
  C55{}
  C56{}
  C57{}
  C58{}
  C59{}
  C60{}
  C61{}
  C62{}
  C63{}
  C64{}
  C65{}
  C66{}
  C67{}
  C68{}
  C69{}
  C70{}
  C71{}
  C72{}
  C73{}
  C74{}
  C75{}
  C76{}
  C77{}
  C78{}
  C79{}
  C80{}
  C81{}
  C82{}
  C83{}
  C84{}
  C85{}
  C86{}
  C87{}
  C88{}
  C89{}
  C90{}
  C91{}
  C92{}
  C93{}
  C94{}
  C95{}
  C96{}
  C97{}
  C98{}
  C99{}

def code(b: Big) -> U32:
  match b:
    case C0{}: 0
    case C1{}: 1
    case C2{}: 2
    case C3{}: 3
    case C4{}: 4
    case C5{}: 5
    case C6{}: 6
    case C7{}: 7
    case C8{}: 8
    case C9{}: 9
    case C10{}: 10
    case C11{}: 11
    case C12{}: 12
    case C13{}: 13
    case C14{}: 14
    case C15{}: 15
    case C16{}: 16
    case C17{}: 17
    case C18{}: 18
    case C19{}: 19
    case C20{}: 20
    case C21{}: 21
    case C22{}: 22
    case C23{}: 23
    case C24{}: 24
    case C25{}: 25
    case C26{}: 26
    case C27{}: 27
    case C28{}: 28
    case C29{}: 29
    case C30{}: 30
    case C31{}: 31
    case C32{}: 32
    case C33{}: 33
    case C34{}: 34
    case C35{}: 35
    case C36{}: 36
    case C37{}: 37
    case C38{}: 38
    case C39{}: 39
    case C40{}: 40
    case C41{}: 41
    case C42{}: 42
    case C43{}: 43
    case C44{}: 44
    case C45{}: 45
    case C46{}: 46
    case C47{}: 47
    case C48{}: 48
    case C49{}: 49
    case C50{}: 50
    case C51{}: 51
    case C52{}: 52
    case C53{}: 53
    case C54{}: 54
    case C55{}: 55
    case C56{}: 56
    case C57{}: 57
    case C58{}: 58
    case C59{}: 59
    case C60{}: 60
    case C61{}: 61
    case C62{}: 62
    case C63{}: 63
    case C64{}: 64
    case C65{}: 65
    case C66{}: 66
    case C67{}: 67
    case C68{}: 68
    case C69{}: 69
    case C70{}: 70
    case C71{}: 71
    case C72{}: 72
    case C73{}: 73
    case C74{}: 74
    case C75{}: 75
    case C76{}: 76
    case C77{}: 77
    case C78{}: 78
    case C79{}: 79
    case C80{}: 80
    case C81{}: 81
    case C82{}: 82
    case C83{}: 83
    case C84{}: 84
    case C85{}: 85
    case C86{}: 86
    case C87{}: 87
    case C88{}: 88
    case C89{}: 89
    case C90{}: 90
    case C91{}: 91
    case C92{}: 92
    case C93{}: 93
    case C94{}: 94
    case C95{}: 95
    case C96{}: 96
    case C97{}: 97
    case C98{}: 98
    case C99{}: 99

def half(b: Big) -> U32:
  match b:
    case C0{}: 0
    case C1{}: 1
    case C2{}: 2
    case C3{}: 3
    case C4{}: 4
    case C5{}: 5
    case C6{}: 6
    case C7{}: 7
    case C8{}: 8
    case C9{}: 9
    case C10{}: 10
    case C11{}: 11
    case C12{}: 12
    case C13{}: 13
    case C14{}: 14
    case C15{}: 15
    case C16{}: 16
    case C17{}: 17
    case C18{}: 18
    case C19{}: 19
    case C20{}: 20
    case C21{}: 21
    case C22{}: 22
    case C23{}: 23
    case C24{}: 24
    case C25{}: 25
    case C26{}: 26
    case C27{}: 27
    case C28{}: 28
    case C29{}: 29
    case C30{}: 30
    case C31{}: 31
    case C32{}: 32
    case C33{}: 33
    case C34{}: 34
    case C35{}: 35
    case C36{}: 36
    case C37{}: 37
    case C38{}: 38
    case C39{}: 39
    case C40{}: 40
    case C41{}: 41
    case C42{}: 42
    case C43{}: 43
    case C44{}: 44
    case C45{}: 45
    case C46{}: 46
    case C47{}: 47
    case C48{}: 48
    case C49{}: 49
    case _: 500

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(code(C0{})))
    Unit <- IO.print(U32.show(code(C57{})))
    Unit <- IO.print(U32.show(code(C99{})))
    Unit <- IO.print(U32.show(half(C49{})))
    IO.print(U32.show(half(C50{})))

#|0
#|57
#|99
#|49
#|500
