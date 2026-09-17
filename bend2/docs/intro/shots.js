// stills: node shots.js 6:3.5 7:10  -> shots/b06_3.5.png (beat 6 at 3.5s)
const { createCanvas } = require("canvas");
const fs = require("fs");
const { draw, setCtx, DUR, SCENES, T0 } = require("./render.js");
const cv = createCanvas(1280, 720); setCtx(cv.getContext("2d"));
fs.mkdirSync("shots", { recursive: true });
if (process.argv.length < 3) {
  SCENES.forEach(([n, d], i) => console.log(String(i).padStart(2), T0[i].toFixed(1).padStart(6), d.toFixed(1).padStart(5), n));
  console.log("DUR", DUR.toFixed(1));
}
for (const a of process.argv.slice(2)) {
  const [b, o] = a.split(":").map(Number);
  draw(T0[b] + o);
  const f = `shots/b${String(b).padStart(2, "0")}_${o}.png`;
  fs.writeFileSync(f, cv.toBuffer("image/png")); console.log(f);
}
