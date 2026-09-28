import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
const project=path.resolve(import.meta.dirname,'../../..'),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const source=path.join(project,'build/phase9/integrated-03/snapshot'),candidate=path.join(out,'project');fs.mkdirSync(candidate);
for(const d of ['src','tools','tests'])fs.cpSync(path.join(source,d),path.join(candidate,d),{recursive:true});
const file=path.join(candidate,'src/back/js/validate.bend');let text=fs.readFileSync(file,'utf8');
const changes=[['dt(j_find_ctor(book, nm(t)))','dt(j_layout_ctor(book, wnf(book, ty), nm(t)))'],['j_arm_type(book, ty, nm(t))','j_arm_tel(book, j_specialize(book, dt(j_layout_ctor(book, wnf(book, kid(ty, 0)), nm(t))), ks(wnf(book, kid(ty, 0)))), kid(ty, 1))']];
for(const [a,b] of changes){if(text.split(a).length!==2)throw Error('Nonunique expected source');text=text.replace(a,b);}
text+='\n# Checked constructor terms identify their ADT; its local telescope lookup avoids\n# repeatedly scanning every unrelated definition. Unknown shapes retain fallback.\n@unsafe\ndef j_layout_ctor(\n  +book: List<&2, KDef>,\n  +ty: KTerm,\n  +name: String,\n) -> KDef:\n  +d = lookup(dc(lookup(book, nm(ty))), name)\n  kc(KDef, String.eq(tg(ty), "ADT") && String.eq(dk(d), "Ctr"), u => d, u => j_find_ctor(book, name))\n';fs.writeFileSync(file,text);
const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({baseline:source,changedFile:file,beforeSha256:hash(path.join(source,'src/back/js/validate.bend')),afterSha256:hash(file),scope:'Layout only; checked unique constructor names; malformed duplicate raw books are outside optimized invariant.',changes,helper:'j_layout_ctor'},null,2)+'\n');
fs.writeFileSync(path.join(out,'config.json'),JSON.stringify({project:candidate,upstream:path.join(project,'.bootstrap/upstream-phase8'),profile:'equality',jobs:1,cpu:'2',timeoutMs:30000},null,2)+'\n');
