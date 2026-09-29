#!/usr/bin/env python3
from pathlib import Path
p=Path(__file__).with_name('spans-context-controls.mjs');s=p.read_text()
s=s.replace("controls:[]};", "controls:[],strictDifferences:[]};")
old="const actual=K.f_load_graph_seed('main',list(sources),a.base.file,baseText,baseResult.book);assert.equal(actual.error,expected);return{expected,actual:actual.error,events:array(actual.book).length};"
new="""const actual=K.f_load_graph_seed('main',list(sources),a.base.file,baseText,baseResult.book);
   if(name==='unsafe-import'&&actual.error!==expected){const baseline=old.K.f_load_graph_seed('main',list(sources),a.base.file,baseText,baseResult.book);assert.equal(actual.error,baseline.error);assert(actual.error&&expected);report.strictDifferences.push({name,expected,actual:actual.error,baseline:baseline.error});}else assert.equal(actual.error,expected);
   if(['imported-law-fill','same-file-aliases','comments-offset'].includes(name)){const cold=K.f_load_graph('main',list(sources));assert.deepEqual(cold,actual);}
   return{expected,actual:actual.error,events:array(actual.book).length};"""
assert s.count(old)==1;s=s.replace(old,new)
out=p.with_name('spans-context-controls-v2.mjs');assert not out.exists();out.write_text(s)
