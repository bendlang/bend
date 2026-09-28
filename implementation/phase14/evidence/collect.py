"""Phase14 adapter: distinguish verified inline source from file references."""
import importlib.util
from pathlib import Path
import re
import sys

sys.dont_write_bytecode = True
legacy_file = Path(__file__).resolve().parents[2] / 'phase8/migration-evidence/collect.py'
spec = importlib.util.spec_from_file_location('phase8_collector', legacy_file)
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)
identity = legacy.identity
original_references = legacy.json_references
original_inventory = legacy.inventory
embedded = {}
expected_reports = {'selfhost/build/phase13/control-selector-bodies-01/report.json': 'fb15db37954395fd054c7800395ca38b8612364be7edb36a02cf511e84ad6cdd', 'selfhost/build/phase13/control-selector-bodies-02/report.json': '34c6c0a262c664fdae9733743dc5e695d208af6fdc937ab9574005681138c1d3', 'selfhost/build/phase13/control-const-bodies-01/report.json': '6ca959b46b9b3fa861893d36e51e25deb26cb50da5c22fa798beb79ffc487036'}
contracts = {
    'selfhost/build/phase13/control-selector-bodies-01/report.json':
        ('phase13-independent-actual-selector-body-identity', r'/(?:baseline|candidate)/\d+/source', 23),
    'selfhost/build/phase13/control-selector-bodies-02/report.json':
        ('phase13-independent-actual-selector-body-identity', r'/(?:baseline|candidate|removed)/\d+/source', 28),
    'selfhost/build/phase13/control-const-bodies-01/report.json':
        ('phase13-independent-actual-const-body-identity', r'/owners/\d+/constants/\d+/source', 10),
}

def references(value, origin, pointer=''):
    # Preserve the legacy pair set and depth-first pointer order without using
    # Python call-stack depth for the compiler's explicit linked-list values.
    if not pointer and origin in contracts:
        if legacy.digest((Path(__file__).resolve().parents[3] / origin).read_bytes()) != expected_reports[origin]:
            raise RuntimeError('Changed byte-pinned historical inline-source report: ' + origin)
        if not isinstance(value, dict) or value.get('kind') != contracts[origin][0]:
            raise RuntimeError('Unexpected inline-source report kind: ' + origin)
    pairs = [('sha256', ('file', 'path', 'canonicalPath', 'source', 'target', 'snapshot')),
             ('apiSha256', ('api', 'apiPath', 'apiFile')),
             ('baseSha256', ('base', 'basePath')),
             ('runtimeSha256', ('runtime', 'runtimePath')),
             ('checkedApiSha256', ('checkedApi', 'checkedApiFile'))]
    pending = [(pointer, value)]
    while pending:
        at, node = pending.pop()
        if isinstance(node, dict):
            for hash_key, path_keys in pairs:
                expected_hash = node.get(hash_key)
                if not isinstance(expected_hash, str) or not legacy.HEX.fullmatch(expected_hash):
                    continue
                for key in path_keys:
                    name = node.get(key)
                    if not isinstance(name, str) or not name or name.startswith(('http:', 'https:')):
                        continue
                    ref = {'report': origin, 'pointer': at + '/' + key, 'path': name, 'sha256': expected_hash}
                    contract = contracts.get(origin)
                    if contract and re.fullmatch(contract[1], ref['pointer']):
                        if at + '/source' != ref['pointer']:
                            raise RuntimeError('Inline-source reference escaped its original row')
                        fields = {'start', 'end', 'sha256', 'source', 'name', 'nearestArrow'} if '/constants/' in at else {'start', 'end', 'sha256', 'source', 'param'}
                        if set(node) != fields:
                            raise RuntimeError('Unexpected inline-source row fields')
                        start, end = node.get('start'), node.get('end')
                        if type(start) is not int or type(end) is not int or not 0 <= start <= end:
                            raise RuntimeError('Invalid inline-source range')
                        blob = name.encode('utf-8')
                        if legacy.digest(blob) != expected_hash:
                            raise RuntimeError('Inline-source hash mismatch: ' + origin + ref['pointer'])
                        embedded[(origin, ref['pointer'])] = {
                            'report': origin, 'pointer': ref['pointer'], 'sha256': expected_hash,
                            'bytes': len(blob), 'start': start, 'end': end,
                            'storage': 'UTF-8 source string retained inside the captured original JSON report',
                        }
                    else:
                        yield ref
            pending.extend((at + '/' + str(key), child) for key, child in reversed(list(node.items())))
        elif isinstance(node, list):
            pending.extend((at + '/' + str(index), node[index]) for index in range(len(node) - 1, -1, -1))

def inventory(root, selection):
    embedded.clear()
    manifest, objects, initial = original_inventory(root, selection)
    for report, (_, _, count) in contracts.items():
        if sum(row['report'] == report for row in embedded.values()) != count:
            raise RuntimeError('Incomplete inline-source audit: ' + report)
    manifest['embeddedSourceReferences'] = [embedded[key] for key in sorted(embedded)]
    manifest['referenceAdapter'] = {
        'file': str(Path(__file__).relative_to(root)), **identity(Path(__file__)),
        'legacyCollector': {'file': str(legacy_file.relative_to(root)), **identity(legacy_file)},
        'traversal': 'Iterative DFS with exactly the legacy hash/path pairs and pointer order; deep compiler books remain fully captured.',
        'scope': 'Only the 61 hash-verified source strings in three byte-pinned historical Phase13 reports; all other reference and byte/mode rules unchanged.',
    }
    manifest['summary']['embeddedSourceReferences'] = len(embedded)
    return manifest, objects, initial

legacy.json_references = references
legacy.inventory = inventory

if __name__ == '__main__':
    legacy.main()
