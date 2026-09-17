// TypeScript twin of main.bend: same template generator into a JS
// string, same tokenizer over its char codes (nested loops, one per
// token class), same checksum, single-threaded. Wrapping u32
// arithmetic rides Math.imul and >>> 0.
const DEPTH = 23;
const TPL = "i = ( n o i ) o ( n o i ) o ( n o i ) ;";

function prng(x: number): number {
  const b = (x ^ (x << 13)) >>> 0;
  const d = (b ^ (b >>> 17)) >>> 0;
  return (d ^ (d << 5)) >>> 0;
}
function seed(i: number): number {
  return prng(Math.imul(i + 1, 2654435761) >>> 0);
}
function salt(s: number, k: number): number {
  return prng((s ^ Math.imul(k, 2654435761)) >>> 0);
}

// one line of source from the template
function gen(s: number): string {
  let line = "";
  for (let k = 0; k < TPL.length; k++) {
    let t = salt(s, k);
    const c = TPL[k];
    if (c === "i") {
      for (let j = 1 + (t & 7); j; j--) {
        t = prng(t);
        line += String.fromCharCode(97 + (t % 26));
      }
    } else if (c === "n") {
      for (let j = 1 + (t % 6); j; j--) {
        t = prng(t);
        line += String.fromCharCode(48 + (t % 10));
      }
    } else if (c === "o") {
      line += "+-*/"[t & 3];
    } else {
      line += c;
    }
  }
  return line;
}

function mix(acc: number, kind: number, x: number): number {
  const tok = (Math.imul(kind, 40503) + x) >>> 0;
  return (Math.imul(acc, 2654435761) ^ tok) >>> 0;
}
function is_letter(c: number): boolean {
  return c >= 97 && c <= 122;
}
function is_digit(c: number): boolean {
  return c >= 48 && c <= 57;
}

// the tokenizer over one line's char codes
function lex(p: string): number {
  let acc = 0;
  let i = 0;
  const n = p.length;
  while (i < n) {
    const c = p.charCodeAt(i);
    if (is_letter(c)) {
      let h = 2166136261;
      while (i < n && is_letter(p.charCodeAt(i))) {
        h = Math.imul(h ^ p.charCodeAt(i), 16777619) >>> 0;
        i++;
      }
      acc = mix(acc, 1, h);
    } else if (is_digit(c)) {
      let v = 0;
      while (i < n && is_digit(p.charCodeAt(i))) {
        v = (Math.imul(v, 10) + (p.charCodeAt(i) - 48)) >>> 0;
        i++;
      }
      acc = mix(acc, 2, v);
    } else if (c === 32) {
      i++;
    } else {
      acc = mix(acc, 3, c);
      i++;
    }
  }
  return acc;
}

let sum = 0;
for (let i = 0; i < 2 ** DEPTH; i++) {
  sum = (sum + lex(gen(seed(i)))) >>> 0;
}
console.log(sum);
