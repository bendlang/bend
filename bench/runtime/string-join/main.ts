// TypeScript twin of main.bend: n lines of the same text joined with a
// separator into one string, then a checksum over the joined text. The
// join is Array.prototype.join, one pass and one copy of each
// character; the Bend side joins the same n lines with String.join,
// whose copies are the head pieces' lengths.
const COUNT = Number(process.argv[2] ?? 3200);

function line(n: number): string {
  return `int ${n} = (a*b) + (c-d);`;
}

const lines: string[] = [];
for (let i = 0; i < COUNT; i++) lines.push(line(i + 1));

const joined = lines.join("\n");

let acc = 0;
for (let i = 0; i < joined.length; i++) acc = (acc + joined.charCodeAt(i)) % 1000000007;

console.log(`${COUNT} ${acc}`);
