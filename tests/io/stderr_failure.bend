# io (io_stderr_failure): print_err lands off stdout, and a failed
# IO.try (get_env of an unset var) halts the chain: the Halt's
# message prints on stderr (strerror of ENOENT), its code is the
# exit, and the print past the failure never runs.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Unit <- IO.print_err("to-stderr")
    b : Unit <- IO.print("to-stdout")
    e : String <- IO.try(String, IO.get_env("BEND_TEST_NO_SUCH_VAR_09AF"))
    c : Unit <- IO.print("unreached")
    return 0

#|to-stderr
#|to-stdout
#|No such file or directory
#|exit 2
