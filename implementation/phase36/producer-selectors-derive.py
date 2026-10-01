#!/usr/bin/env python3
"""Prepare the small full-producer source extension; never edits production."""
from pathlib import Path
import difflib
import hashlib
import json
root=Path(__file__).resolve().parents[2]
region=root/'selfhost/src/back/js/region.bend'
producer=Path(__file__).with_name('producer-proposed.bend')
new_producer=producer.read_text()
producer_changes=[
 ('True{}, "", Con{dn(d), active}, U32.inc(depth),', 'True{}, "", Con{"@producer", Con{dn(d), active}}, U32.inc(depth),'),
 ('da(d), dn(d), Con{dn(d), active}, U32.inc(depth), s)', 'da(d), dn(d), Con{"@producer", Con{dn(d), active}}, U32.inc(depth), s)'),
]
for before,after in producer_changes:
 assert new_producer.count(before)==1,before
 new_producer=new_producer.replace(before,after)
new_producer+='''
# Constructor admission is confined to a whole-graph-proved producer context.
# Existing Ctr emission preserves the original tag/field-array representation.
@unsafe
def j_producer_ctor(+book: List<&2,KDef>, +ty: KTerm, +name: String, +active: List<&2,String>) -> KDef:
  kc(KDef, has_name(active, "@producer") && j_fold_type(book, ty),
    u => lookup(dc(lookup(book, nm(ty))), name), u => j_region_local_ctor(book, ty))
'''
old_region=region.read_text();new_region=old_region
region_changes=[
 ('''        kc(JRegionBuild, Bool.not(keep) && String.eq(tg(t), "Mat") && U32.is_eq(left, 1),
          u => kc(JRegionBuild, j_primitive_type(book, wnf(book, kid(ty, 0)), "Nat"),
            u => j_region_nat_select(book, env, t, ty, at, 0, active, depth, s),
            u => j_region_unpack(book, env, t, ty, at, active, depth, s)), u => j_region_fail(s)))), u => j_region_fail(s))''',
 '''        kc(JRegionBuild, Bool.not(keep) && String.eq(tg(t), "Mat"),
          u => kc(JRegionBuild, j_primitive_type(book, wnf(book, kid(ty, 0)), "Nat") &&
            (U32.is_eq(left, 1) || has_name(active, "@producer")),
            u => j_region_nat_select(book, env, t, ty, at, left, 0, active, depth, s),
            u => kc(JRegionBuild, U32.is_eq(left, 1), u => j_region_unpack(book, env, t, ty, at, active, depth, s),
              u => j_region_fail(s))), u => j_region_fail(s)))), u => j_region_fail(s))'''),
]
for before,after in region_changes:
 assert new_region.count(before)==1,before
 new_region=new_region.replace(before,after)
# The four existing Nat selector functions carry the unchanged remaining arity.
for name in ['j_region_nat_select','j_region_nat_select_on','j_region_nat_match','j_region_nat_first']:
 before='def '+name+'(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +at: U32, +offset: U32,'
 after=before.replace('+at: U32, +offset:', '+at: U32, +left: U32, +offset:')
 assert new_region.count(before)==1
 new_region=new_region.replace(before,after);region_changes.append((before,after))
extra=[
 ('j_region_nat_select_on(book, env, j_strip(t), wnf(book, ty), at, offset, active, depth, j_region_tick(s))','j_region_nat_select_on(book, env, j_strip(t), wnf(book, ty), at, left, offset, active, depth, j_region_tick(s))'),
 ('''      j_region_expr(book, Con{kt("JEnvNat", U32.show(offset), ix(t), at, [wnf(book, kid(ty, 0))]), env},
        kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), "", active, depth, 0, s)''',
 '''      j_region_prefix(book, Con{kt("JEnvNat", U32.show(offset), ix(t), at, [wnf(book, kid(ty, 0))]), env},
        kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), U32.inc(at), U32.sub(left, 1), False{}, "", active, depth, s)'''),
 ('j_region_nat_match(book, env, t, ty, at, offset, active, depth, s)','j_region_nat_match(book, env, t, ty, at, left, offset, active, depth, s)'),
 ('''      j_region_nat_first(book, env, t, ty, at, offset, active, depth,
        j_region_expr(book, env, kid(t, 0), j_arm_type(book, ty, "Zero"), "", active, depth, 0, s))''',
 '''      j_region_nat_first(book, env, t, ty, at, left, offset, active, depth,
        j_region_prefix(book, env, kid(t, 0), j_arm_type(book, ty, "Zero"), U32.inc(at), U32.sub(left, 1), False{}, "", active, depth, s))'''),
 ('j_arm_type(book, ty, "Succ"), at, U32.inc(offset), active, depth, s)', 'j_arm_type(book, ty, "Succ"), at, left, U32.inc(offset), active, depth, s)'),
 ('  +c = j_region_local_ctor(book, ty)\n  kc(JRegionBuild,', '  +c = j_producer_ctor(book, ty, nm(t), active)\n  kc(JRegionBuild,'),
 ('''    kc(Bool, j_region_record(book, ty), u => kc(Bool, root, u => j_fold_terminal_fields(book, ks(t), da(c)),
      u => j_region_field_values(book, ks(t), da(c))), u => True{}), u =>
    j_region_constructor_done(book, t, ty, j_region_args(book, env, ks(t), j_region_local_fields(book, ty), active, depth, level, s))''',
 '''    kc(Bool, j_fold_type(book, ty), u => j_fold_terminal_fields(book, ks(t), da(c)), u =>
      kc(Bool, j_region_record(book, ty), u => kc(Bool, root, u => j_fold_terminal_fields(book, ks(t), da(c)),
        u => j_region_field_values(book, ks(t), da(c))), u => True{})), u =>
    j_region_constructor_done(book, t, ty, j_region_args(book, env, ks(t), j_specialize(book, dt(c), ks(ty)), active, depth, level, s))'''),
]
for before,after in extra:
 assert new_region.count(before)==1,(before,new_region.count(before))
 new_region=new_region.replace(before,after);region_changes.append((before,after))
patch=''
for name,old,new in [('selfhost/src/back/js/region.bend',old_region,new_region),('selfhost/src/back/js/producer.bend',producer.read_text(),new_producer)]:
 patch+=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='a/'+name,tofile='b/'+name))
output=Path(__file__).with_name('producer-selectors.patch')
assert not output.exists(),'preserve previous proposal'
output.write_text(patch)
Path(__file__).with_name('producer-selectors-proposed.bend').write_text(new_producer)
def ident(p):return dict(file=str(p.resolve()),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size)
Path(__file__).with_name('producer-selectors.json').write_text(json.dumps(dict(kind='phase36-private-producer-selectors-proposal',complete=True,
 inputs=[ident(Path(__file__)),ident(region),ident(producer)],output=ident(output),
 producerChanges=[dict(before=a,after=b,count=1)for a,b in producer_changes],
 regionChanges=[dict(before=a,after=b,count=1)for a,b in region_changes],
 producerAddedTail=new_producer[len(new_producer)-len(new_producer.split('def j_producer_ctor')[1])-len('def j_producer_ctor'):],
 lineDelta=len(new_region.splitlines())+len(new_producer.splitlines())-len(old_region.splitlines())-len(producer.read_text().splitlines()),
 scope='Proposed extension atop frozen107line producer. Read/write derivation only; no production source edit, compiler execution or measurement.'),indent=2)+'\n')
print(json.dumps(dict(complete=True,patch=str(output),netAddedLines=len(new_region.splitlines())+len(new_producer.splitlines())-len(old_region.splitlines())-len(producer.read_text().splitlines()))))
