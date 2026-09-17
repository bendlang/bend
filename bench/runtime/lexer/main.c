// Native C twin of main.bend: same generator (the template expanded
// placeholder by placeholder from a salted xorshift stream), same
// tokenizer (identifier by FNV-1a, number in decimal, operator or
// punctuation by its code, spaces skipped), same checksum (tokens
// folded in order per line, lines summed), single-threaded. Each line
// lives in one stack byte buffer, and the tokenizer runs as nested
// loops over it, one inner loop per token class: the same work as
// main.bend's mode machine, one classification and one arithmetic
// step per byte, one mix per token.
#include <stdint.h>
#include <stdio.h>

#ifndef DEPTH
#define DEPTH 23
#endif

static const char TPL[] = "i = ( n o i ) o ( n o i ) o ( n o i ) ;";

static uint32_t prng(uint32_t x) {
  uint32_t b = x ^ (x << 13);
  uint32_t d = b ^ (b >> 17);
  return d ^ (d << 5);
}
static uint32_t seed(uint32_t i) { return prng((i + 1u) * 2654435761u); }
static uint32_t salt(uint32_t s, uint32_t k) {
  return prng(s ^ (k * 2654435761u));
}

// one line of source from the template; answers its length
static uint32_t gen(uint32_t s, char *buf) {
  uint32_t n = 0;
  for (uint32_t k = 0; TPL[k]; k++) {
    uint32_t t = salt(s, k);
    switch (TPL[k]) {
    case 'i':
      for (uint32_t j = 1 + (t & 7); j; j--) {
        t = prng(t);
        buf[n++] = (char)('a' + t % 26);
      }
      break;
    case 'n':
      for (uint32_t j = 1 + t % 6; j; j--) {
        t = prng(t);
        buf[n++] = (char)('0' + t % 10);
      }
      break;
    case 'o':
      buf[n++] = "+-*/"[t & 3];
      break;
    default:
      buf[n++] = TPL[k];
    }
  }
  return n;
}

static uint32_t mix(uint32_t acc, uint32_t kind, uint32_t x) {
  return (acc * 2654435761u) ^ (kind * 40503u + x);
}
static int is_letter(char c) { return c >= 'a' && c <= 'z'; }
static int is_digit(char c) { return c >= '0' && c <= '9'; }

// the tokenizer over one line's bytes
static uint32_t lex(const char *p, uint32_t n) {
  uint32_t acc = 0;
  uint32_t i = 0;
  while (i < n) {
    char c = p[i];
    if (is_letter(c)) {
      uint32_t h = 2166136261u;
      while (i < n && is_letter(p[i])) {
        h = (h ^ (uint32_t)p[i]) * 16777619u;
        i++;
      }
      acc = mix(acc, 1, h);
    } else if (is_digit(c)) {
      uint32_t v = 0;
      while (i < n && is_digit(p[i])) {
        v = v * 10 + (uint32_t)(p[i] - '0');
        i++;
      }
      acc = mix(acc, 2, v);
    } else if (c == ' ') {
      i++;
    } else {
      acc = mix(acc, 3, (uint32_t)c);
      i++;
    }
  }
  return acc;
}

int main(void) {
  char buf[128];
  uint32_t sum = 0;
  for (uint32_t i = 0; i < (1u << DEPTH); i++) {
    sum += lex(buf, gen(seed(i), buf));
  }
  printf("%u\n", sum);
}
