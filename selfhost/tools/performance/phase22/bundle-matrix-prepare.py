"""Freeze a one-driver-file ABI2 bundle matrix; never launches measurements."""
from pathlib import Path
import hashlib,json,difflib,sys
root=Path(__file__).resolve().parents[4]
candidate=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
parent=root/'selfhost/build/phase21/group-range-build-02'
a=json.loads((parent/'attempt.json').read_text());b=json.loads((candidate/'attempt.json').read_text())
assert a['api']['sha256']=='44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0'
assert a['base']['sha256']==b['base']['sha256'];assert a['runtime']['sha256']==b['runtime']['sha256'];assert a['config']['upstream']==b['config']['upstream']
def identity(p):
 p=p.resolve();return {'file':str(p),'canonicalPath':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def hosts(m):return {str(Path(x['frozen']['file']).relative_to(m['snapshot']['root'])):x['frozen'] for x in m['snapshot']['sources'] if str(Path(x['frozen']['file']).relative_to(m['snapshot']['root'])).startswith('tools/')}
ah,bh=hosts(a),hosts(b);assert set(ah)==set(bh);assert len(ah)==35
review_file=root/'implementation/phase22/loader-retirement-review.json';approved=json.loads(review_file.read_text());assert approved['readOnlyScopeApproved'];approved_driver=next(x for x in approved['reviewed'] if x['relative']=='tools/typed-driver.mjs')
assert ah['tools/typed-driver.mjs']['sha256']==approved_driver['before']['sha256'];assert bh['tools/typed-driver.mjs']['sha256']==approved_driver['after']['sha256']
rows=[];changes=[]
for name in sorted(ah):
 x,y=ah[name],bh[name];assert identity(Path(x['file']))['sha256']==x['sha256'];assert identity(Path(y['file']))['sha256']==y['sha256'];rows.append({'relative':name,'before':x,'after':y})
 if x['sha256']!=y['sha256']:changes.append({'relative':name,'before':x,'after':y})
assert [x['relative'] for x in changes]==['tools/typed-driver.mjs']
out.mkdir();patch=out/'typed-driver.patch';patch.write_text(''.join(difflib.unified_diff(Path(changes[0]['before']['file']).read_text().splitlines(True),Path(changes[0]['after']['file']).read_text().splitlines(True),fromfile='a/tools/typed-driver.mjs',tofile='b/tools/typed-driver.mjs')));changes[0]['patch']=identity(patch)
review=out/'host-review.json';review.write_text(json.dumps({'kind':'phase22-exact-abi2-bundle-host-review','pass':True,'members':35,'changes':changes,'rows':rows,'approvedSourceReview':identity(review_file),'programObservationPolicy':'Exact complete result; only verified hostProvenance excluded','scope':'Usable compiler bundle comparison; exactly one ABI2 driver delta, all other34 host members equal. No Bend-only attribution or timing authorization.'},indent=2)+'\n')
profile_request=root/'selfhost/build/phase22/installed-profile-01/request.json';source=Path(json.loads(profile_request.read_text())['source']);old_matrix=root/'selfhost/build/phase22/index-remove-matrix-01/report.json';old=json.loads(old_matrix.read_text());assert identity(source)['sha256']==old['source']['sha256']
config=out/'matrix.json';config.write_text(json.dumps({'baseline':str(parent),'candidate':str(candidate),'source':str(source),'cpu':'0','mode':'measure','hostReview':str(review)},indent=2)+'\n')
inputs=[Path(__file__),parent/'attempt.json',candidate/'attempt.json',source,profile_request,old_matrix,review,config,patch,review_file,root/'design/phase22/final-bundle-cost.md',root/'selfhost/tools/performance/phase22/bundle-check-matrix.mjs',root/'selfhost/tools/performance/phase16/check-matrix-v2.mjs',root/'selfhost/tools/performance/phase8/check-worker.mjs']
(out/'freeze.json').write_text(json.dumps({'complete':True,'timingAuthorized':False,'inputs':[identity(p) for p in inputs],'resources':{'cpu':'0','stackKiB':4096,'heapMiB':4096},'order':['typescript','baseline','candidate','candidate','baseline','typescript'],'requires':'Root exclusive-window grant before launch; gates/owner closure separately recorded. Two samples/image, no edit-loop or emission claim.'},indent=2)+'\n')
print(out)
