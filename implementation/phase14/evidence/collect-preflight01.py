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
    if not pointer and origin in contracts:
        if legacy.digest((Path(__file__).resolve().parents[3] / origin).read_bytes()) != expected_reports[origin]:
            raise RuntimeError('Changed byte-pinned historical inline-source report: ' + origin)
        if not isinstance(value, dict) or value.get('kind') != contracts[origin][0]:
            raise RuntimeError('Unexpected inline-source report kind: ' + origin)
    for ref in original_references(value, origin, pointer):
        contract = contracts.get(origin)
        if contract and re.fullmatch(contract[1], ref['pointer']):
            if not isinstance(value, dict) or pointer + '/source' != ref['pointer']:
                raise RuntimeError('Inline-source reference escaped its original row')
            expected = {'start', 'end', 'sha256', 'source', 'name', 'nearestArrow'} if '/constants/' in pointer else {'start', 'end', 'sha256', 'source', 'param'}
            if set(value) != expected:
                raise RuntimeError('Unexpected inline-source row fields')
            start, end = value.get('start'), value.get('end')
            if type(start) is not int or type(end) is not int or not 0 <= start <= end:
                raise RuntimeError('Invalid inline-source range')
            blob = ref['path'].encode('utf-8')
            if legacy.digest(blob) != ref['sha256']:
                raise RuntimeError('Inline-source hash mismatch: ' + origin + ref['pointer'])
            embedded[(origin, ref['pointer'])] = {
                'report': origin, 'pointer': ref['pointer'], 'sha256': ref['sha256'],
                'bytes': len(blob), 'start': start, 'end': end,
                'storage': 'UTF-8 source string retained inside the captured original JSON report',
            }
        else:
            yield ref

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
        'scope': 'Only the 61 hash-verified source strings in three byte-pinned historical Phase13 reports; all other reference and byte/mode rules unchanged.',
    }
    manifest['summary']['embeddedSourceReferences'] = len(embedded)
    return manifest, objects, initial

legacy.json_references = references
legacy.inventory = inventory

if __name__ == '__main__':
    legacy.main()
