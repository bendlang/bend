#!/usr/bin/env python3
"""Capture the dynamically named installed CLI cache without changing producers."""
import hashlib,json,os,stat,subprocess,tarfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
def identity(p):
 raw=p.read_bytes();return {'file':str(p.relative_to(ROOT)),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
def main():
 report=ROOT/'selfhost/build/phase24/release-smoke-02/checks/report.json';cli=json.loads(report.read_text());assert cli['pass']
 api=ROOT/'selfhost/dist/typed-api.mjs';base=ROOT/'selfhost/dist/base.bend';driver=ROOT/'selfhost/tools/typed-driver.mjs'
 aid,bid=identity(api),identity(base);assert aid['sha256']==cli['apiSha256']
 location=hashlib.sha256(str(base.resolve()).encode()).hexdigest()
 cache=ROOT/'selfhost/build/typed/cache'/('base-'+aid['sha256']+'-'+bid['sha256']+'-'+location+'.json')
 before=identity(cache);data=json.loads(cache.read_text());assert data['compilerSha256']==aid['sha256'] and data['baseSha256']==bid['sha256']
 assert data['sourcePath']==str(base.resolve()) and data['validatedBy']=='check_book'
 node=Path(cli['node']['file']);assert hashlib.sha256(node.read_bytes()).hexdigest()==cli['node']['sha256']
 script='const fs=require("fs"),c=require("crypto"),x=JSON.parse(fs.readFileSync(process.argv[1]));const h=c.createHash("sha256").update(JSON.stringify(x.book)).digest("hex");if(h!==x.bookSha256)throw Error("book hash mismatch");console.log(JSON.stringify({bookSha256:h,version:x.version,validatedBy:x.validatedBy}));'
 command=[str(node),'-e',script,str(cache)];v=subprocess.run(command,capture_output=True,text=True,check=True,timeout=15)
 out=HERE/'cache-supplement-01';out.mkdir()
 row={'path':str(cache.relative_to(ROOT)),'kind':'file','mode':stat.S_IMODE(cache.lstat().st_mode),'bytes':before['bytes'],'sha256':before['sha256']}
 archive=out/'phase24-cli-cache.tar.xz'
 with tarfile.open(archive,'w:xz',preset=3) as tar:tar.add(cache,arcname=row['path'],recursive=False)
 assert identity(cache)==before,'Cache changed during supplement capture'
 manifest={'kind':'phase24-closed-evidence-capsule','roots':[row['path']],'externalExclusions':{'prefixes':[]},'created':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'archive':{'file':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()},'members':[row],'scope':'Supplement to immutable primary Phase24 capsule: current exact installed CLI Base-cache bytes, captured after identifying the dynamic dependency. Does not rewrite old input reports or establish a new compilation.'}
 (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 dependency={'kind':'phase24-installed-cli-cache-dependency','script':identity(Path(__file__).resolve()),'originalCache':before,'cacheMetadata':{k:v for k,v in data.items() if k!='book'},'sourceInputs':[aid,bid,identity(driver),identity(report)],'validation':{'command':command,'exitCode':v.returncode,'stdout':v.stdout,'stderr':v.stderr},'historicalAttribution':'The recorded ordinary CLI commands use this installed project with ambient Bend overrides removed. typed-driver baseCacheInfo derives this exact path; its generated timestamp is within the first CLI invocation and it validates against the unchanged installed API/Base. The cache was not individually hashed in the original CLI report, so this supplement binds current exact bytes and does not retroactively claim an at-run byte measurement.','regeneration':'With the recorded installed release/Node at these canonical paths, node selfhost/tools/typed-driver.mjs --prepare-base checks and regenerates an absent cache. A fresh generated timestamp changes exact cache bytes; retain this supplement for exact restoration.','primaryArchiveUnchanged':True}
 (out/'dependency.json').write_text(json.dumps(dependency,indent=2)+'\n');print(json.dumps({'archive':manifest['archive'],'cache':before},indent=2))
if __name__=='__main__':main()
