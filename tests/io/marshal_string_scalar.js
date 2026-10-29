function low() {
  return "\uD7FF";
}
function high() {
  return "\uE000";
}
function apex() {
  return "\u{10FFFF}";
}
function edge() {
  return "\uD7FF";
}
function torn() {
  return str_in("a\uD800");
}
function torn_low() {
  return str_in("a\uDC00bcd");
}

io_eff(CID(low), low);
io_eff(CID(high), high);
io_eff(CID(apex), apex);
io_eff(CID(edge), edge);
io_eff(CID(torn), torn);
io_eff(CID(torn_low), torn_low);
