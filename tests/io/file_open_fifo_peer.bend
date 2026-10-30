# io (file_open_fifo_peer): a File effect that blocks on a peer goes out
# after what IO.print holds. peer_arm moves stdout onto a pipe read by a
# shell that waits for a line, echoes it, and only then opens a FIFO and
# writes "hi" into it; a "ready" still held at File.open would leave the
# open waiting on a writer that waits on it, and the run would hang.
# peer_done puts stdout back, since the checkup lane shares its process.
import Base

def peer_arm() -> IO(String):
  import "./file_open_fifo_peer.c"
  import "./file_open_fifo_peer.js"

def peer_done() -> IO(Unit):
  import "./file_open_fifo_peer.c"
  import "./file_open_fifo_peer.js"

def got(pair: File & Result<&1, &1, U32 & String, String>) -> IO(String):
  (file, result) = pair
  do IO<String>:
    text : String <- IO.pass(String, result)
    File.close(file)
    return text

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- peer_arm()
    IO.print("ready")
    f : File <- IO.try(File, File.open(path, "r"))
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 64)
    text : String <- got(p)
    Unit <- peer_done()
    IO.print(text)

#|ready
#|hi
