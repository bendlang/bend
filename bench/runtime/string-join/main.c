// Native C twin of main.bend: n lines of the same text joined with a
// separator into one buffer, then a checksum over the joined text. The
// join is one pass over the lines and one pass over the buffer, one
// copy of each character; the Bend side joins the same n lines with
// String.join, whose copies are the head pieces' lengths.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef DEPTH
#define DEPTH 11
#endif

static uint32_t checksum(const char *s, size_t n) {
  uint32_t acc = 0;
  for (size_t i = 0; i < n; i++) acc = (acc + (uint32_t)(unsigned char)s[i]) % 1000000007u;
  return acc;
}

int main(int argc, char **argv) {
  size_t count = (size_t)1 << DEPTH;
  if (argc > 1) count = (size_t)strtoul(argv[1], NULL, 10);
  const char *sep = "\n";
  const size_t sep_len = strlen(sep);
  // one line: "int <n> = (a*b) + (c-d);" -- the same text as the Bend
  // side's line(), with the line number written in place of n.
  char line[64];
  // the SAME line as the Bend side: "int <n> = (a*b) + (c-d);" with the
  // line's own number in it, so the text grows with n and the numbers
  // have different widths.
  size_t widest = 0;
  {
    int written = snprintf(line, sizeof line, "int %zu = (a*b) + (c-d);", count);
    widest = (size_t)written;
  }
  const size_t total = count * widest + (count - 1) * sep_len;
  char *buf = (char *)malloc(total ? total : 1);
  if (!buf) return 1;
  size_t at = 0;
  for (size_t i = 0; i < count; i++) {
    int written = snprintf(line, sizeof line, "int %zu = (a*b) + (c-d);", i + 1);
    size_t line_len = (size_t)written;
    if (i) { memcpy(buf + at, sep, sep_len); at += sep_len; }
    memcpy(buf + at, line, line_len);
    at += line_len;
  }
  printf("%zu %u\n", count, checksum(buf, total));
  free(buf);
  return 0;
}
