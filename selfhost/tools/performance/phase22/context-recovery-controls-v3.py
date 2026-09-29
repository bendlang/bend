#!/usr/bin/env python3
"""Exercise actual v2 recovery; keep every tiny capsule and raw result."""
from pathlib import Path
import copy, difflib, gzip, hashlib, io, json, lzma, os, stat, subprocess, sys, tarfile
R = Path(__file__).resolve().parents[4]
O = Path(sys.argv[1]).resolve(); O.mkdir()
TOOL = R/'selfhost/tools/performance/phase22/context-recover-v3.py'
COMMIT = 'a784e0e1a0de1ee085cc188ca0f1f19038679bdb'
ARCHIVE_FORMAT = {'container':'tar','compression':'xz','preset':9,'dictionaryBytes':67108864,'check':'CRC64'}
sha = lambda b: hashlib.sha256(b).hexdigest()
write = lambda p,x: p.write_text(json.dumps(x,indent=2)+'\n')
initial_tool = TOOL.read_bytes(); initial_control = Path(__file__).read_bytes()
old = subprocess.check_output(['git','show',COMMIT+':selfhost/src/core/term.bend'],cwd=R)
new = old+b'\n# Synthetic bounded-recovery control only.\n'
prefix = 'selfhost/build/phase22/policy-source/project/'
source = prefix+'src/core/term.bend'; attempt = 'selfhost/build/phase22/policy-build'
checked = b'// synthetic checked API\n'; derived = b'// synthetic equality-derived API\n'
metadata = {'artifactKind':'derived-b1','api':{'sha256':sha(derived)},'checkedApi':{'sha256':sha(checked)}}
files = {source:new,'fixtures/leaf.bend':b'fixture\n',attempt+'/attempt.json':json.dumps(metadata).encode(),attempt+'/build.json':b'{"complete":true}\n',attempt+'/api.mjs':checked,attempt+'/equality/api.mjs':derived,attempt+'/validation-001/report.json':b'{"complete":true,"pass":true}\n'}
base_rows = [{'path':n,'type':'file','bytes':len(d),'sha256':sha(d),'mode':0o755 if n==source else 0o644} for n,d in files.items()]
link = {'path':'fixtures/a/link.bend','type':'symlink','target':'../leaf.bend','resolvedTarget':'fixtures/leaf.bend','targetSha256':sha(files['fixtures/leaf.bend']),'bytes':len(b'../leaf.bend'),'sha256':sha(b'../leaf.bend'),'mode':0o777}
base_rows.append(link)
def set_link(row, target, resolved, data):
    row.update(type='symlink',target=target,resolvedTarget=resolved,targetSha256=sha(data),bytes=len(os.fsencode(target)),sha256=sha(os.fsencode(target)),mode=0o777)
def link_patch(name, target):
    return f'diff --git a/{name} b/{name}\nnew file mode 120000\n--- /dev/null\n+++ b/{name}\n@@ -0,0 +1 @@\n+{target}\n\\ No newline at end of file\n'
def replace_with_link(name, target):
    deleted = f'diff --git a/{name} b/{name}\ndeleted file mode 100644\n--- a/{name}\n+++ /dev/null\n@@ -1,{len(old.splitlines())} +0,0 @@\n'
    return deleted+''.join('-'+line for line in old.decode().splitlines(True))+link_patch(name,target)
