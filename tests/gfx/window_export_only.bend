import Base

def close_export(q: Window & Result<&1, &1, U32 & String, WindowRef>) -> IO(Unit):
  (kept, result) = q
  Window.close(kept)

def export(maybe: Maybe<&1, Window>) -> IO(Unit):
  match maybe:
    case None{}:
      IO.print("no owner to export")
    case Some{window}:
      IO.bind(Window & Result<&1, &1, U32 & String, WindowRef>, Unit,
        Window.export_ref(window), close_export)

def main() -> IO(Unit):
  export(None{})

#|no owner to export
