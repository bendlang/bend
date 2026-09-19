// IO
// ==

function io_args() {
  let xs = { $: "Nil" };
  for (let i = cli_args.length; i > 0; i -= 1) {
    xs = { $: "Con", head: cli_args[i - 1], tail: xs };
  }
  return xs;
}
