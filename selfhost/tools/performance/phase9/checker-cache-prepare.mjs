// Isolate one diagnostic cache change against the tested P9-002 combined source.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const [baselineArg,outputArg,selectionArg,upstreamArg]=process.argv.slice(2);
const baseline=fs.realpathSync(baselineArg),output=path.resolve(outputArg),upstream=fs.realpathSync(upstreamArg);
fs.mkdirSync(output,{recursive:false});
const project=path.join(output,'project');fs.cpSync(baseline,project,{recursive:true});
const file=path.join(project,'src/diagnostic/produce.bend'),before=fs.readFileSync(file,'utf8');
let after=before;
const edits=[
 ['  dg_suffix_events(book, check_declarations(book, book_cached(Nil{}, norm_max_book(book))), Nil{}, book, origins)',
  '  dg_seed_books(book, Nil{}, origins, book_cached(Nil{}, norm_max_book(book)))'],
 ['u => dg_prefix_seed(book, validated, check_declarations(book, book_cached(Nil{}, norm_max_book(book))), Nil{}, book, origins)',
  'u => dg_seed_books(book, validated, origins, book_cached(Nil{}, norm_max_book(book)))'],
 ['@unsafe\ndef dg_quant_error(message, name, allowed, used):',
  'law dg_seed_books:\n  for +book: List<&2, KDef>\n  for +validated: List<&2, KDef>\n  for +origins: List<&2, DOrigin>\n  for +seed: List<&2, KDef>\n  DResult\n\n# The immutable empty cache seeds independent declaration and event indexes.\n@unsafe\ndef dg_seed_books(book, validated, origins, seed):\n  dg_prefix_seed(book, validated, check_declarations(book, seed), seed, book, origins)\n\n@unsafe\ndef dg_quant_error(message, name, allowed, used):'],
];
for(const [from,to] of edits){if(after.split(from).length!==2)throw Error('Nonunique source edit');after=after.replace(from,to);}
fs.writeFileSync(file,after);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const modules=JSON.parse(fs.readFileSync(path.join(project,'src/compiler.json'))).modules.map(file=>({file,baseline:sha(fs.readFileSync(path.join(baseline,file))),candidate:sha(fs.readFileSync(path.join(project,file)))}));
const changed=modules.filter(m=>m.baseline!==m.candidate);if(changed.length!==1||changed[0].file!=='src/diagnostic/produce.bend')throw Error('Unexpected source changes');
fs.writeFileSync(path.join(output,'source-manifest.json'),JSON.stringify({kind:'chronological-cache-source',baseline,project,modules,edits,script:{file:import.meta.filename,sha256:sha(fs.readFileSync(import.meta.filename))}},null,2)+'\n');
fs.writeFileSync(path.join(output,'config.json'),JSON.stringify({project,upstream,selection:fs.realpathSync(selectionArg),jobs:1,cpu:'1'},null,2)+'\n');
console.log(JSON.stringify({project,changed}));
