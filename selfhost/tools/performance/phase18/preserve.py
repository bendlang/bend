#!/usr/bin/env python3
"""Scoped wave7-style capture. Run only after the explicit final producer freeze."""
from pathlib import Path, PurePosixPath
import difflib, gzip, hashlib, json, os, posixpath, stat, subprocess, sys, tarfile

ROOT = Path(__file__).resolve().parents[4]
PLAN = ROOT/'implementation/phase18/evidence/selection-proposal.json'
FREEZE = ROOT/'implementation/phase18/evidence/root-freeze.json'

def need(ok, message):
    if not ok: raise ValueError(message)

def sha(file):
    h = hashlib.sha256()
    with open(file, 'rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
    return h.hexdigest()

def write(file, value):
    with open(file, 'x') as f: json.dump(value, f, indent=2); f.write('\n')

def safe(name):
    p = PurePosixPath(name)
    need(bool(name) and str(p) == name and name != '.' and not p.is_absolute() and '..' not in p.parts and '.' not in p.parts, 'Unsafe member '+name)
    return p

def freeze():
    p = json.loads(PLAN.read_text()); f = json.loads(FREEZE.read_text())
    need(f.get('authorized') is True and f.get('allProducersClosed') is True, 'Root producer freeze required')
    need(f['finalAttempt'] == p['finalAttempt'] and f['finalApiSha256'] == p['finalApiSha256'], 'Freeze/plan identity mismatch')
    need(p['anchorStatus'] == 'uninstalled-reconstruction-anchor' and f.get('anchorStatus') == p['anchorStatus'], 'Explicit uninstalled anchor freeze required')
    a = json.loads((ROOT/p['finalAttempt']/'attempt.json').read_text())
    need(a['api']['sha256'] == p['finalApiSha256'] and sha(a['api']['file']) == p['finalApiSha256'], 'Final API mismatch')
    for row in f['inputs']:
        need(sha(ROOT/row['path']) == row['sha256'], 'Frozen input changed: '+row['path'])
    return p, f

def prepare(out):
    p, f = freeze(); out.mkdir(); files = {}; selected = []; excluded = []
    def add(file, topic):
        relative = file.relative_to(ROOT).as_posix(); safe(relative)
        need(not any(relative == name or relative.startswith(name+'/') for name in p.get('excludedTrees', [])), 'Explicitly excluded input: '+relative)
        need('.git' not in file.relative_to(ROOT).parts, 'Refuse git metadata')
        need('/tools/performance/phase6/' not in '/'+relative+'/', 'Unreviewed Phase6 source payload')
        if relative in files: need(files[relative] == topic, 'Overlapping topics: '+relative)
        else: files[relative] = topic
    def tree(file, topic):
        need(file.exists() or file.is_symlink(), 'Missing selected input: '+str(file))
        if file.is_symlink() or file.is_file(): add(file, topic); return
        for directory, dirs, names in os.walk(file, followlinks=False):
            for name in list(dirs):
                q = Path(directory)/name
                if q.is_symlink(): add(q, topic); dirs.remove(name)
            for name in names: add(Path(directory)/name, topic)
    for entry in sorted((ROOT/p['phaseRoot']).iterdir()):
        owners = [topic for topic, prefixes in p['topics'].items() if any(entry.name.startswith(prefix) for prefix in prefixes)]
        need(len(owners) <= 1, 'Ambiguous topic: '+entry.name)
        if owners:
            selected.append({'path': entry.relative_to(ROOT).as_posix(), 'topic': owners[0]}); tree(entry, owners[0])
        elif entry.relative_to(ROOT).as_posix() not in sum(p['extraTrees'].values(), []):
            excluded.append({'path': entry.relative_to(ROOT).as_posix(), 'reason': p['excludedTopLevelReason']})
    for topic, names in p['extraTrees'].items():
        for name in names: selected.append({'path': name, 'topic': topic}); tree(ROOT/name, topic)
    for topic, names in p['extraFiles'].items():
        for name in names: tree(ROOT/name, topic)
    for folder in p['closedDocumentationDirectories']:
        for file in sorted((ROOT/folder).iterdir()):
            if file.is_file(): add(file, 'final')
    for name in f.get('additionalFiles', []): tree(ROOT/name, 'final')
    for file in [PLAN, FREEZE, PLAN.parent/'PLAN.md']: add(file, 'final')
    # Selected case records identify exact custom fixture files. Preserve their
    # sibling fixture trees (including imported modules/foreign code), as wave7
    # did, without parsing Bend source or broadening whole experiment families.
    dependencies = []
    for name in list(files):
        document = ROOT/name
        if not (document.name.endswith('selection.json') or document.name.endswith('cases.json')): continue
        pending = [json.loads(document.read_text())]
        while pending:
            value = pending.pop()
            if isinstance(value, list): pending.extend(value)
            elif isinstance(value, dict):
                pending.extend(value.values()); target = value.get('file')
                if not isinstance(target,str) or not target.endswith('.bend'): continue
                target = Path(target)
                if not target.is_absolute(): target = document.parent/target
                target = Path(os.path.abspath(target))
                need(target.is_relative_to(ROOT), 'External custom fixture needs review: '+str(target))
                relative = target.relative_to(ROOT).as_posix()
                if relative.startswith('selfhost/.bootstrap/'): continue
                if relative in files: continue
                need(target.is_file(), 'Missing selected custom fixture: '+relative)
                need(target.parent not in [ROOT,ROOT/'selfhost',ROOT/p['phaseRoot']], 'Overbroad fixture directory')
                dependencies.append({'selection':name,'fixture':relative,'tree':target.parent.relative_to(ROOT).as_posix()})
                tree(target.parent,'final')
    for row in excluded:
        count = sum(name.startswith(row['path']+'/') or name == row['path'] for name in files)
        if count:
            row['includedDescendantFiles'] = count
            row['reason'] = 'Only explicitly referenced custom fixture subtree included; remaining experiment payload is outside scope.'
    rows = []
    for name, topic in sorted(files.items()):
        q = ROOT/name; st = q.lstat(); row = {'path': name, 'topic': topic, 'mode': stat.S_IMODE(st.st_mode)}
        if stat.S_ISLNK(st.st_mode):
            target = os.readlink(q); data = os.fsencode(target)
            row.update(type='symlink', target=target, bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        else:
            need(stat.S_ISREG(st.st_mode), 'Unsupported file type: '+name)
            row.update(type='file', bytes=st.st_size, sha256=sha(q))
        rows.append(row)
    indexed = {r['path']: r for r in rows}; links = {r['path'] for r in rows if r['type'] == 'symlink'}
    for row in rows:
        need(not any(str(a) in links for a in safe(row['path']).parents), 'Symlink ancestor: '+row['path'])
        if row['type'] == 'symlink':
            need(not row['target'].startswith('/'), 'Absolute symlink')
            target = posixpath.normpath(posixpath.join(posixpath.dirname(row['path']), row['target'])); safe(target)
            need(target in indexed and indexed[target]['type'] == 'file', 'Unselected regular link target: '+target)
            need(not any(str(a) in links for a in safe(target).parents), 'Target symlink ancestor')
            row['resolvedTarget'] = target; row['targetSha256'] = indexed[target]['sha256']
    source_prefix = p['finalSource']+'/'; source = [r for r in rows if r['path'].startswith(source_prefix)]
    need(source and all(r['type'] == 'file' for r in source), 'Final source must contain regular files')
    patch = []; baseline = []
    tracked = subprocess.check_output(['git','ls-tree','-rz','--name-only',p['baselineCommit'],'--','selfhost'], cwd=ROOT)
    baseline_names = set(tracked.decode().split('\0'))
    for row in source:
        name = row['path'][len(source_prefix):]
        existed = 'selfhost/'+name in baseline_names
        before = subprocess.check_output(['git','show',p['baselineCommit']+':selfhost/'+name], cwd=ROOT) if existed else b''
        after = (ROOT/row['path']).read_bytes(); baseline.append({'path': name, 'exists': existed, 'sha256': hashlib.sha256(before).hexdigest()})
        if before != after:
            patch.extend(difflib.unified_diff(before.decode().splitlines(True), after.decode().splitlines(True), fromfile='a/'+name if existed else '/dev/null', tofile='b/'+name))
    patch_file = out/'phase17-to-anchor.patch'; patch_file.write_text(''.join(patch))
    inventory = {'kind':'phase18-scoped-inventory','scope':'Selected closed Phase18 uninstalled transport experiments only; the reconstruction anchor is not a release and excluded entries are not claimed preserved.',
      'planSha256':sha(PLAN),'freezeSha256':sha(FREEZE),'baselineCommit':p['baselineCommit'],'finalSource':p['finalSource'],'finalAttempt':p['finalAttempt'],
      'finalApiSha256':p['finalApiSha256'],'anchorStatus':p['anchorStatus'],'selectedRoots':selected,'fixtureDependencies':dependencies,'externalPrerequisites':p['externalPrerequisites'],'excludedPhase18Roots':excluded,'members':rows,'sourceBaseline':baseline,
      'patch':{'path':patch_file.name,'bytes':patch_file.stat().st_size,'sha256':sha(patch_file)},'maxPartPayloadBytes':p['maxPartPayloadBytes'],'maxArchiveBytes':p['maxArchiveBytes']}
    write(out/'inventory.json', inventory)
    print(json.dumps({'prepared':True,'files':len(rows),'bytes':sum(r['bytes'] for r in rows),'excludedRoots':len(excluded),'inventory':str(out/'inventory.json')}))

def capture(out):
    p, f = freeze(); invfile = out/'inventory.json'; inv = json.loads(invfile.read_text())
    need(inv['planSha256'] == sha(PLAN) and inv['freezeSha256'] == sha(FREEZE), 'Preparation identities changed')
    archives = []
    def current(row):
        q = ROOT/row['path']; st = q.lstat(); need(stat.S_IMODE(st.st_mode) == row['mode'], 'Input mode changed')
        if row['type'] == 'symlink': need(q.is_symlink() and os.readlink(q) == row['target'], 'Input link changed')
        else: need(stat.S_ISREG(st.st_mode) and st.st_size == row['bytes'] and sha(q) == row['sha256'], 'Input bytes changed: '+row['path'])
    for row in inv['members']: current(row)
    for topic in p['topics']:
        parts = [[]]; size = 0
        for row in [r for r in inv['members'] if r['topic'] == topic]:
            need(row['bytes'] < inv['maxPartPayloadBytes'], 'Single member exceeds part bound: '+row['path'])
            cost = ((row['bytes']+511)//512+4)*512
            if parts[-1] and size+cost > inv['maxPartPayloadBytes']: parts.append([]); size = 0
            parts[-1].append(row); size += cost
        for number, rows in enumerate(parts, 1):
            if not rows: continue
            archive = out/(topic+'-'+str(number).zfill(2)+'.tar.gz')
            with archive.open('xb') as raw, gzip.GzipFile(filename='', mode='wb', fileobj=raw, compresslevel=6, mtime=0) as zipped, tarfile.open(fileobj=zipped,mode='w') as tar:
                for row in rows:
                    info = tarfile.TarInfo(row['path']); info.uid = info.gid = info.mtime = 0; info.mode = row['mode']
                    if row['type'] == 'symlink': info.type = tarfile.SYMTYPE; info.linkname = row['target']; tar.addfile(info)
                    else:
                        info.size = row['bytes']
                        with (ROOT/row['path']).open('rb') as file: tar.addfile(info, file)
            need(archive.stat().st_size < inv['maxArchiveBytes'], 'Archive exceeds reviewed GitHub bound')
            archives.append({'path':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive),'members':[r['path'] for r in rows]})
    for row in inv['members']: current(row)
    write(out/'manifest.json', {'kind':'phase18-scoped-capture','complete':True,'captured':True,'recoveryPending':True,
      'tool':{'path':str(Path(__file__).relative_to(ROOT)),'sha256':sha(__file__)},'inventory':{'path':invfile.name,'sha256':sha(invfile)},'archives':archives,
      'files':len(inv['members']),'bytes':sum(r['bytes'] for r in inv['members']),'scope':inv['scope']})
    print(json.dumps({'captured':True,'archives':len(archives),'compressedBytes':sum(r['bytes'] for r in archives),'recoveryPending':True}))

if __name__ == '__main__':
    mode, directory = sys.argv[1:]; out = Path(directory).resolve()
    try:
        if mode == 'prepare': prepare(out)
        elif mode == 'capture': capture(out)
        else: raise ValueError('Usage: compact-preserve.py prepare|capture NEW_EVIDENCE_DIRECTORY')
    except Exception as e:
        if out.exists(): write(out/(mode+'-failure.json'), {'complete':False,'error':repr(e),'toolSha256':sha(__file__)})
        raise
