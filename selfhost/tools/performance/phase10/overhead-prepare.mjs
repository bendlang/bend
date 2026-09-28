import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';
const [baselineArg,outArg]=process.argv.slice(2);
const baseline=path.resolve(baselineArg),out=path.resolve(outArg),m=await verifyAttempt(baseline);
fs.mkdirSync(out,{recursive:false});
const project=path.join(out,'project');fs.mkdirSync(project);
for(const name of ['src','tools','tests'])fs.cpSync(path.join(m.snapshot.root,name),path.join(project,name),{recursive:true});
const file=path.join(project,'src/core/index.bend'),before=fs.readFileSync(file,'utf8');
const oldChild='      kc(KDef, right, u => index_first(rest), u => h)';
const newChild='      match right:\n        case True{}: index_first(rest)\n        case False{}: h';
const oldFind=`  kc(KDef, String.eq(dk(tree), "Absent"), u => missing(), u =>
    kc(KDef, U32.is_eq(dx(tree), 0),
      u => kc(KDef, U32.is_eq(da(tree), hash), u => index_bucket(dc(tree), name), u => missing()),
      u => index_find(index_child(tree, Bool.not(U32.is_eq(U32.and(hash, dx(tree)), 0))), name, hash, bits)))`;
const newFind=`  index_find_absent(tree, name, hash, bits, String.eq(dk(tree), "Absent"))

@unsafe
def index_find_absent(
  +tree: KDef,
  +name: String,
  +hash: U32,
  +bits: U32,
  +absent: Bool,
) -> KDef:
  match absent:
    case True{}: missing()
    case False{}:
      index_find_leaf(tree, name, hash, bits, U32.is_eq(dx(tree), 0))

@unsafe
def index_find_leaf(
  +tree: KDef,
  +name: String,
  +hash: U32,
  +bits: U32,
  +leaf: Bool,
) -> KDef:
  match leaf:
    case True{}:
      index_find_hash(tree, name, U32.is_eq(da(tree), hash))
    case False{}:
      index_find(index_child(tree, Bool.not(U32.is_eq(U32.and(hash, dx(tree)), 0))), name, hash, bits)

@unsafe
def index_find_hash(
  +tree: KDef,
  +name: String,
  +same: Bool,
) -> KDef:
  match same:
    case True{}: index_bucket(dc(tree), name)
    case False{}: missing()`;
assert.equal(before.split(oldChild).length,2);assert.equal(before.split(oldFind).length,2);
const after=before.replace(oldChild,newChild).replace(oldFind,newFind);fs.writeFileSync(file,after);
const config=path.join(out,'workflow.json');
fs.writeFileSync(config,JSON.stringify({project,upstream:path.resolve('selfhost/.bootstrap/upstream-phase8'),jobs:1,cpu:'3',profile:'equality',timeoutMs:30000},null,2)+'\n');
fs.writeFileSync(path.join(out,'before-index.bend'),before);
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({kind:'phase10-index-branch-source-candidate',baselineApi:m.api,inputs:[identity(import.meta.filename),identity(path.join(baseline,'attempt.json'))],modified:identity(file),edits:[{before:oldChild,after:newChild},{before:oldFind,after:newFind}],lineDelta:after.split('\n').length-before.split('\n').length,config:identity(config)},null,2)+'\n');
console.log(JSON.stringify({project,config,file}));
