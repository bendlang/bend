// IO
// ==

function io_get_env(name) {
  // Node's environment proxy truncates a key at an embedded NUL, so a
  // name like "HOME\0suffix" would answer for "HOME" instead of
  // failing. get_env.c rejects such names before asking the host
  // environment; do the same here so the lanes agree on ENOENT.
  if (name.includes("\0")) return io_fail(2);
  const value = Object.hasOwn(process.env, name) ? process.env[name] : undefined;
  return value === undefined ? io_fail(2) : io_done(value);
}

io_eff(CID(IO.get_env), io_get_env);
