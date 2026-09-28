// IO
// ==

function io_get_env(name) {
  const value = Object.hasOwn(process.env, name) ? process.env[name] : undefined;
  return value === undefined ? io_fail(2) : io_done(value);
}

io_eff(CID(IO.get_env), io_get_env);
