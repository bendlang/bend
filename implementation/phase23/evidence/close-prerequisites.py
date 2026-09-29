#!/usr/bin/env python3
"""Bind the final restore routes to Git, actual capsules and independent recovery.

Does not replay experiments or bundle external Node/Clang/system dependencies.
Run: python3 implementation/phase23/evidence/close-prerequisites.py NEW_RECEIPT
"""
import collections
import hashlib
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent

def identity(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda:stream.read(1024*1024),b''):h.update(block)
    return {'file':str(path.relative_to(ROOT)),'bytes':path.stat().st_size,'sha256':h.hexdigest()}

def main():
    assert len(sys.argv)==2,'Supply a new receipt filename'
    output=Path(sys.argv[1]);output=output if output.is_absolute() else ROOT/output
    assert not output.exists(),'Never overwrite an earlier receipt'
    source=HERE.parent/'evidence-prerequisites-closed.json'
    inventory=json.loads(source.read_text())
    manifest_path=HERE/'manifest.json';manifest=json.loads(manifest_path.read_text())
    recovery_path=HERE/'recovery-01.json';recovery=json.loads(recovery_path.read_text())
    assert inventory['producersDeclaredClosed'] and not inventory['explicitCaptureRequired']
    assert inventory['productionCommit']=='ab246cdd24e7695a14d3b725d5323b95c5f5892b'
    assert recovery['complete'] and recovery['pass']
    assert recovery['manifest']['sha256']==identity(manifest_path)['sha256']
    assert recovery['archive']['sha256']==manifest['archive']['sha256']
    assert recovery['originalProducerClosure']['membershipExact']
    assert recovery['originalProducerClosure']['allBytesModesTypesExact']
    members={row['path']:row for row in manifest['members']}
    metadata=[];archives=[];seen=set()
    def check(path,sha,size=None,archive=False):
        path=path if path.is_absolute() else ROOT/path
        key=(str(path),sha)
        if key in seen:return
        row=identity(path);assert row['sha256']==sha,(str(path),row['sha256'],sha)
        if size is not None:assert row['bytes']==size,str(path)
        (archives if archive else metadata).append(row);seen.add(key)
    check(HERE/manifest['archive']['file'],manifest['archive']['sha256'],manifest['archive']['bytes'],True)
    for entry in inventory['registry'].values():
        for key in ['manifest','inventory','receipt','successfulHistoricalRecovery']:
            if key in entry:
                row=entry[key];check(Path(row['file']),row['sha256'],row['bytes'])
        directory=(ROOT/entry['manifest']['file']).parent
        for row in entry.get('archives',[]):check(directory/row['path'],row['sha256'],row['bytes'],True)
        if 'archive' in entry:
            row=entry['archive'];check(directory/row['file'],row['sha256'],row['bytes'],True)
        for row in entry.get('externalCapsules',[]):
            check(Path(row['manifest']),row['manifestSha256'])
            check(Path(row['archive']),row['archiveSha256'],row['archiveBytes'],True)
    counts=collections.Counter();capture_bindings=[];production=[];external=[];historical=[]
    for row in inventory['references']:
        route=row['restoration'];kind=route['kind'];counts[kind]+=1
        if kind in ['planned-phase23-byte-alias','planned-phase23-owned-source','planned-phase23-explicit-capture']:
            target=route.get('copyFrom',row['relative']);member=members[target]
            assert member['kind']=='file' and member['sha256']==row['sha256'],target
            capture_bindings.append({'original':row['relative'],'member':target,'sha256':row['sha256']})
        elif kind in ['pinned-upstream-git','fixed-fork-git','phase23-production-git']:
            assert route['contentHashVerifiedNow']
            if kind=='phase23-production-git':production.append({'file':row['relative'],'sha256':row['sha256'],'gitObject':route['gitObject']})
        elif kind=='durable-capsule':
            assert route['matches'] and all(match['capsule'] in inventory['registry'] for match in route['matches'])
        elif kind=='external-toolchain':external.append(row)
        elif kind=='historical-metadata-only-omission':
            assert route['notConsumedByPhase23'] and row['observedOnlyInHistoricalReplay'];historical.append(row)
        else:raise AssertionError(('Unclosed route',kind,row['relative']))
    result={'kind':'phase23-prerequisite-route-closure','complete':True,'pass':True,
            'scope':'All final discovered identities have verified Git/capsule routes or explicitly classified external toolchain/historical metadata status. Phase23 capsule recovered independently. This is not hermetic environment recovery or compiler reexecution.',
            'script':identity(Path(__file__).resolve()),'inventory':identity(source),
            'manifest':identity(manifest_path),'independentRecovery':identity(recovery_path),
            'referenceCount':len(inventory['references']),'referenceKinds':dict(counts),
            'productionCommit':inventory['productionCommit'],'productionGitBindings':production,
            'phase23CapturedBindings':capture_bindings,
            'currentVerifiedCapsuleMetadata':metadata,'currentVerifiedCompressedArchives':archives,
            'compressedArchiveBytes':sum(row['bytes'] for row in archives),
            'externalToolchainsNotBundled':external,'historicalCacheIdentitiesNotConsumed':historical,
            'allPriorCapsulePayloadsReextractedNow':False,
            'priorPayloadVerification':'Existing successful independent recovery receipts remain hash-bound; compressed archives and metadata were rehashed now. Only the Phase23 capsule was independently extracted during this closure.'}
    with output.open('x') as stream:json.dump(result,stream,indent=2);stream.write('\n')
    print(json.dumps({'receipt':str(output),'references':result['referenceCount'],'capturedBindings':len(capture_bindings),'productionBindings':len(production),'metadata':len(metadata),'archives':len(archives),'compressedBytes':result['compressedArchiveBytes'],'pass':True},indent=2))

if __name__=='__main__':main()