expected_errors = {
    'wrong-codec-metadata':'Unsupported archive format',
    'wrong-gzip-container':'ReadError',
    'negative-inventory-bytes':'Invalid inventory byte count',
    'boolean-inventory-bytes':'Invalid inventory byte count',
    'part-bound':'Declared part payload exceeds bound',
    'wrong-part-member':'Tar member belongs to another archive',
    'file-ancestor':'Member ancestor is a selected file/link',
    'oversized-member':'Oversized member',
    'compressed-bound':'Compressed archive exceeds bound',
    'retained-bound':'Retained payload exceeds bound',
    'source-symlink-patch':'Reconstructed source symlink',
    'unexpected-broken-symlink':'Reconstructed source symlink',
    'source-inventory-symlink':'Source inventory must contain regular files only',
    'report-inside-capsule':'Recovery report must be outside capsule',
}
labels = ['valid-cross-part-link','absolute-member','escaping-link','absolute-link','unselected-target','symlink-ancestor','file-ancestor','hardlink','changed-archive','wrong-mode','wrong-content','duplicate-member','missing-member','derived-lineage','checked-lineage','oversized-member','part-bound','wrong-part-member','changed-source-patch','compressed-bound','retained-bound','source-symlink-patch','unexpected-broken-symlink','source-inventory-symlink','report-inside-capsule','negative-inventory-bytes','boolean-inventory-bytes','wrong-codec-metadata','wrong-gzip-container']
results = []
for label in labels:
    case = O/label; case.mkdir(); folder = case/'capsule'; folder.mkdir()
    rows = copy.deepcopy(base_rows); payload = dict(files)
    if label == 'negative-inventory-bytes': rows[1]['bytes'] = -8000001
    if label == 'boolean-inventory-bytes': rows[1]['bytes'] = True
    if label == 'absolute-member': rows[1]['path'] = '/absolute-escape'
    if label == 'escaping-link': rows[-1]['target'] = '../../../escape'; rows[-1]['resolvedTarget'] = '../escape'
    if label == 'absolute-link': rows[-1]['target'] = '/escape'
    if label == 'unselected-target': rows[-1]['target'] = '../missing'; rows[-1]['resolvedTarget'] = 'fixtures/missing'
    if label == 'symlink-ancestor': rows[1]['path'] = 'fixtures/a/link.bend/child'
    if label == 'file-ancestor':
        rows[1]['path'] = source+'/child'; payload[rows[1]['path']] = files['fixtures/leaf.bend']
        set_link(rows[-1],os.path.relpath(rows[1]['path'],'fixtures/a'),rows[1]['path'],payload[rows[1]['path']])
    if label in ['derived-lineage','checked-lineage']:
        bad = copy.deepcopy(metadata); bad['api' if label=='derived-lineage' else 'checkedApi']['sha256'] = '0'*64
        name = attempt+'/attempt.json'; payload[name] = json.dumps(bad).encode()
        next(r for r in rows if r['path']==name).update(bytes=len(payload[name]),sha256=sha(payload[name]))
    patch = ''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile='a/src/core/term.bend',tofile='b/src/core/term.bend'))
    sentinel = case/'outside-sentinel'; sentinel.write_bytes(b'UNCHANGED external synthetic sentinel\n'); sentinel.chmod(0o640)
    before_sentinel = {'sha256':sha(sentinel.read_bytes()),'mode':stat.S_IMODE(sentinel.lstat().st_mode)}
    if label == 'source-symlink-patch': patch = replace_with_link('src/core/term.bend',str(sentinel))
    if label == 'unexpected-broken-symlink': patch += link_patch('unexpected-link',str(case/'nonexistent-target'))
    if label == 'source-inventory-symlink':
        set_link(rows[0],os.path.relpath('fixtures/leaf.bend',str(Path(source).parent)),'fixtures/leaf.bend',files['fixtures/leaf.bend'])
    bound = 1000000
    if label == 'oversized-member': bound = rows[0]['bytes']
    if label == 'part-bound': bound = sum(r['bytes'] for r in rows[:4])-1
    if label == 'retained-bound':
        bound = 38000000; name = 'fixtures/leaf.bend'; payload[name] = b'R'*8000001
        rows[1].update(bytes=len(payload[name]),sha256=sha(payload[name])); rows[-1]['targetSha256'] = sha(payload[name])
    (folder/'source.patch').write_text(patch)
    inv = {'archiveFormat':ARCHIVE_FORMAT,'members':rows,'finalSource':prefix[:-1],'finalAttempt':attempt,'finalApiSha256':sha(derived),'maxPartPayloadBytes':bound,'maxArchiveBytes':1 if label=='compressed-bound' else 40000000,'sourceBaseline':[{'path':'src/core/term.bend','exists':True,'sha256':sha(old)}],'baselineCommit':COMMIT,'patch':{'path':'source.patch','sha256':sha(patch.encode())}}
    write(folder/'inventory.json',inv); archives = []
    parts = [[0],list(range(1,len(rows)))] if label=='oversized-member' else [list(range(4)),list(range(4,len(rows)))]
    if label == 'duplicate-member': parts[1].append(1)
    for number,indices in enumerate(parts,1):
        archive = folder/f'part-{number:02}.tar.xz'
        with archive.open('xb') as raw, (gzip.GzipFile(filename='',mode='wb',fileobj=raw,compresslevel=6,mtime=0) if label=='wrong-gzip-container' else lzma.LZMAFile(raw,mode='wb',format=lzma.FORMAT_XZ,preset=9,check=lzma.CHECK_CRC64)) as encoded, tarfile.open(fileobj=encoded,mode='w') as tar:
            actual_indices = [4]+indices if label=='wrong-part-member' and number==1 else indices
            for index in actual_indices:
                row = rows[index]
                if label=='missing-member' and index==0: continue
                info = tarfile.TarInfo(row['path']); info.mode = 0o600 if label=='wrong-mode' and index==0 else row['mode']
                if row['type']=='symlink': info.type=tarfile.SYMTYPE; info.linkname=row['target']; tar.addfile(info)
                elif label=='hardlink' and index==1: info.type=tarfile.LNKTYPE; info.linkname=source; tar.addfile(info)
                else:
                    data=payload.get(row['path'],files['fixtures/leaf.bend'])
                    if label=='wrong-content' and index==1: data=b'changed\n'
                    info.size=len(data); tar.addfile(info,io.BytesIO(data))
        archives.append({'path':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive.read_bytes()),'members':[rows[i]['path'] for i in indices]})
    write(folder/'manifest.json',{'complete':True,'captured':True,'archiveFormat':({**ARCHIVE_FORMAT,'compression':'gzip'} if label=='wrong-codec-metadata' else ARCHIVE_FORMAT),'inventory':{'path':'inventory.json','sha256':sha((folder/'inventory.json').read_bytes())},'archives':archives})
    if label=='changed-archive': (folder/'part-01.tar.xz').write_bytes((folder/'part-01.tar.xz').read_bytes()+b'changed')
    if label=='changed-source-patch': (folder/'source.patch').write_text(patch+'changed')
    report_path = folder/'recovery.json' if label=='report-inside-capsule' else case/'recovery.json'
    before_capsule = {p.relative_to(folder).as_posix():sha(p.read_bytes()) for p in folder.iterdir() if p.is_file()}
    run = subprocess.run([sys.executable,str(TOOL),str(folder),str(report_path)],cwd=R,capture_output=True,text=True)
    (case/'stdout').write_text(run.stdout); (case/'stderr').write_text(run.stderr)
    report = json.loads(report_path.read_text()) if report_path.exists() else {'pass':False,'error':run.stderr}
    expected = label=='valid-cross-part-link'
    after_sentinel = {'sha256':sha(sentinel.read_bytes()),'mode':stat.S_IMODE(sentinel.lstat().st_mode)}
    after_capsule = {p.relative_to(folder).as_posix():sha(p.read_bytes()) for p in folder.iterdir() if p.is_file()}
    passed = ((run.returncode==0)==expected and report['pass']==expected and before_sentinel==after_sentinel and before_capsule==after_capsule)
    if label in expected_errors: passed = passed and expected_errors[label] in report.get('error','')
    if label in ['part-bound','retained-bound','compressed-bound','wrong-part-member']: passed = passed and 'extraction' not in report
    if label=='report-inside-capsule': passed = passed and not report_path.exists()
    if expected:
        passed = passed and report['extraction']['files']==len(rows) and len(report['extraction']['parts'])==2 and report['sourceReconstruction']['files']==1 and report['artifacts']['checkedApiSha256']!=report['artifacts']['derivedApiSha256'] and report['extraction']['retainedRegularByteLimit']==8000000
    results.append({'name':label,'pass':bool(passed),'expectedAccepted':expected,'exitCode':run.returncode,'recoveryPass':report['pass'],'error':report.get('error'),'outsideSentinelUnchanged':before_sentinel==after_sentinel,'capsuleUnchanged':before_capsule==after_capsule})
assert TOOL.read_bytes()==initial_tool and Path(__file__).read_bytes()==initial_control
frame_equality = []
for number in [1,2]:
    previous = R/f'selfhost/build/phase22/bounded-recovery-policy-02/valid-cross-part-link/capsule/part-{number:02}.tar.gz'
    current = O/f'valid-cross-part-link/capsule/part-{number:02}.tar.xz'
    before = gzip.decompress(previous.read_bytes()); after = lzma.decompress(current.read_bytes())
    frame_equality.append({'part':number,'equal':before==after,'uncompressedTarBytes':len(before),'tarSha256':sha(before),'previous':str(previous),'previousArchiveSha256':sha(previous.read_bytes()),'currentArchiveSha256':sha(current.read_bytes())})
summary = {'kind':'phase22-synthetic-bounded-recovery-v3-controls','archiveFormat':ARCHIVE_FORMAT,'gzipTarFrameEquality':frame_equality,'complete':True,'pass':all(r['pass'] for r in results) and all(r['equal'] for r in frame_equality),'toolSha256':sha(initial_tool),'controlSha256':sha(initial_control),'rows':results}
write(O/'report.json',summary); print(json.dumps(summary)); sys.exit(0 if summary['pass'] else 1)
