// IO
// ==

// One line from standard input, without the line break. None{} on EOF.
// The browser playground parks on a virtual fd (-1) when no line is
// buffered: the page is asked for a line and the read resumes on reply.
// Every other host reads file descriptor 0 synchronously.
function io_read_line(k) {
  if (typeof browser !== "undefined" && browser !== null
    && typeof browser.takeLine === "function") {
    const hit = browser.takeLine();
    if (hit !== undefined) {
      return hit === null ? { $: "None" } : { $: "Some", value: hit };
    }
    self.postMessage({ type: "input-request" });
    if (typeof browser.dbg === "function") browser.dbg("read_line parked: requesting a line");
    io_park_on(-1, false, k, () => io_read_line(k));
    return undefined;
  }
  const fs = require("fs");
  const chunks = [];
  const one = Buffer.alloc(1);
  for (;;) {
    let n = 0;
    try {
      n = fs.readSync(0, one, 0, 1);
    } catch (e) {
      return { $: "None" };
    }
    if (n === 0 || one[0] === 10) {
      break;
    }
    chunks.push(one[0]);
  }
  if (chunks.length === 0) {
    return { $: "None" };
  }
  let text = Buffer.from(chunks).toString("utf8");
  if (text.endsWith("\r")) {
    text = text.slice(0, -1);
  }
  return { $: "Some", value: text };
}
