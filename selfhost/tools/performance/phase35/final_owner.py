"""Append concrete final-image owner acquisitions and controls; execute none."""
from pathlib import Path
import sys
import json


def append_owner(root, here, attempt, out, manifest, additions, command, keep, save, prepared_arg=None):
    owner=out/'owner'; owner.mkdir()
    programs=here.parent/'programs'; prior=here.parent/'phase32'
    baseline=root/'selfhost/build/phase32/attempt-03'
    node=Path(manifest['node']['file'])
    cases={}
    def py(name,tool,args,seconds=300,self_supervised=False):
        keep(tool)
        command('owner-'+name,[sys.executable,tool,*args],seconds,
            'Final-image owner acquisition/control; unchanged semantic assertions.',
            stage='owner',self_supervised=self_supervised)
    def js(name,tool,args,group=None,report=None,seconds=180):
        if tool.exists(): keep(tool)
        command('owner-'+name,[node,'--stack-size=4096','--max-old-space-size=1024',tool,*args],seconds,
            'Final-image owner assertions; final API provenance required.',stage='owner')
        if group: cases.setdefault(group,[]).append(str(report or Path(args[-1])/'report.json'))
    prepared=owner/'programs'
    selected='local-pair,local-fold,raytrace'
    if prepared_arg:
        bundle_file=prepared_arg.resolve()
        if bundle_file.is_dir(): bundle_file=bundle_file/'manifest.json'
        bundle=json.loads(bundle_file.read_text());assert bundle['complete']
        compiler=bundle['roles']['candidate']['compiler']
        assert compiler['kind']=='checked-development-attempt'
        for key in ['api','runtime','base']: assert compiler[key]['sha256']==manifest[key]['sha256']
        assert set(selected.split(',')) <= {c['id'] for c in bundle['cases']}
        receipt=(bundle_file.parent/bundle['preparation']['path']).resolve()
        keep(receipt,bundle['preparation']['sha256']);assert json.loads(receipt.read_text())['complete']
        keep(bundle_file);prepared=bundle_file.parent
    else:
        py('prepare-programs',programs/'prepare.py',['--attempt',attempt,'--out',prepared,
            '--cases',selected,'--node',node,'--cpu','3','--heap-mib','1024','--rss-mib','2048',
            '--available-mib','2048','--timeout','180'],900,True)
    py('vector-cohort',here/'vector-cohort.py',[prepared/'manifest.json',owner/'vector-cohort'])
    for name in ['pair','fold']:
        js(name,here/('vector-'+name+'-controls.mjs'),[owner/'vector-cohort'/name,owner/name],name)
    js('order',here/'vector-inline-order-controls.mjs',[prepared/'modules/local-row.mjs',owner/'order'],'order')
    # Legacy scope/type/value assertions remain the exact Phase32 tools.
    source=owner/'legacy-emissions'; source.mkdir()
    emitter=here.parent/'phase26/emit.mjs'; keep(emitter)
    for name,fixture,reference,control in [
        ('scope','local-scope.bend','scope.mjs','local-scope-controls.mjs'),
        ('vectors','review-local-vectors.bend','vectors.mjs','review-local-vectors.mjs')]:
        keep(prior/fixture); keep(root/'selfhost/build/phase32/emission-02'/reference)
        js('emit-'+name,emitter,[attempt,prior/fixture,source/(name+'.mjs')])
        js(name,prior/control,[owner/name,root/'selfhost/build/phase32/emission-02'/reference,source/(name+'.mjs')],name)
    js('types',prior/'review-local-vector-types.mjs',[attempt,owner/'types'],'types')
    py('vector-fixtures',here/'vector-acquire.py',['--attempt',attempt,'--baseline-attempt',baseline,
        '--node',node,'--cpu','3','--rss-mib','2048','--available-mib','2048',
        '--cases','aliases,nested,counters','--out',owner/'vector-fixtures'],1800,True)
    for name,tool in [('aliases','vector-alias-controls.mjs'),('nested','vector-nested-controls.mjs'),
                      ('counters','vector-counter-fixture-controls.mjs')]:
        js(name,here/tool,[owner/'vector-fixtures'/name,owner/name],name)
    for name,module in [('pair','local-row.mjs'),('fold','local-fold.mjs')]:
        js('counter-hooks-'+name,here/'vector-countdown-controls.mjs',[
            owner/'vector-cohort'/name/'baseline.mjs',prepared/'modules'/module,owner/('counter-hooks-'+name)],'counter-hooks')
    py('region-fixtures',here/'region-acquire.py',['--attempt',attempt,'--baseline-attempt',baseline,
        '--node',node,'--cpu','3','--rss-mib','2048','--available-mib','2048','--out',owner/'region-fixtures'],1200,True)
    js('regions',here/'region-controls.mjs',[owner/'region-fixtures',owner/'regions'],'regions')
    config=owner/'candidate-config.json'
    save(config,dict(candidate={k:manifest[k]['file'] for k in ['api','runtime','base']},
        _provenance=dict(attempt=keep(attempt/'attempt.json'),api=keep(manifest['api']['file'],manifest['api']['sha256']))))
    js('nat-guards',here/'region-nat-guards.mjs',[config,owner/'nat-guards'],'nat-guards')
    py('ray-cohort',here/'region-ray-cohort.py',[prepared/'manifest.json',owner/'ray-cohort'])
    js('ray',owner/'ray-cohort/controls.mjs',[owner/'ray-cohort',owner/'ray'],'ray')
    if 'src/back/js/jpure.bend' in additions:
        py('region-extra-fixtures',here/'region-extra-acquire.py',['--attempt',attempt,'--baseline-attempt',baseline,
            '--node',node,'--cpu','3','--rss-mib','2048','--available-mib','2048',
            '--cases','hit-fields,partial-tree','--out',owner/'region-extra-fixtures'],1200,True)
        js('region-extra',here/'region-extra-controls.mjs',[owner/'region-extra-fixtures',owner/'region-extra'],'regions')
        js('pure-guards',here/'region-pure-guards.mjs',[config,owner/'pure-guards'],'pure-graph')
        # The cohort adapter/control is supplied by the pure-graph owner before
        # final plan creation, so missing tools fail here rather than at runtime.
        py('colf-cohort',here/'region-colf-cohort.py',[prepared/'manifest.json',owner/'colf-cohort'])
        js('colf',owner/'colf-cohort/controls.mjs',[owner/'colf-cohort',owner/'colf'],'pure-graph')
    if 'src/back/js/fold.bend' in additions:
        py('recursive-folds',here/'fold-final-controls.py',[attempt,owner/'recursive-folds'],1800,True)
        cases['recursive-folds']=[str(owner/'recursive-folds/report.json')]
    save(owner/'reports.json',dict(attempt=keep(attempt/'attempt.json'),api=manifest['api'],cases=cases))
    py('close',here/'final-owner-close.py',[out/'plan.json',owner/'reports.json',owner/'report.json'])
    return list(cases)
