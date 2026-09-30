// Actual compiler-component oracle; no timing, compiler invocation or mutation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
export const provenance={source:'selfhost/src/back/js/emit.bend',startLine:91,endLine:130,sourceAtExtractionSha256:'18c6bc0ed2cd5d97b95fbf0d314473ed881de69686e914128d4bd863f36138b5',fragmentSha256:'135e0256faf45898e1120283c11fffdc5c5c723cbbcea5339801b7758a8eade1',scope:'Unedited j_escape, j_escape_char, j_escape_char_on definitions; wrapper additionally constructs strings and computes a codepoint checksum.'};
export function escape(text){return Array.from(text,c=>({34:'\\"',92:'\\\\',10:'\\n',13:'\\r',9:'\\t',0:'\\x00'}[c.codePointAt(0)]??c)).join('');}
export function input(size,seed){return (String.fromCodePoint(65+(seed%26))+'"\\\n\r\t\0λ雪𝄞az09').repeat(size);}
export function expected(size,seed){let sum=seed>>>0;for(const c of escape(input(size,seed)))sum=(sum+c.codePointAt(0))>>>0;return sum;}
export const benchmarkInputs=[{size:32,seed:17},{size:128,seed:18}].map(p=>({...p,expected:expected(p.size,p.seed)}));
export const inputs=[{size:0,seed:0},{size:1,seed:1},{size:8,seed:17},{size:32,seed:18},...benchmarkInputs].map(p=>({...p,expected:expected(p.size,p.seed)}));
export const textInputs=['',Array.from({length:128},(_,i)=>String.fromCodePoint(i)).join(''),'"\\\n\r\t\0','λ雪𝄞','\u007f\u0080\u07ff\u0800\ud7ff\ue000\uffff\u{10000}\u{10ffff}'];
function checkExtraction(){const source=fs.readFileSync(new URL('./compiler-escape.bend',import.meta.url),'utf8');const first=source.indexOf('@unsafe\ndef j_escape(\n'),end=source.indexOf('\n# Wrapper only:',first);assert.ok(first>=0&&end>first);assert.equal(createHash('sha256').update(source.slice(first,end)).digest('hex'),provenance.fragmentSha256);}
export async function check(moduleFile){checkExtraction();const file=fs.realpathSync(moduleFile),bytes=fs.readFileSync(file);const a=(await import(pathToFileURL(file))).default;const observations=[];for(const text of textInputs){const result=a.j_escape(text);assert.equal(result,escape(text));observations.push({export:'j_escape',text,result});}for(const p of inputs){const result=a.bench(p.size,p.seed);assert.equal(result,p.expected);assert.equal(a.escape_text(p.size,p.seed),escape(input(p.size,p.seed)));observations.push({...p,result});}return {file,sha256:createHash('sha256').update(bytes).digest('hex'),pass:true,observations};}
if(process.argv[1]&&path.resolve(process.argv[1])===import.meta.filename){if(process.argv.length===2){checkExtraction();console.log(JSON.stringify({provenance,inputs,benchmarkInputs,textInputs},null,2));}else{const results=[];for(const file of process.argv.slice(2))results.push(await check(file));console.log(JSON.stringify({provenance,results},null,2));}}
