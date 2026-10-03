# Export your own X11 window

This demo opens a 320 × 200 window and exports its reference before the first
frame. It prints `DISPLAY=<display>` and `XID=<decimal ID>`, then keeps the window
open for about 30 seconds or until Close.

Build and run from the checkout in an X11 desktop session. Linux needs
`libx11-dev` and clang 14 or newer.

```sh
bun bend2/main.ts demos/io_window_ref/main.bend -o /tmp/bend-window-ref
/tmp/bend-window-ref
```

While it runs, give the printed values to an exact-ID consumer in another
terminal. For example, with `xwininfo` and `xprop` installed, replace the values
below with the output of this run.

```sh
DISPLAY=:1 xwininfo -id 4194305
DISPLAY=:1 xprop -id 4194305 WM_NAME
```

An Xlib consumer opens the printed display with `XOpenDisplay(display)` and
passes the printed ID to `XGetWindowAttributes` or `XFetchName`. It queries that
exact window without searching by title or enumerating other windows. The
consumer needs access to the same X server.

`Window.export_ref(window)` returns the same owning `Window` beside
`Result<&1, &1, U32 & String, WindowRef>`, including on failure. Success contains
copyable `X11WindowRef{display: String, id: U32}` data. Copying this data keeps no
resource alive. Continue using the returned owner for frames, title changes,
and close.

Native Linux with X11 supports export. macOS, other native backends, and
JavaScript return ENOTSUP. The demo closes the returned owner if export fails.
An exported ID becomes stale after close and may later name a different window.
A display name supplies connection scope, not credentials or a durable server
identity.

Check the pure Close-handling laws against the checkout.

```sh
bun bend2/main.ts demos/io_window_ref/PROOF.bend
bun bend2/main.ts demos/io_window_ref/PROOF.bend --verdict
```

`LAWS.bend` also records the runtime contract. Native identity, ownership,
visibility, and lifetime rely on foreign IO and require runtime reference tests.
These properties are not formal proofs, and neither are properties depending
on `@unsafe` definitions.
