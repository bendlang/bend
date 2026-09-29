from pathlib import Path
import json, hashlib, re
root=Path.cwd();phase=root/'selfhost/build/phase16';out=phase/'checker-compact-final-key-probe-01';out.mkdir()
final=phase/'compact-final-build-01/equality/api.mjs';donor=phase/'checker-key-json-build-02/equality/api.mjs';original=final.read_bytes();text=original.decode();donor_text=donor.read_text()
sha=lambda b:hashlib.sha256(b).hexdigest()
assert sha(original)=='35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315'
wrappers=[]
for name in ['term_key','sp_keys','sp_len','sk_quote']:
 lines=[l for l in donor_text.splitlines() if l.startswith('  "'+name+'": run_lib(')];assert len(lines)==1
 assert len(re.findall(r'^function \$'+name+r'\$\(',text,re.M))==1
 assert len(re.findall(r'^function \$'+name+r'\$\(',donor_text,re.M))==1
 wrappers.append(lines[0])
suffix='\n// Instrumentation only: unchanged checked encoder wrappers over final compiled helpers.\nexport const phase16_key_probe = {\n'+'\n'.join(wrappers)+'\n};\n'
extended=original+suffix.encode();p=out/'probe-api.mjs';p.write_bytes(extended);assert p.read_bytes()[:len(original)]==original
identity=lambda p:{'file':str(p),'sha256':sha(p.read_bytes()),'bytes':p.stat().st_size}
manifest={'kind':'phase16-final-api-named-probe-extension','productionAPI':identity(final),'wrapperDonorAPI':identity(donor),'productionAttempt':identity(phase/'compact-final-build-01/attempt.json'),'wrapperDonorAttempt':identity(phase/'checker-key-json-build-02/attempt.json'),'probeAPI':identity(p),'originalPrefixBytes':len(original),'exactOriginalPrefix':True,'appendedSuffix':suffix,'namedExport':'phase16_key_probe','unchangedWrapperLines':wrappers,'internalTargets':['term_key','sp_keys','sp_len','sk_quote'],'tool':identity(Path(__file__)),'scope':'Probe-only appended named export; no compiler rebuild, production export change, production API mutation, or claim that the extended probe has the original API hash.'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps({'prefixBytes':len(original),'probeSha256':sha(extended),'productionSha256':sha(original)}))
