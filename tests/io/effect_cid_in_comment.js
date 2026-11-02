// The same quote, "CID(...) names no constructor or def", in the JS twin.
function answer(n) {
  return (n + 2) >>> 0;
}

// U+2028 and U+2029 end a JS comment, so the CIDs after them are code: CID(answer);
// CID(answer);
io_eff(CID(answer), answer);
