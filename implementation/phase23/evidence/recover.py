#!/usr/bin/env python3
"""Independently restore and audit the Phase23 capsule in a new directory.

This does not run compiler experiments or restore external prerequisites.
Usage: python3 implementation/phase23/evidence/recover.py CAPSULE DEST RECEIPT
All three paths are explicit; DEST and RECEIPT must not already exist.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import tarfile
import time

def sha256(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda:stream.read(1024*1024),b''):h.update(block)
    return h.hexdigest()

def identity(path):
    return {'file':str(path),'bytes':path.stat().st_size,'sha256':sha256(path)}

def member_row(path,root):
    s=path.lstat()
    kind='symlink' if stat.S_ISLNK(s.st_mode) else 'directory' if stat.S_ISDIR(s.st_mode) else 'file' if stat.S_ISREG(s.st_mode) else 'unsupported'
    row={'path':path.relative_to(root).as_posix(),'kind':kind,'mode':stat.S_IMODE(s.st_mode)}
    if kind=='file':row.update(bytes=s.st_size,sha256=sha256(path))
    if kind=='symlink':row['target']=os.readlink(path)
    return row

def safe_name(name):
    p=PurePosixPath(name)
    assert name and not p.is_absolute() and '..' not in p.parts and str(p)==name, name
    return p

def ensure_parents(path,root):
    for parent in reversed(path.parents):
        if parent==root or root in parent.parents:
            if parent.exists() or parent.is_symlink():
                assert parent.is_dir() and not parent.is_symlink(), str(parent)
            else:parent.mkdir(mode=0o755)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capsule');parser.add_argument('destination');parser.add_argument('receipt')
    parser.add_argument('--original-root',help='Also recheck every current producer member against the manifest')
    args=parser.parse_args()
    capsule=Path(args.capsule).resolve();dest=Path(args.destination).absolute();receipt=Path(args.receipt).absolute()
    assert not dest.exists() and not dest.is_symlink(), 'Destination already exists'
    assert not receipt.exists(), 'Receipt already exists'
    report={'kind':'phase23-independent-capsule-recovery','complete':False,'pass':False,
            'started':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
            'script':identity(Path(__file__).resolve()),'destination':str(dest),
            'externalPrerequisitesRecovered':False,'compilerExperimentsReexecuted':False,
            'scope':'Every archive member restored and audited independently for names, bytes, mode and type; no new compiler result or external closure claim.'}
    try:
        manifest_path=capsule/'manifest.json';report['manifest']=identity(manifest_path)
        manifest=json.loads(manifest_path.read_text());assert manifest['kind']=='phase23-closed-evidence-capsule'
        archive_name=manifest['archive']['file'];safe_name(archive_name)
        assert len(PurePosixPath(archive_name).parts)==1
        archive=capsule/archive_name;report['archive']=identity(archive)
        assert report['archive']['bytes']==manifest['archive']['bytes']
        assert report['archive']['sha256']==manifest['archive']['sha256']
        expected={}
        for row in manifest['members']:
            safe_name(row['path']);assert row['path'] not in expected
            assert row['kind'] in ['file','directory','symlink']
            expected[row['path']]=row
        scaffolds=set()
        for name in expected:
            for parent in PurePosixPath(name).parents:
                if str(parent)!='.' and str(parent) not in expected:scaffolds.add(str(parent))
        dest.mkdir(mode=0o755);seen=set();hardlinks=[]
        with tarfile.open(archive,'r|xz') as tar:
            for member in tar:
                name=member.name;safe_name(name)
                assert name not in seen and name in expected, name
                seen.add(name);row=expected[name];target=dest/name
                ensure_parents(target,dest)
                assert stat.S_IMODE(member.mode)==row['mode'], name
                if member.isdir():
                    assert row['kind']=='directory', name
                    target.mkdir(mode=0o755,exist_ok=True)
                    assert target.is_dir() and not target.is_symlink(), name
                elif member.issym():
                    assert row['kind']=='symlink' and member.linkname==row['target'], name
                    assert not target.exists() and not target.is_symlink(), name
                    os.symlink(member.linkname,target)
                elif member.islnk():
                    # Tar hard links represent ordinary files in the source inventory.
                    linked=safe_name(member.linkname)
                    assert row['kind']=='file' and str(linked) in expected
                    assert expected[str(linked)]['kind']=='file'
                    hardlinks.append((name,str(linked)))
                else:
                    assert member.isfile() and row['kind']=='file', name
                    assert member.size==row['bytes'], name
                    src=tar.extractfile(member);assert src is not None
                    with target.open('xb') as out:
                        for block in iter(lambda:src.read(1024*1024),b''):out.write(block)
                    os.chmod(target,row['mode'])
        assert seen==set(expected), sorted(set(expected)-seen)[:10]
        while hardlinks:
            pending=[];progress=False
            for name,source in hardlinks:
                origin=dest/source
                if origin.is_file() and not origin.is_symlink():
                    os.link(origin,dest/name);progress=True
                else:pending.append((name,source))
            assert progress, pending
            hardlinks=pending
        for name,row in sorted(expected.items(),key=lambda x:-len(PurePosixPath(x[0]).parts)):
            if row['kind']=='directory':os.chmod(dest/name,row['mode'])
        actual={}
        for directory,dirs,files in os.walk(dest,followlinks=False):
            for name in dirs+files:
                path=Path(directory)/name;row=member_row(path,dest);actual[row['path']]=row
        assert set(actual)==set(expected)|scaffolds, {'missing':sorted(set(expected)-set(actual))[:10],'extra':sorted(set(actual)-set(expected)-scaffolds)[:10]}
        for name,row in expected.items():assert actual[name]==row, {'expected':row,'actual':actual[name]}
        assert all(actual[name]['kind']=='directory' for name in scaffolds)
        if args.original_root:
            original_root=Path(args.original_root).resolve();original={}
            for name in manifest['roots']:
                safe_name(name);path=original_root/name
                row=member_row(path,original_root);original[row['path']]=row
                if path.is_dir() and not path.is_symlink():
                    for directory,dirs,files in os.walk(path,followlinks=False):
                        for child in dirs+files:
                            row=member_row(Path(directory)/child,original_root);original[row['path']]=row
            assert set(original)==set(expected), {'missingOriginals':sorted(set(expected)-set(original))[:10],'extraOriginals':sorted(set(original)-set(expected))[:10]}
            for name,row in expected.items():assert original[name]==row, {'expected':row,'currentOriginal':original[name]}
            report['originalProducerClosure']={'root':str(original_root),'members':len(original),'membershipExact':True,'allBytesModesTypesExact':True}
        report.update({'complete':True,'pass':True})
        report.update(members=len(expected),
                      files=sum(r['kind']=='file' for r in expected.values()),
                      directories=sum(r['kind']=='directory' for r in expected.values()),
                      symlinks=sum(r['kind']=='symlink' for r in expected.values()),
                      fileBytes=sum(r.get('bytes',0) for r in expected.values()),
                      requiredAncestorDirectories=sorted(scaffolds),
                      restoredInventorySha256=hashlib.sha256(json.dumps([actual[n] for n in sorted(expected)],sort_keys=True,separators=(',',':')).encode()).hexdigest(),
                      archiveMembersExact=True,restoredMembersExact=True,allBytesModesTypesExact=True,
                      restoredTreeRetained=True)
    except Exception as error:
        report['error']={'type':type(error).__name__,'message':str(error)}
    report['finished']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
    with receipt.open('x') as out:json.dump(report,out,indent=2);out.write('\n')
    print(json.dumps(report,indent=2))
    if not report['pass']:raise SystemExit(1)

if __name__=='__main__':main()
