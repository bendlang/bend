function word_to_u32(w) {
  let x = 0;
  for (let i = 0; w.$ === "WCon"; i++) {
    x |= Number(w.head) << i;
    w = w.tail;
  }
  return x >>> 0;
}

function u32_to_word(x) {
  let w = {$: "WNil"};
  for (let i = 31; i >= 0; i--) {
    w = {$: "WCon", head: ((x >>> i) & 1) === 1, tail: w};
  }
  return w;
}

function cmp_new(a, b) {
  return {$: a < b ? "LT"
    : a === b ? "EQ" : "GT"};
}

function nat_divmod(a, b) {
  return b === 0 ? {$: "Tuple", fst: 0, snd: a}
    : {$: "Tuple", fst: Math.trunc(a / b), snd: a % b};
}

function nat_chk(n) {
  if (n > 281474976710655) {
    throw "bend: a Nat past the largest immediate 2^48-1";
  }
  return n;
}

function nat_host(n) {
  const int = typeof n === "bigint" || Number.isInteger(n);
  if (int && n >= 0 && n <= 2 ** 53) {
    return Number(n);
  }
  return { [Symbol.toPrimitive]() { throw "bend: a Nat past the largest immediate 2^48-1"; } };
}

function f32_show(x) {
  if (x !== x) {
    return "nan";
  }
  if (!Number.isFinite(x) || Object.is(x, -0)) {
    return x < 0 ? "-inf"
      : x === 0 ? "-0" : "inf";
  }
  let s = "x";
  for (let p = 1; p <= 9 && f32_round(s) !== x; p += 1) {
    s = String(Number(x.toExponential(p - 1)));
  }
  return s;
}

function f32_bits(x) {
  return new Uint32Array(new Float32Array([x]).buffer)[0];
}

function f32_from_bits(u) {
  return new Float32Array(new Uint32Array([u]).buffer)[0];
}

function f32_read(s) {
  const re = /^\s*[+-]?((\d+\.?\d*|\.\d+)(e[+-]?\d+)?|inf(inity)?|nan)$/i;
  const v = f32_round(s.replace(/inf\w*/i, "Infinity"));
  return re.test(s) ? {$: "Some", value: v} : {$: "None"};
}

const f32_round = function f32_round(s        )         {
  const d = Number(s);
  const a = Math.abs(d);
  const f = Math.fround(a);
  const g = 2 * a - Math.min(f, 2 ** 128);
  if (g === f || Math.fround(g) !== g || g === Infinity) {
    return Math.sign(d) * f;
  }
  let k = 0;
  while (a * 2 ** k % 1 !== 0) {
    k += 1;
  }
  const [, i, r, e] = /(\d*)\.?(\d*)(?:e([+-]?\d+))?$/i.exec(s) ;
  const n = Number(e ?? 0) - r.length;
  const x = BigInt(i + r) * 2n ** BigInt(k) * 10n ** BigInt(Math.max(n, 0));
  const y = BigInt(a * 2 ** k) * 10n ** BigInt(Math.max(-n, 0));
  return Math.sign(d) * (x === y || x > y !== g > f ? f : g);
};

function char_new(code) {
  if (code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) {
    throw "bend: " + code + " is not a Unicode scalar value";
  }
  return String.fromCodePoint(code);
}

// Array
// =====

function array_new(d, v) {
  if (d > 31) {
    throw "bend: an array past the deepest block class 31";
  }
  return Array(2 ** d).fill(v);
}

function array_node(a, b) {
  if (a.length !== b.length) {
    throw "bend: runtime fail-stop";
  }
  return a.concat(b);
}

function array_rmw(a, i, f) {
  const at = i % a.length;
  const old = a[at];
  a[at] = f(old);
  return {$: "Tuple", fst: a, snd: old};
}

// Run
// ===

function run_tail(f, x) {
  return {$: "$JMP", f: f.j?.f === f ? f.j : f, x: [x]};
}

function run_clo(j) {
  const f = (x) => run_loop(j(x));
  f.j = j;
  j.f = f;
  return f;
}

function run_loop(r) {
  while (r !== null && typeof r === "object" && r.$ === "$JMP") {
    r = r.f(...r.x);
  }
  return r;
}

function run_lib(f, n) {
  return (...a) => a.length < n ? run_lib((...b) => f(...a, ...b), n - a.length)
    : f(...a);
}

// Effect
// ======

const $0eff = Object.create(null);

function io_eff(k, run, need) {
  if (k in $0eff) {
    throw new Error("bend: two effects register " + k);
  }
  $0eff[k] = { run, need };
}
// Program
// =======

function $f_parse$(_source_0) {
  return $fpe_finish$(_source_0, run_loop($f_tops$(run_loop($f_lex$(_source_0, 1, 0, 0, {$: "Nil"})), {$: "Nil"}, {$: "Nil"}, false)));
}

function $f_load$(_main_0, _sources_0) {
  return $f_loaded_result$(run_loop($f_load_module$(_main_0, "", _sources_0, {$: "Nil"}, {$: "Nil"})));
}

function $f_path_join$(_dir_0, _path_0) {
  return $f_choose$(($Char$is_eq$(($f_head$(_path_0)), "/")), run_clo((_x_0) => {
  return _path_0;
}), run_clo((_x_1) => {
  return (_dir_0 + _path_0);
}));
}

function $f_path_dir$(_path_0) {
  return $f_path_scan$(_path_0, "", "");
}

function $check_book$(_book_0) {
  return $dg_result_error$(run_loop($check_book_diagnostic$(_book_0, {$: "Nil"})));
}

function $annotate_book$(_book_0) {
  return $ka_defs$(run_loop($book_context$(_book_0)), _book_0);
}

function $j_program$(_book_0) {
  return $j_program_selected$(_book_0, _book_0);
}

function $j_library$(_book_0) {
  return $j_library_selected$(_book_0, _book_0);
}

function $j_expr$(_book_0, _env_0, _t_0, _ty_0, _tail_0) {
  const _x_0 = ($String$eq$(($tg$(_t_0)), "Lam"));
  const _x_1 = ($String$eq$(($tg$(_t_0)), "Mat"));
  return $kc$(($Bool$and$((_x_0 || _x_1), ($Bool$not$(($String$eq$(run_loop($j_l_name$(_t_0)), "")))))), run_clo((_x_2) => {
  const _x_3 = run_loop($j_l_capture$(_env_0, {$: "Nil"}));
  const _x_4 = (_x_3 + ")");
  const _x_5 = ($j_quote$(run_loop($j_l_name$(_t_0))));
  const _x_6 = ("](" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  return ("F[" + _x_7);
}), run_clo((_x_8) => {
  return $j_expr_on$(_book_0, _env_0, _t_0, _ty_0, _tail_0, ($tg$(_t_0)));
}));
}

function $j_descriptor$(_book_0, _ty_0, _fuel_0) {
  return $j_desc_kind$(_book_0, run_loop($wnf$(_book_0, _ty_0)), _fuel_0);
}

function $j_io_type$(_book_0, _ty_0) {
  return $kc$(($Bool$and$(($String$eq$(($dk$(run_loop($lookup$(_book_0, "IO")))), "Def")), ($db$(run_loop($lookup$(_book_0, "IO")))))), run_clo((_x_0) => {
  return $j_io_spine$(run_loop($wnf$(run_loop($j_io_shadow$(_book_0)), _ty_0)), 0);
}), run_clo((_x_1) => {
  return false;
}));
}

function $j_modules$(_book_0, _sources_0) {
  if (_sources_0.$ === "Nil") {
    return "";
  } else {
    const _source_0 = _sources_0["head"];
    const _rest_0 = _sources_0["tail"];
    const _x_0 = ($j_modules$(_book_0, _rest_0));
    const _x_1 = ($j_module_exports$(_book_0, ($nm$(_source_0))));
    const _x_2 = ("},registered);})();\n" + _x_0);
    const _x_3 = (_x_1 + _x_2);
    const _x_4 = ($j_source_parts$(($ks$(_source_0))));
    const _x_5 = ("\nreturn Object.assign({" + _x_3);
    const _x_6 = (_x_4 + _x_5);
    const _x_7 = ($j_quote$(($nm$(_source_0))));
    const _x_8 = ("]=(()=>{const registered=Object.create(null);const io_eff=(name,fn)=>{registered[name]=fn;};\n" + _x_6);
    const _x_9 = (_x_7 + _x_8);
    return ("foreignModules[" + _x_9);
  }
}

function $driver_has_main$(_book_0) {
  return $Bool$not$(($String$eq$(($tg$(($dv$(run_loop($lookup$(_book_0, "main")))))), "Absent")));
}

function $driver_is_io$(_book_0) {
  return $j_io_type$(_book_0, ($dt$(run_loop($lookup$(_book_0, "main")))));
}

function $driver_interpret$(_book_0) {
  const _final_0 = run_loop($driver_final$(_book_0, {$: "Nil"}));
  return $kp_show$(run_loop($strong$(_final_0, ($dv$(run_loop($lookup$(_final_0, "main")))))));
}

function $driver_todos$(_book_0) {
  return $driver_count_todos$(run_loop($driver_final$(_book_0, {$: "Nil"})));
}

function $driver_emit_owned$(_book_0) {
  return $driver_owned_names$(_book_0, {$: "Con", "head": "IO", "tail": {$: "Con", "head": "Sigma", "tail": {$: "Con", "head": "String", "tail": {$: "Con", "head": "Word.Con", "tail": {$: "Con", "head": "IO.OP", "tail": {$: "Con", "head": "Result", "tail": {$: "Con", "head": "Maybe", "tail": {$: "Con", "head": "Bool", "tail": {$: "Con", "head": "Unit", "tail": {$: "Con", "head": "Nat", "tail": {$: "Con", "head": "U32", "tail": {$: "Con", "head": "F32", "tail": {$: "Con", "head": "Char", "tail": {$: "Con", "head": "Array", "tail": {$: "Nil"}}}}}}}}}}}}}}});
}

function $specialize_book$(_book_0) {
  return $sp_finish$(run_loop($sp_definitions$(_book_0, ($sp_initial$(run_loop($sp_canonical$(_book_0, {$: "Nil"})), ($norm_max_book$(_book_0)))))));
}

function $specialized_book$(_r_0) {
  const _book_0 = _r_0["book"];
  return _book_0;
}

function $specialized_error$(_r_0) {
  const _error_0 = _r_0["error"];
  return _error_0;
}

function $nc_compile$(_book_0, _runtime_0, _requests_0) {
  const _main_0 = run_loop($lookup$(_book_0, "main"));
  const _owned_0 = run_loop($nv_owned$(_book_0));
  return $nt_choose$(($Bool$not$(($String$eq$(_owned_0, "")))), run_clo((_x_0) => {
  return {$: "NC_Result", "source": "", "error": _owned_0};
}), run_clo((_x_1) => {
  const _x_2 = ($Bool$not$(($String$eq$(($dk$(_main_0)), "Def"))));
  const _x_3 = ($String$eq$(($tg$(run_loop($nc_unann$(($dv$(_main_0)))))), "Absent"));
  return $nt_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return {$: "NC_Result", "source": "", "error": "no main to run"};
}), run_clo((_x_5) => {
  return $nt_choose$(($Bool$and$(($nc_is_io$(_book_0, ($dt$(_main_0)))), ($String$eq$(($tg$(run_loop($nc_unann$(($dv$(_main_0)))))), "Foreign")))), run_clo((_x_6) => {
  return {$: "NC_Result", "source": "", "error": "main must be a filled def: a foreign main cannot anchor IO"};
}), run_clo((_x_7) => {
  const _x_8 = ($norm_max_book$(_book_0));
  return $nt_choose$((_x_8 >= 4000000000), run_clo((_x_9) => {
  return {$: "NC_Result", "source": "", "error": "native source binder IDs overlap the compiler temporary range"};
}), run_clo((_x_10) => {
  return $nc_finish$(_book_0, _runtime_0, _requests_0, run_loop($nc_compile_defs$(_book_0, {$: "Con", "head": "main", "tail": {$: "Nil"}}, {$: "Nil"}, 0, ($nc_bangs_book$(_book_0)))));
}));
}));
}));
}));
}

function $nc_foreign_paths$(_book_0) {
  return $nc_paths_of$(_book_0, run_loop($nc_live_names$(_book_0, {$: "Con", "head": "main", "tail": {$: "Nil"}}, {$: "Nil"})));
}

function $nc_annotation_stops$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $nt_choose$(($nc_native_def$(_d_0)), run_clo((_x_0) => {
  return {$: "Con", "head": ($dn$(_d_0)), "tail": run_loop($nc_annotation_stops$(_rest_0))};
}), run_clo((_x_1) => {
  return $nc_annotation_stops$(_rest_0);
}));
  }
}

function $nc_annotated_context$(_book_0, _annotated_0) {
  const _merged_0 = run_loop($nc_context_defs$(_book_0, run_loop($nc_context_index$(_annotated_0))));
  return $book_cached$(_merged_0, ($norm_max_book$(_merged_0)));
}

function $nc_foreign_source$(_book_0, _scope_0, _path_0, _source_0, _parsed_0) {
  const _parts_0 = _parsed_0["parts"];
  const _error_0 = _parsed_0["error"];
  return $nt_choose$(($String$eq$(_error_0, "")), run_clo((_x_0) => {
  return $nt_choose$(run_loop($nc_foreign_base$(_scope_0, _path_0)), run_clo((_x_1) => {
  return $nc_foreign_parts$(_book_0, _parts_0);
}), run_clo((_x_2) => {
  return $nc_foreign_wrap$(run_loop($nc_constructors$(_book_0, _book_0)), run_loop($nc_foreign_namespace$(_scope_0, _path_0, _source_0)), ($nc_foreign_parts$(_book_0, _parts_0)));
}));
}), run_clo((_x_3) => {
  return "#error invalid foreign source identifier\n";
}));
}

function $nc_foreign_scope$(_book_0) {
  return $kr_filter$(_book_0, run_loop($nc_live_names$(_book_0, {$: "Con", "head": "main", "tail": {$: "Nil"}}, {$: "Nil"})));
}

function $check_from_exact_prefix$(_book_0, _validated_0) {
  return $dg_result_error$(run_loop($check_book_diagnostic_from_exact_prefix$(_book_0, _validated_0, {$: "Nil"})));
}

function $exact_prefix$(_book_0, _prefix_0) {
  if (_prefix_0.$ === "Nil") {
    return true;
  } else {
    const _h_0 = _prefix_0["head"];
    const _rest_0 = _prefix_0["tail"];
    return $exact_prefix_head$(_book_0, _h_0, _rest_0);
  }
}

function $f_load_graph$(_main_0, _sources_0) {
  return $f_graph_result_at$(run_loop($f_graph_load$(_main_0, "", _sources_0, {$: "FGraph", "book": {$: "Nil"}, "error": "", "done": {$: "Nil"}}, {$: "Nil"})), _sources_0);
}

function $f_main_names$(_main_0, _sources_0) {
  return $f_main_result_names$(($f_parse_source$(run_loop($f_graph_source$(_main_0, _sources_0)))));
}

function $f_load_graph_trace$(_main_0, _sources_0) {
  return $f_graph_trace$(run_loop($f_graph_load$(_main_0, "", _sources_0, {$: "FGraph", "book": {$: "Nil"}, "error": "", "done": {$: "Nil"}}, {$: "Nil"})), _sources_0);
}

function $f_source_parsed$(_name_0, _path_0, _text_0, _parsed_0) {
  return {$: "FParsedSource", "name": _name_0, "path": _path_0, "text": _text_0, "parsed": _parsed_0};
}

function $book_context$(_book_0) {
  if (_book_0.$ === "Nil") {
    return $book_cached$({$: "Nil"}, 0);
  } else {
    const _h_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($String$eq$(($dk$(_h_0)), "BookCache")), run_clo((_x_0) => {
  return {$: "Con", "head": _h_0, "tail": _rest_0};
}), run_clo((_x_1) => {
  return $book_cached$({$: "Con", "head": _h_0, "tail": _rest_0}, ($norm_max_book$({$: "Con", "head": _h_0, "tail": _rest_0})));
}));
  }
}

function $book_cached$(_book_0, _bound_0) {
  return {$: "Con", "head": {$: "KDef", "name": "$kernel.cache", "kind": "BookCache", "arity": _bound_0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Con", "head": run_loop($index_build$(_book_0)), "tail": {$: "Nil"}}, "native": true, "unsafe": false}, "tail": _book_0};
}

function $f_load_graph_seed$(_main_0, _sources_0, _seedPath_0, _seedText_0, _seedBook_0) {
  return $f_choose$(($f_seed_matches$(run_loop($f_source$("Base", _sources_0)), _seedPath_0, _seedText_0)), run_clo((_x_0) => {
  return $f_graph_result_at$(run_loop($fs_load$(_main_0, "", _sources_0, {$: "FGraph", "book": {$: "Nil"}, "error": "", "done": {$: "Nil"}}, {$: "Nil"}, {$: "FSeed", "path": _seedPath_0, "book": _seedBook_0, "root": run_loop($f_path_dir$(($f_source_path$(run_loop($f_graph_source$(_main_0, _sources_0))))))})), _sources_0);
}), run_clo((_x_1) => {
  return $f_load_graph$(_main_0, _sources_0);
}));
}

function $f_load_graph_seed_trace$(_main_0, _sources_0, _seedPath_0, _seedText_0, _seedBook_0) {
  return $f_choose$(($f_seed_matches$(run_loop($f_source$("Base", _sources_0)), _seedPath_0, _seedText_0)), run_clo((_x_0) => {
  return $f_graph_trace$(run_loop($fs_load$(_main_0, "", _sources_0, {$: "FGraph", "book": {$: "Nil"}, "error": "", "done": {$: "Nil"}}, {$: "Nil"}, {$: "FSeed", "path": _seedPath_0, "book": _seedBook_0, "root": run_loop($f_path_dir$(($f_source_path$(run_loop($f_graph_source$(_main_0, _sources_0))))))})), _sources_0);
}), run_clo((_x_1) => {
  return $f_load_graph_trace$(_main_0, _sources_0);
}));
}

function $driver_report$(_book_0, _names_0) {
  return $dr_verdict$(run_loop($driver_bad_names$(_book_0)));
}

function $driver_bad_names$(_book_0) {
  return $dr_bad_names$(($book_cached$(_book_0, ($norm_max_book$(_book_0)))), run_loop($dr_own_names$(_book_0, {$: "Nil"})));
}

function $compiler_check_result_abi$() {
  return 1;
}

function $check_book_diagnostic$($0, $1, $2, $3, $4, $5, $6) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _origins_0 = $1;
      $0 = _book_0;
      $1 = {$: "Nil"};
      $2 = _origins_0;
      $3 = ($book_cached$({$: "Nil"}, ($norm_max_book$(_book_0))));
      $pc = 1; continue;
    }
    case 1: {
      const _book_0 = $0;
      const _validated_0 = $1;
      const _origins_0 = $2;
      const _seed_0 = $3;
      $0 = _book_0;
      $1 = _validated_0;
      $2 = ($check_declarations$(_book_0, _seed_0));
      $3 = _seed_0;
      $4 = _book_0;
      $5 = _origins_0;
      $pc = 2; continue;
    }
    case 2: {
      const _todo_0 = $0;
      const _validated_0 = $1;
      const _done_0 = $2;
      const _seen_0 = $3;
      const _original_0 = $4;
      const _origins_0 = $5;
      if (_validated_0.$ === "Nil") {
        return $dg_suffix_events$(_todo_0, _done_0, _seen_0, _original_0, _origins_0);
      } else {
        const _head_0 = _validated_0["head"];
        const _tail_0 = _validated_0["tail"];
        $0 = _todo_0;
        $1 = _head_0;
        $2 = _tail_0;
        $3 = _done_0;
        $4 = _seen_0;
        $5 = _original_0;
        $6 = _origins_0;
        $pc = 3; continue;
      }
    }
    case 3: {
      const _todo_0 = $0;
      const _head_0 = $1;
      const _tail_0 = $2;
      const _done_0 = $3;
      const _seen_0 = $4;
      const _original_0 = $5;
      const _origins_0 = $6;
      if (_todo_0.$ === "Nil") {
        $0 = _original_0;
        $1 = _origins_0;
        $pc = 0; continue;
      } else {
        const _rest_0 = _todo_0["tail"];
        $0 = _rest_0;
        $1 = _tail_0;
        $2 = run_loop($check_event_install$(_done_0, _head_0, _rest_0));
        $3 = run_loop($book_put$(_seen_0, _head_0));
        $4 = _original_0;
        $5 = _origins_0;
        $pc = 2; continue;
      }
    }
  }
}

function $check_book_diagnostic_from_exact_prefix$(_book_0, _validated_0, _origins_0) {
  return $kc$(($exact_prefix$(_book_0, _validated_0)), run_clo((_x_0) => {
  return $dg_seed_books$(_book_0, _validated_0, _origins_0, ($book_cached$({$: "Nil"}, ($norm_max_book$(_book_0)))));
}), run_clo((_x_1) => {
  return $check_book_diagnostic$(_book_0, _origins_0);
}));
}

function $diagnostic_render$(_result_0) {
  const _error_0 = _result_0["error"];
  const _book_0 = _result_0["book"];
  const _diagnostic_0 = _result_0["diagnostic"];
  return $kc$(($String$eq$(_error_0, "")), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  return $dg_render_checked$(_book_0, _diagnostic_0, _error_0);
}));
}

function $diagnostic_result_locate$(_result_0, _origins_0) {
  const _error_0 = _result_0["error"];
  const _book_0 = _result_0["book"];
  const _diagnostic_0 = _result_0["diagnostic"];
  return {$: "DResult", "error": _error_0, "book": _book_0, "diagnostic": ($diagnostic_locate$(_diagnostic_0, _origins_0))};
}

function $f_load_origins_for$(_main_0, _sources_0, _definition_0) {
  return $f_loaded_origins_for$(($f_load_graph_trace$(_main_0, _sources_0)), _definition_0);
}

function $f_loaded_origins_for$(_trace_0, _definition_0) {
  return $fp_loaded_origins$(_trace_0, false, _definition_0);
}

function $j_compile_error$(_book_0) {
  return $kc$(($String$eq$(($dk$(run_loop($lookup$(_book_0, "IO")))), "Absent")), run_clo((_x_0) => {
  return "a build needs import Base";
}), run_clo((_x_1) => {
  return $j_main_error$(_book_0, run_loop($lookup$(_book_0, "main")));
}));
}

function $j_layout_error$(_book_0, _defs_0, _roots_0, _stops_0) {
  return $kc$(run_loop($j_layout_visit$(run_loop($book_context$(_book_0)), ($book_cached$(_defs_0, 0)), _roots_0, {$: "Nil"}, _stops_0)), run_clo((_x_0) => {
  return "an open Array element type";
}), run_clo((_x_1) => {
  return "";
}));
}

function $reach_book$(_book_0, _roots_0, _stops_0) {
  return $kr_filter$(_book_0, run_loop($kr_visit$(_book_0, _roots_0, {$: "Nil"}, _stops_0)));
}

function $j_roots$(_book_0, _library_0) {
  return $kc$(_library_0, run_clo((_x_0) => {
  return $j_library_roots$(_book_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": "main", "tail": {$: "Nil"}};
}));
}

function $j_stops$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($Bool$and$(($db$(_d_0)), ($j_intrinsic$(($dn$(_d_0)))))), run_clo((_x_0) => {
  return {$: "Con", "head": ($dn$(_d_0)), "tail": run_loop($j_stops$(_rest_0))};
}), run_clo((_x_1) => {
  return $j_stops$(_rest_0);
}));
  }
}

function $annotate_except$(_book_0, _stops_0) {
  return $ka_defs_except$(run_loop($book_context$(_book_0)), _book_0, _stops_0);
}

function $kf_source$(_book_0, _scope_0, _path_0, _source_0) {
  const _ns_0 = run_loop($kf_namespace$(_scope_0, _path_0));
  return $kc$(($String$eq$(($tg$(_ns_0)), "Error")), run_clo((_x_0) => {
  return {$: "KF_Source", "parts": {$: "Nil"}, "error": ($nm$(_ns_0))};
}), run_clo((_x_1) => {
  return $kf_scan$(_book_0, ($nm$(_ns_0)), _source_0, false, "", {$: "Nil"});
}));
}

function $annotate_selected$(_book_0, _selected_0, _stops_0) {
  return $ka_defs_except$(run_loop($book_context$(_book_0)), _selected_0, _stops_0);
}

function $j_program_selected$(_book_0, _defs_0) {
  return $j_program_context$(run_loop($book_context$(_book_0)), _defs_0);
}

function $j_library_selected$(_book_0, _defs_0) {
  return $j_library_context$(run_loop($book_context$(_book_0)), _defs_0);
}

function $j_foreign_paths$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($Bool$and$(($String$eq$(($tg$(run_loop($j_strip$(($dv$(_d_0)))))), "Foreign")), ($Bool$not$(($j_builtin_effect$(($dn$(_d_0)))))))), run_clo((_x_0) => {
  return {$: "Con", "head": run_loop($j_foreign_path$(($ks$(run_loop($j_strip$(($dv$(_d_0)))))))), "tail": run_loop($j_foreign_paths$(_rest_0))};
}), run_clo((_x_1) => {
  return $j_foreign_paths$(_rest_0);
}));
  }
}

function $j_foreign_error$(_book_0) {
  if (_book_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(run_loop($j_strip$(($dv$(_d_0)))))), "Foreign")), ($Bool$not$(($j_builtin_effect$(($dn$(_d_0)))))))), ($String$eq$(run_loop($j_foreign_path$(($ks$(run_loop($j_strip$(($dv$(_d_0)))))))), "")))), run_clo((_x_0) => {
  const _x_1 = ($dn$(_d_0));
  return ("a foreign def without a .js import: " + _x_1);
}), run_clo((_x_2) => {
  return $j_foreign_error$(_rest_0);
}));
  }
}

function $fpe_finish$(_source_0, _raw_0) {
  const _book_0 = _raw_0["book"];
  const _error_0 = _raw_0["error"];
  const _imports_0 = _raw_0["imports"];
  return {$: "FResult", "book": _book_0, "error": run_loop($fpe_render$(_source_0, _error_0)), "imports": _imports_0};
}

function $f_tops$(_ts0_0, _book_0, _imports_0, _unsafe_0) {
  return $f_top$(run_loop($f_skip$(_ts0_0)), _book_0, _imports_0, _unsafe_0);
}

function $f_lex$(_s_0, _l_0, _c_0, _d_0, _acc_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return $List$reverse$(_acc_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_ascii_char_eq$(($f_head$(_s_0)), "\n")), run_clo((_x_2) => {
  return $f_lex$(($f_tail$(_s_0)), ((_l_0 + 1) >>> 0), 0, _d_0, run_loop($f_choose$((_d_0 === 0), run_clo((_x_3) => {
  return {$: "Con", "head": {$: "FToken", "text": "\n", "f_line": _l_0, "f_col": _c_0, "f_kind": 0}, "tail": _acc_0};
}), run_clo((_x_4) => {
  return _acc_0;
}))));
}), run_clo((_x_5) => {
  return $f_choose$(($f_ascii_space$(($f_head$(_s_0)))), run_clo((_x_6) => {
  return $f_lex$(($f_tail$(_s_0)), _l_0, ((_c_0 + 1) >>> 0), _d_0, _acc_0);
}), run_clo((_x_7) => {
  return $f_choose$(($f_ascii_char_eq$(($f_head$(_s_0)), "#")), run_clo((_x_8) => {
  return $f_lex$(run_loop($f_scan_comment$(_s_0)), _l_0, _c_0, _d_0, _acc_0);
}), run_clo((_x_9) => {
  const _x_10 = ($f_ascii_char_eq$(($f_head$(_s_0)), "\""));
  const _x_11 = ($f_ascii_char_eq$(($f_head$(_s_0)), "'"));
  return $f_choose$((_x_10 || _x_11), run_clo((_x_12) => {
  return $f_lex_scanned$(run_loop($f_scan_quote$(($f_tail$(_s_0)), ($f_head$(_s_0)), (($f_head$(_s_0)) + ""), 1)), _l_0, _c_0, _d_0, 2, _acc_0);
}), run_clo((_x_13) => {
  return $f_choose$(($Bool$and$(($f_ident$(($f_head$(_s_0)))), ($Bool$not$(($f_ascii_char_eq$(($f_head$(_s_0)), ".")))))), run_clo((_x_14) => {
  return $f_lex_scanned$(run_loop($f_scan_word$(_s_0, "", 0)), _l_0, _c_0, _d_0, 1, _acc_0);
}), run_clo((_x_15) => {
  return $f_choose$(($f_triple_op$(_s_0)), run_clo((_x_16) => {
  return $f_lex$(($f_tail$(($f_tail$(($f_tail$(_s_0)))))), _l_0, ((_c_0 + 3) >>> 0), _d_0, {$: "Con", "head": {$: "FToken", "text": ($f_three$(_s_0)), "f_line": _l_0, "f_col": _c_0, "f_kind": 0}, "tail": _acc_0});
}), run_clo((_x_17) => {
  return $f_choose$(($f_ident$(($f_head$(_s_0)))), run_clo((_x_18) => {
  return $f_lex_scanned$(run_loop($f_scan_word$(_s_0, "", 0)), _l_0, _c_0, _d_0, 1, _acc_0);
}), run_clo((_x_19) => {
  return $f_lex_symbol$(_s_0, _l_0, _c_0, _d_0, _acc_0);
}));
}));
}));
}));
}));
}));
}));
}));
}

function $f_loaded_result$(_r_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  return $f_fresh_result$({$: "FResult", "book": _book_0, "error": _err_0, "imports": {$: "Nil"}});
}

function $f_load_module$(_name_0, _ns_0, _sources_0, _seen_0, _stack_0) {
  return $f_choose$(run_loop($has_name$(_stack_0, _name_0)), run_clo((_x_0) => {
  return {$: "FLoaded", "book": {$: "Nil"}, "error": ("cyclic import: " + _name_0), "seen": _seen_0};
}), run_clo((_x_1) => {
  return $f_choose$(run_loop($has_name$(_seen_0, _name_0)), run_clo((_x_2) => {
  return {$: "FLoaded", "book": {$: "Nil"}, "error": "", "seen": _seen_0};
}), run_clo((_x_3) => {
  return $f_load_source$(_name_0, _ns_0, run_loop($f_source$(_name_0, _sources_0)), _sources_0, _seen_0, _stack_0);
}));
}));
}

function $f_choose$(_b_0, _yes_0, _no_0) {
  if (_b_0) {
    return run_tail(_yes_0, {$: "Unit"});
  } else {
    return run_tail(_no_0, {$: "Unit"});
  }
}

function $Char$is_eq$(_a_0, _b_0) {
  const _x_0 = _a_0.codePointAt(0);
  const _x_1 = _b_0.codePointAt(0);
  return (_x_0 === _x_1);
}

function $f_head$(_s_0) {
  if (_s_0 === "") {
    return "\u0000";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    return _h_0;
  }
}

function $f_path_scan$(_path_0, _acc_0, _dir_0) {
  return $f_choose$(($String$is_empty$(_path_0)), run_clo((_x_0) => {
  return _dir_0;
}), run_clo((_x_1) => {
  const _x_2 = (($f_head$(_path_0)) + "");
  return $f_path_scan$(($f_tail$(_path_0)), (_acc_0 + _x_2), run_loop($f_choose$(($Char$is_eq$(($f_head$(_path_0)), "/")), run_clo((_x_3) => {
  return (_acc_0 + "/");
}), run_clo((_x_4) => {
  return _dir_0;
}))));
}));
}

function $dg_result_error$(_result_0) {
  const _error_0 = _result_0["error"];
  return _error_0;
}

function $ka_defs$(_book_0, _ds_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return {$: "Con", "head": ($ka_def$(_book_0, _d_0)), "tail": ($ka_defs$(_book_0, _rest_0))};
  }
}

function $kc$(_b_0, _yes_0, _no_0) {
  if (_b_0) {
    return run_tail(_yes_0, {$: "Unit"});
  } else {
    return run_tail(_no_0, {$: "Unit"});
  }
}

function $Bool$and$(_a_0, _b_0) {
  if (!_a_0) {
    return false;
  } else {
    return _b_0;
  }
}

function $String$eq$(_a_0, _b_0) {
  return $String$eq$fin$(($String$cmp$(_a_0, _b_0)));
}

function $tg$(_t_0) {
  const _tag_0 = _t_0["tag"];
  return _tag_0;
}

function $Bool$not$(_b_0) {
  if (!_b_0) {
    return true;
  } else {
    return false;
  }
}

function $j_l_name$(_t_0) {
  return $j_l_names$(($rm$(_t_0)));
}

function $j_quote$(_s_0) {
  const _x_0 = ($j_escape$(_s_0));
  const _x_1 = (_x_0 + "\"");
  return ("\"" + _x_1);
}

function $j_l_capture$(_env_0, _seen_0) {
  if (_env_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _env_0["head"];
    const _rest_0 = _env_0["tail"];
    return $kc$(run_loop($has_name$(_seen_0, ($j_local$(($ix$(_h_0)))))), run_clo((_x_0) => {
  return $j_l_capture$(_rest_0, _seen_0);
}), run_clo((_x_1) => {
  const _x_2 = run_loop($j_l_capture$(_rest_0, {$: "Con", "head": ($j_local$(($ix$(_h_0)))), "tail": _seen_0}));
  const _x_3 = ($j_local$(($ix$(_h_0))));
  const _x_4 = ("," + _x_2);
  return (_x_3 + _x_4);
}));
  }
}

function $j_expr_on$(_book_0, _env_0, _t_0, _ty_0, _tail_0, _key_0) {
  return $kc$(($String$eq$(_key_0, "Var")), run_clo((_x_0) => {
  return $j_local$(($ix$(_t_0)));
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(_key_0, "Ref")), run_clo((_x_2) => {
  const _x_3 = ($j_quote$(($nm$(_t_0))));
  const _x_4 = (_x_3 + ")");
  return ("get(G," + _x_4);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(_key_0, "App")), run_clo((_x_6) => {
  return $j_apply$(_book_0, _env_0, _t_0, _tail_0, run_loop($wnf$(_book_0, run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_t_0, 0)))))));
}), run_clo((_x_7) => {
  const _x_8 = ($String$eq$(_key_0, "Ctr"));
  const _x_9 = run_loop($core_nat$(_t_0));
  return $kc$((_x_8 || _x_9), run_clo((_x_10) => {
  return $j_constructor_mode$(_book_0, _env_0, _t_0, _ty_0, _tail_0);
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(_key_0, "Ann")), run_clo((_x_12) => {
  return $j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)), _tail_0);
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(_key_0, "Lam")), run_clo((_x_14) => {
  return $j_lambda$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)));
}), run_clo((_x_15) => {
  return $kc$(($String$eq$(_key_0, "Mat")), run_clo((_x_16) => {
  return $j_match$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)));
}), run_clo((_x_17) => {
  return $kc$(($String$eq$(_key_0, "Let")), run_clo((_x_18) => {
  return $j_let$(_book_0, _env_0, ($ks$(_t_0)), _ty_0, _tail_0);
}), run_clo((_x_19) => {
  return $kc$(($String$eq$(_key_0, "Rwt")), run_clo((_x_20) => {
  return $j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 2)), _ty_0, _tail_0);
}), run_clo((_x_21) => {
  return $kc$(($String$eq$(_key_0, "Efq")), run_clo((_x_22) => {
  return "fn(1,()=>bad(\"an absurd elimination\"))";
}), run_clo((_x_23) => {
  return $kc$(($String$eq$(_key_0, "Hol")), run_clo((_x_24) => {
  return "bad(\"cannot compile a hole\")";
}), run_clo((_x_25) => {
  return $kc$(($String$eq$(_key_0, "ADT")), run_clo((_x_26) => {
  const _x_27 = ($j_exprs$(_book_0, _env_0, ($ks$(_t_0))));
  const _x_28 = (_x_27 + "]})");
  const _x_29 = ($j_quote$(($nm$(_t_0))));
  const _x_30 = (",typeArgs:[" + _x_28);
  const _x_31 = (_x_29 + _x_30);
  return ("({typeName:" + _x_31);
}), run_clo((_x_32) => {
  return $kc$(($String$eq$(_key_0, "Qua")), run_clo((_x_33) => {
  const _x_34 = ($U32$show$(($qt$(_t_0))));
  const _x_35 = ($j_quote$(("&" + _x_34)));
  const _x_36 = (_x_35 + "})");
  return ("({typeName:" + _x_36);
}), run_clo((_x_37) => {
  return $kc$(($String$eq$(_key_0, "Typ")), run_clo((_x_38) => {
  return "({typeName:\"Type\"})";
}), run_clo((_x_39) => {
  return $kc$(($String$eq$(_key_0, "Rfl")), run_clo((_x_40) => {
  return "({proof:true})";
}), run_clo((_x_41) => {
  return "null";
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $j_desc_kind$(_book_0, _ty_0, _fuel_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  const _x_1 = run_loop($j_descriptor$(_book_0, run_loop($kid$(_ty_0, 1)), _fuel_0));
  const _x_2 = (_x_1 + "]");
  const _x_3 = run_loop($j_descriptor$(_book_0, run_loop($kid$(_ty_0, 0)), _fuel_0));
  const _x_4 = ("," + _x_2);
  const _x_5 = (_x_3 + _x_4);
  const _x_6 = ($U32$show$(($qt$(_ty_0))));
  const _x_7 = ("," + _x_5);
  const _x_8 = (_x_6 + _x_7);
  return ("[\"Fun\"," + _x_8);
}), run_clo((_x_9) => {
  return $j_desc_head$(_book_0, _ty_0, _fuel_0);
}));
}

function $wnf$(_book_0, _t_0) {
  return $norm_eval$(_book_0, _t_0, {$: "Nil"}, 0, ($atom$("Absent")));
}

function $dk$(_d_0) {
  const _kind_0 = _d_0["kind"];
  return _kind_0;
}

function $lookup$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return $missing$();
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($String$eq$(($dk$(_d_0)), "BookCache")), run_clo((_x_0) => {
  return $index_lookup$(_d_0, _name_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($dn$(_d_0)), _name_0)), run_clo((_x_2) => {
  return _d_0;
}), run_clo((_x_3) => {
  return $lookup$(_rest_0, _name_0);
}));
}));
  }
}

function $db$(_d_0) {
  const _native_0 = _d_0["native"];
  return _native_0;
}

function $j_io_spine$(_t_0, _args_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $j_io_spine$(run_loop($kid$(_t_0, 0)), ((_args_0 + 1) >>> 0));
}), run_clo((_x_1) => {
  return $Bool$and$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ref")), ($String$eq$(($nm$(_t_0)), "IO")))), (_args_0 === 1));
}));
}

function $j_io_shadow$(_book_0) {
  return $j_io_shadow_def$(_book_0, run_loop($lookup$(_book_0, "IO")));
}

function $nm$(_t_0) {
  const _name_0 = _t_0["name"];
  return _name_0;
}

function $j_source_parts$(_parts_0) {
  if (_parts_0.$ === "Nil") {
    return "";
  } else {
    const _part_0 = _parts_0["head"];
    const _rest_0 = _parts_0["tail"];
    const _x_2 = run_loop($kc$(($String$eq$(($tg$(_part_0)), "Text")), run_clo((_x_0) => {
  return $nm$(_part_0);
}), run_clo((_x_1) => {
  return $j_quote$(($nm$(_part_0)));
})));
    const _x_3 = ($j_source_parts$(_rest_0));
    return (_x_2 + _x_3);
  }
}

function $ks$(_t_0) {
  const _kids_0 = _t_0["kids"];
  return _kids_0;
}

function $j_module_exports$(_book_0, _path_0) {
  if (_book_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(($dv$(_d_0)))), "Foreign")), ($String$eq$(run_loop($j_foreign_path$(($ks$(($dv$(_d_0)))))), _path_0)))), run_clo((_x_0) => {
  return $j_module_export$(($dn$(_d_0)), ($j_foreign_name$(run_loop($kc$(($String$eq$(($nm$(($dv$(_d_0)))), "")), run_clo((_x_1) => {
  return $dn$(_d_0);
}), run_clo((_x_2) => {
  return $nm$(($dv$(_d_0)));
}))))));
}), run_clo((_x_3) => {
  return "";
})));
    const _x_5 = ($j_module_exports$(_rest_0, _path_0));
    return (_x_4 + _x_5);
  }
}

function $dv$(_d_0) {
  const _value_0 = _d_0["value"];
  return _value_0;
}

function $dt$(_d_0) {
  const _typ_0 = _d_0["typ"];
  return _typ_0;
}

function $driver_final$(_book_0, _done_0) {
  return $book_final_fast$(_book_0, _done_0);
}

function $kp_show$(_t_0) {
  return $kp_go$(_t_0, 0, {$: "Nil"});
}

function $strong$(_book_0, _t_0) {
  return $graph_strong$(_book_0, _t_0);
}

function $driver_count_todos$(_book_0) {
  if (_book_0.$ === "Nil") {
    return 0;
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_4 = ($driver_count_todos$(($dc$(_d_0))));
    const _x_5 = ($driver_count_todos$(_rest_0));
    const _x_6 = run_loop($kc$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), ($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))), ($Bool$not$(($db$(_d_0)))))), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  const _x_2 = ($driver_holes$(($dt$(_d_0))));
  const _x_3 = ($driver_holes$(($dv$(_d_0))));
  return ((_x_2 + _x_3) >>> 0);
})));
    const _x_7 = ((_x_4 + _x_5) >>> 0);
    return ((_x_6 + _x_7) >>> 0);
  }
}

function $driver_owned_names$(_book_0, _names_0) {
  if (_names_0.$ === "Nil") {
    return "";
  } else {
    const _name_0 = _names_0["head"];
    const _rest_0 = _names_0["tail"];
    return $kc$(($driver_owned_name$(_book_0, _name_0)), run_clo((_x_0) => {
  return (_name_0 + " is a name the compiler encodes itself: name yours apart");
}), run_clo((_x_1) => {
  return $driver_owned_names$(_book_0, _rest_0);
}));
  }
}

function $sp_finish$(_st_0) {
  return {$: "KSpecialized", "book": run_loop($index_remove$(($sp_book$(_st_0)), "$kernel.max-id")), "error": ($sp_error$(_st_0))};
}

function $sp_definitions$(_todo_0, _st_0) {
  if (_todo_0.$ === "Nil") {
    return _st_0;
  } else {
    const _d_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $kc$(($String$eq$(($sp_error$(_st_0)), "")), run_clo((_x_0) => {
  return $sp_definition_next$(_rest_0, _st_0, _d_0);
}), run_clo((_x_1) => {
  return _st_0;
}));
  }
}

function $sp_initial$(_book_0, _bound_0) {
  return {$: "KSpecState", "book": ($sp_stamp$(($check_declarations$(_book_0, {$: "Nil"})), _bound_0)), "memo": {$: "Nil"}, "serial": 0, "fresh": ((_bound_0 + 1) >>> 0), "error": "", "templates": run_loop($sp_template_book$(_book_0))};
}

function $sp_canonical$(_book_0, _done_0) {
  return $book_final_fast$(_book_0, _done_0);
}

function $norm_max_book$(_book_0) {
  return $norm_max_defs$(_book_0, 0);
}

function $nv_owned$(_book_0) {
  if (_book_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $nt_choose$(($Bool$and$(($Bool$not$(($db$(_d_0)))), ($nb_contains$({$: "Con", "head": "IO", "tail": {$: "Con", "head": "Sigma", "tail": {$: "Con", "head": "String", "tail": {$: "Con", "head": "Word.Con", "tail": {$: "Con", "head": "IO.OP", "tail": {$: "Con", "head": "Result", "tail": {$: "Con", "head": "Maybe", "tail": {$: "Con", "head": "Bool", "tail": {$: "Con", "head": "Unit", "tail": {$: "Con", "head": "Nat", "tail": {$: "Con", "head": "U32", "tail": {$: "Con", "head": "F32", "tail": {$: "Con", "head": "Char", "tail": {$: "Con", "head": "Array", "tail": {$: "Nil"}}}}}}}}}}}}}}}, ($dn$(_d_0)))))), run_clo((_x_0) => {
  const _x_1 = ($dn$(_d_0));
  return (_x_1 + " is a name the compiler encodes itself: name yours apart");
}), run_clo((_x_2) => {
  return $nv_owned$(_rest_0);
}));
  }
}

function $nt_choose$(_b_0, _yes_0, _no_0) {
  if (_b_0) {
    return run_tail(_yes_0, {$: "Unit"});
  } else {
    return run_tail(_no_0, {$: "Unit"});
  }
}

function $nc_unann$(_t_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $nc_unann$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $nc_is_io$(_book_0, _ty_0) {
  const _io_0 = run_loop($lookup$(_book_0, "IO"));
  const _shadow_0 = run_loop($book_put$(_book_0, {$: "KDef", "name": ($dn$(_io_0)), "kind": ($dk$(_io_0)), "arity": ($da$(_io_0)), "templates": ($dx$(_io_0)), "typ": ($dt$(_io_0)), "value": ($atom$("Absent")), "ctors": ($dc$(_io_0)), "native": ($db$(_io_0)), "unsafe": ($du$(_io_0))}));
  const _head_0 = run_loop($wnf$(_shadow_0, _ty_0));
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_io_0)), "Def")), ($db$(_io_0)))), ($String$eq$(($tg$(_head_0)), "App")))), ($String$eq$(($tg$(run_loop($kid$(_head_0, 0)))), "Ref")))), ($String$eq$(($nm$(run_loop($kid$(_head_0, 0)))), "IO")));
}

function $nc_finish$(_book_0, _runtime_0, _requests_0, _compiled_0) {
  const _ss_0 = _compiled_0["segments"];
  const _error_0 = _compiled_0["error"];
  const _ty_0 = ($dt$(run_loop($lookup$(_book_0, "main"))));
  const _pure_0 = ($Bool$not$(($nc_is_io$(_book_0, _ty_0))));
  const _cs_0 = ($nc_add_ctors$(($nc_default_ctors$()), run_loop($nc_constructors$(_book_0, _book_0))));
  return $nt_choose$(($Bool$not$(($String$eq$(_error_0, "")))), run_clo((_x_0) => {
  return {$: "NC_Result", "source": "", "error": _error_0};
}), run_clo((_x_1) => {
  return $nc_with_show$(_ss_0, _cs_0, _runtime_0, _requests_0, _pure_0, run_loop($nt_choose$(_pure_0, run_clo((_x_2) => {
  return $nc_show_program$(_book_0, _ty_0, _cs_0);
}), run_clo((_x_3) => {
  return {$: "NC_Show", "source": ($nc_show$("0")), "error": ""};
}))));
}));
}

function $nc_compile_defs$(_book_0, _todo_0, _done_0, _n_0, _bangs_0) {
  if (_todo_0.$ === "Nil") {
    return {$: "NC_Book", "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
  } else {
    const _name_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $nt_choose$(($nb_contains$(_done_0, _name_0)), run_clo((_x_0) => {
  return $nc_compile_defs$(_book_0, _rest_0, _done_0, _n_0, _bangs_0);
}), run_clo((_x_1) => {
  return $nc_compile_def$(_book_0, _name_0, _rest_0, _done_0, _n_0, _bangs_0);
}));
  }
}

function $nc_bangs_book$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $List$append$(run_loop($nc_bangs_term$(($dv$(_d_0)))), ($nc_bangs_book$(_rest_0)));
  }
}

function $nc_paths_of$(_book_0, _names_0) {
  if (_names_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _name_0 = _names_0["head"];
    const _rest_0 = _names_0["tail"];
    return $List$append$(run_loop($nc_c_paths$(($ks$(run_loop($nc_unann$(($dv$(run_loop($lookup$(_book_0, _name_0)))))))))), ($nc_paths_of$(_book_0, _rest_0)));
  }
}

function $nc_live_names$(_book_0, _todo_0, _done_0) {
  if (_todo_0.$ === "Nil") {
    return _done_0;
  } else {
    const _name_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $nt_choose$(($nb_contains$(_done_0, _name_0)), run_clo((_x_0) => {
  return $nc_live_names$(_book_0, _rest_0, _done_0);
}), run_clo((_x_1) => {
  return $nc_live_names$(_book_0, ($List$append$(($nc_refs$(run_loop($nc_definition$(_book_0, run_loop($lookup$(_book_0, _name_0)), 0)))), _rest_0)), {$: "Con", "head": _name_0, "tail": _done_0});
}));
  }
}

function $nc_native_def$(_d_0) {
  const _prim_0 = ($nc_primitive_name$(($dn$(_d_0))));
  const _x_0 = ($Bool$not$(($String$eq$(run_loop($ni_find$(_prim_0, ($ni_templates$()))), ""))));
  const _x_1 = ($nc_array_known$(_prim_0));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(_prim_0, "nat_divmod"));
  return $Bool$and$(($Bool$and$(($db$(_d_0)), ($Bool$not$(($String$eq$(($tg$(run_loop($nc_unann$(($dv$(_d_0)))))), "Foreign")))))), (_x_2 || _x_3));
}

function $dn$(_d_0) {
  const _name_0 = _d_0["name"];
  return _name_0;
}

function $nc_context_defs$(_book_0, _annotated_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $nt_choose$(($String$eq$(($dk$(_d_0)), "BookCache")), run_clo((_x_0) => {
  return $nc_context_defs$(_rest_0, _annotated_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": run_loop($nc_context_pick$(_d_0, run_loop($lookup$(_annotated_0, ($dn$(_d_0)))))), "tail": run_loop($nc_context_defs$(_rest_0, _annotated_0))};
}));
  }
}

function $nc_context_index$(_annotated_0) {
  if (_annotated_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _head_0 = _annotated_0["head"];
    const _rest_0 = _annotated_0["tail"];
    return $nt_choose$(run_loop($nc_context_has_cache$({$: "Con", "head": _head_0, "tail": _rest_0})), run_clo((_x_0) => {
  return {$: "Con", "head": _head_0, "tail": _rest_0};
}), run_clo((_x_1) => {
  return $book_cached$({$: "Con", "head": _head_0, "tail": _rest_0}, 0);
}));
  }
}

function $nc_foreign_base$(_ds_0, _path_0) {
  if (_ds_0.$ === "Nil") {
    return false;
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return $nt_choose$(($nc_foreign_has$(($ks$(run_loop($nc_unann$(($dv$(_d_0)))))), _path_0)), run_clo((_x_0) => {
  return $db$(_d_0);
}), run_clo((_x_1) => {
  return $nc_foreign_base$(_rest_0, _path_0);
}));
  }
}

function $nc_foreign_parts$(_book_0, _parts_0) {
  if (_parts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _parts_0["head"];
    const _rest_0 = _parts_0["tail"];
    const _x_6 = run_loop($nt_choose$(($String$eq$(($tg$(_h_0)), "Text")), run_clo((_x_0) => {
  return $nm$(_h_0);
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($tg$(_h_0)), "FID")), run_clo((_x_2) => {
  return $nt_fid$(run_loop($nc_ref_name$(_book_0, ($nm$(_h_0)))));
}), run_clo((_x_3) => {
  return $nt_cid$(run_loop($nt_choose$(($String$eq$(($dk$(run_loop($lookup$(_book_0, ($nm$(_h_0)))))), "Def")), run_clo((_x_4) => {
  return $nm$(_h_0);
}), run_clo((_x_5) => {
  return $nc_ctor_identity$(_book_0, ($nm$(_h_0)));
}))));
}));
})));
    const _x_7 = ($nc_foreign_parts$(_book_0, _rest_0));
    return (_x_6 + _x_7);
  }
}

function $nc_foreign_wrap$(_cs_0, _ns_0, _source_0) {
  const _x_0 = ($nc_foreign_aliases$(_cs_0, _ns_0, false));
  const _x_1 = ("\n" + _x_0);
  const _x_2 = ($nc_foreign_aliases$(_cs_0, _ns_0, true));
  const _x_3 = (_source_0 + _x_1);
  return (_x_2 + _x_3);
}

function $nc_constructors$(_book_0, _ds_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return $nt_choose$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_0) => {
  return $List$append$(($nc_ctor_specs$(_book_0, ($dc$(_d_0)), ($da$(_d_0)))), run_loop($nc_constructors$(_book_0, _rest_0)));
}), run_clo((_x_1) => {
  return $nt_choose$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), ($nc_foreign$(_d_0)))), run_clo((_x_2) => {
  return {$: "Con", "head": {$: "N_Constructor", "name": ($dn$(_d_0)), "arity": run_loop($nc_all_args$(_book_0, ($dt$(_d_0)))), "hot": true}, "tail": run_loop($nc_constructors$(_book_0, _rest_0))};
}), run_clo((_x_3) => {
  return $nc_constructors$(_book_0, _rest_0);
}));
}));
  }
}

function $nc_foreign_namespace$(_ds_0, _path_0, _source_0) {
  if (_ds_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return $nt_choose$(($nc_foreign_has$(($ks$(run_loop($nc_unann$(($dv$(_d_0)))))), _path_0)), run_clo((_x_0) => {
  return $nt_choose$(($String$eq$(($nm$(run_loop($nc_unann$(($dv$(_d_0)))))), "")), run_clo((_x_1) => {
  return $nc_source_namespace$(($String$split$(($dn$(_d_0)), ".")), "", _source_0);
}), run_clo((_x_2) => {
  const _x_3 = ($dn$(_d_0));
  const _x_4 = ($nm$(run_loop($nc_unann$(($dv$(_d_0))))));
  const _x_5 = [..._x_3].length;
  const _x_6 = [..._x_4].length;
  return $String$take$(($dn$(_d_0)), (_x_5 < _x_6 ? 0 : _x_5 - _x_6));
}));
}), run_clo((_x_7) => {
  return $nc_foreign_namespace$(_rest_0, _path_0, _source_0);
}));
  }
}

function $kr_filter$(_book_0, _live_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(run_loop($has_name$(_live_0, ($dn$(_d_0)))), run_clo((_x_0) => {
  return {$: "Con", "head": _d_0, "tail": run_loop($kr_filter$(_rest_0, _live_0))};
}), run_clo((_x_1) => {
  return $kr_filter$(_rest_0, _live_0);
}));
  }
}

function $exact_prefix_head$(_book_0, _h_0, _rest_0) {
  if (_book_0.$ === "Nil") {
    return false;
  } else {
    const _x_0 = _book_0["head"];
    const _xs_0 = _book_0["tail"];
    return $Bool$and$(($exact_def$(_x_0, _h_0)), ($exact_prefix$(_xs_0, _rest_0)));
  }
}

function $f_graph_result_at$(_graph_0, _sources_0) {
  return $fpe_graph_result$(_graph_0, _sources_0, ($f_graph_result$(_graph_0)));
}

function $f_graph_load$(_path_0, _ns_0, _sources_0, _g_0, _stack_0) {
  return $fs_load$(_path_0, _ns_0, _sources_0, _g_0, _stack_0, {$: "FSeed", "path": "", "book": {$: "Nil"}, "root": run_loop($f_path_dir$(($f_source_path$(run_loop($f_graph_source$(_path_0, _sources_0))))))});
}

function $f_main_result_names$(_r_0) {
  const _book_0 = _r_0["book"];
  const _error_0 = _r_0["error"];
  return $f_choose$(($String$is_empty$(_error_0)), run_clo((_x_0) => {
  return $f_main_order$(_book_0, {$: "Nil"});
}), run_clo((_x_1) => {
  return {$: "Nil"};
}));
}

function $f_parse_source$(_source_0) {
  if (_source_0.$ === "FSource") {
    const _text_0 = _source_0["text"];
    return $f_parse$(_text_0);
  } else {
    const _parsed_0 = _source_0["parsed"];
    return _parsed_0;
  }
}

function $f_graph_source$(_path_0, _sources_0) {
  if (_sources_0.$ === "Nil") {
    return {$: "FSource", "name": "", "path": "", "text": ""};
  } else {
    const _s_0 = _sources_0["head"];
    const _rest_0 = _sources_0["tail"];
    const _x_0 = ($f_eq$(_path_0, ($f_source_name$(_s_0))));
    const _x_1 = ($f_eq$(_path_0, ($f_source_path$(_s_0))));
    return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return _s_0;
}), run_clo((_x_3) => {
  return $f_graph_source$(_path_0, _rest_0);
}));
  }
}

function $f_graph_trace$(_graph_0, _sources_0) {
  const _book_0 = _graph_0["book"];
  const _error_0 = _graph_0["error"];
  const _done_0 = _graph_0["done"];
  return {$: "FLoadTrace", "result": run_loop($f_graph_result_at$({$: "FGraph", "book": _book_0, "error": _error_0, "done": _done_0}, _sources_0)), "done": _done_0, "sources": _sources_0};
}

function $atom$(_tag_0) {
  return $kt$(_tag_0, "", 0, 0, {$: "Nil"});
}

function $index_build$(_book_0) {
  if (_book_0.$ === "Nil") {
    return $missing$();
  } else {
    const _h_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $index_set$(run_loop($index_build$(_rest_0)), _h_0, ($index_hash$(($dn$(_h_0)), 2166136261)), 32);
  }
}

function $f_seed_matches$(_source_0, _path_0, _text_0) {
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$not$(($String$is_empty$(_path_0)))), ($f_eq$(($f_source_name$(_source_0)), "Base")))), ($f_eq$(($f_source_path$(_source_0)), _path_0)))), run_loop($f_seed_text_equal$(($f_source_text$(_source_0)), _text_0)));
}

function $f_source$(_name_0, _sources_0) {
  if (_sources_0.$ === "Nil") {
    return {$: "FSource", "name": "", "path": "", "text": ""};
  } else {
    const _source_0 = _sources_0["head"];
    const _rest_0 = _sources_0["tail"];
    return $f_choose$(($f_eq$(_name_0, ($f_source_name$(_source_0)))), run_clo((_x_0) => {
  return _source_0;
}), run_clo((_x_1) => {
  return $f_source$(_name_0, _rest_0);
}));
  }
}

function $fs_load$(_path_0, _ns_0, _sources_0, _g_0, _stack_0, _seed_0) {
  return $fs_source$(run_loop($f_graph_source$(_path_0, _sources_0)), _ns_0, _sources_0, _g_0, _stack_0, _seed_0);
}

function $f_source_path$(_source_0) {
  if (_source_0.$ === "FSource") {
    const _path_0 = _source_0["path"];
    return _path_0;
  } else {
    const _path_1 = _source_0["path"];
    return _path_1;
  }
}

function $dr_verdict$(_names_0) {
  if (_names_0.$ === "Nil") {
    return "ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n";
  } else {
    const _name_0 = _names_0["head"];
    const _rest_0 = _names_0["tail"];
    const _x_0 = ($dr_count$({$: "Con", "head": _name_0, "tail": _rest_0}));
    const _x_3 = ($dr_lines$({$: "Con", "head": _name_0, "tail": _rest_0}));
    const _x_4 = run_loop($kc$((_x_0 === 1), run_clo((_x_1) => {
  return " def relies";
}), run_clo((_x_2) => {
  return " defs rely";
})));
    const _x_5 = (" on unsafe or foreign code:\n" + _x_3);
    const _x_6 = ($U32$show$(($dr_count$({$: "Con", "head": _name_0, "tail": _rest_0}))));
    const _x_7 = (_x_4 + _x_5);
    const _x_8 = (_x_6 + _x_7);
    return ("SOME PROOFS FAIL\nError: " + _x_8);
  }
}

function $dr_bad_names$(_book_0, _names_0) {
  if (_names_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _name_0 = _names_0["head"];
    const _rest_0 = _names_0["tail"];
    return $kc$(run_loop($dr_relies$(_book_0, {$: "Con", "head": _name_0, "tail": {$: "Nil"}}, {$: "Nil"})), run_clo((_x_0) => {
  return {$: "Con", "head": _name_0, "tail": run_loop($dr_bad_names$(_book_0, _rest_0))};
}), run_clo((_x_1) => {
  return $dr_bad_names$(_book_0, _rest_0);
}));
  }
}

function $dr_own_names$(_book_0, _seen_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_0 = ($db$(_d_0));
    const _x_1 = run_loop($has_name$(_seen_0, ($dn$(_d_0))));
    return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return $dr_own_names$(_rest_0, _seen_0);
}), run_clo((_x_3) => {
  return {$: "Con", "head": ($dn$(_d_0)), "tail": run_loop($dr_own_names$(_rest_0, {$: "Con", "head": ($dn$(_d_0)), "tail": _seen_0}))};
}));
  }
}

function $dg_seed_books$($0, $1, $2, $3, $4, $5, $6) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _origins_0 = $1;
      $0 = _book_0;
      $1 = {$: "Nil"};
      $2 = _origins_0;
      $3 = ($book_cached$({$: "Nil"}, ($norm_max_book$(_book_0))));
      $pc = 1; continue;
    }
    case 1: {
      const _book_0 = $0;
      const _validated_0 = $1;
      const _origins_0 = $2;
      const _seed_0 = $3;
      $0 = _book_0;
      $1 = _validated_0;
      $2 = ($check_declarations$(_book_0, _seed_0));
      $3 = _seed_0;
      $4 = _book_0;
      $5 = _origins_0;
      $pc = 2; continue;
    }
    case 2: {
      const _todo_0 = $0;
      const _validated_0 = $1;
      const _done_0 = $2;
      const _seen_0 = $3;
      const _original_0 = $4;
      const _origins_0 = $5;
      if (_validated_0.$ === "Nil") {
        return $dg_suffix_events$(_todo_0, _done_0, _seen_0, _original_0, _origins_0);
      } else {
        const _head_0 = _validated_0["head"];
        const _tail_0 = _validated_0["tail"];
        $0 = _todo_0;
        $1 = _head_0;
        $2 = _tail_0;
        $3 = _done_0;
        $4 = _seen_0;
        $5 = _original_0;
        $6 = _origins_0;
        $pc = 3; continue;
      }
    }
    case 3: {
      const _todo_0 = $0;
      const _head_0 = $1;
      const _tail_0 = $2;
      const _done_0 = $3;
      const _seen_0 = $4;
      const _original_0 = $5;
      const _origins_0 = $6;
      if (_todo_0.$ === "Nil") {
        $0 = _original_0;
        $1 = _origins_0;
        $pc = 0; continue;
      } else {
        const _rest_0 = _todo_0["tail"];
        $0 = _rest_0;
        $1 = _tail_0;
        $2 = run_loop($check_event_install$(_done_0, _head_0, _rest_0));
        $3 = run_loop($book_put$(_seen_0, _head_0));
        $4 = _original_0;
        $5 = _origins_0;
        $pc = 2; continue;
      }
    }
  }
}

function $dg_render_checked$(_book_0, _diagnostic_0, _error_0) {
  const _expected_0 = _diagnostic_0["expected"];
  const _observed_0 = _diagnostic_0["observed"];
  const _has_observed_0 = _diagnostic_0["has_observed"];
  const _context_0 = _diagnostic_0["context"];
  const _definition_0 = _diagnostic_0["definition"];
  const _span_0 = _diagnostic_0["span"];
  const _note_0 = _diagnostic_0["note"];
  const _trail_0 = _diagnostic_0["trail"];
  const _x_0 = ($terms_len$(_trail_0));
  return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return ("Error: " + _error_0);
}), run_clo((_x_2) => {
  return $dg_render$(_book_0, {$: "DDiagnostic", "expected": _expected_0, "observed": _observed_0, "has_observed": _has_observed_0, "context": _context_0, "definition": _definition_0, "span": _span_0, "note": _note_0, "trail": _trail_0});
}));
}

function $diagnostic_locate$(_diagnostic_0, _origins_0) {
  const _expected_0 = _diagnostic_0["expected"];
  const _observed_0 = _diagnostic_0["observed"];
  const _has_observed_0 = _diagnostic_0["has_observed"];
  const _context_0 = _diagnostic_0["context"];
  const _definition_0 = _diagnostic_0["definition"];
  const _span_0 = _diagnostic_0["span"];
  const _note_0 = _diagnostic_0["note"];
  const _trail_0 = _diagnostic_0["trail"];
  return {$: "DDiagnostic", "expected": _expected_0, "observed": _observed_0, "has_observed": _has_observed_0, "context": _context_0, "definition": _definition_0, "span": run_loop($kc$(($dg_has_span$(_span_0)), run_clo((_x_0) => {
  return _span_0;
}), run_clo((_x_1) => {
  return $dg_origin_trail$(_origins_0, _definition_0, _trail_0);
}))), "note": _note_0, "trail": _trail_0};
}

function $fp_loaded_origins$(_trace_0, _all_0, _definition_0) {
  const _result_0 = _trace_0["result"];
  const _done_0 = _trace_0["done"];
  const _sources_0 = _trace_0["sources"];
  return $fp_loaded_result$(_result_0, _done_0, _sources_0, _all_0, _definition_0);
}

function $j_main_error$(_book_0, _main_0) {
  const _x_0 = ($Bool$not$(($String$eq$(($dk$(_main_0)), "Def"))));
  const _x_1 = ($String$eq$(($tg$(run_loop($j_strip$(($dv$(_main_0)))))), "Absent"));
  return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return "no main to run";
}), run_clo((_x_3) => {
  return $kc$(run_loop($j_io_type$(_book_0, ($dt$(_main_0)))), run_clo((_x_4) => {
  return $kc$(($String$eq$(($tg$(run_loop($j_strip$(($dv$(_main_0)))))), "Foreign")), run_clo((_x_5) => {
  return "main must be a filled def: a foreign main cannot anchor IO";
}), run_clo((_x_6) => {
  return "";
}));
}), run_clo((_x_7) => {
  return $kc$(run_loop($j_printable$(_book_0, ($dt$(_main_0)), {$: "Nil"}, 0)), run_clo((_x_8) => {
  return "";
}), run_clo((_x_9) => {
  const _x_10 = run_loop($kp_show$(($dt$(_main_0))));
  const _x_11 = (_x_10 + " cannot be printed (a function, a Type, an erased or dependent field)");
  return ("main's type " + _x_11);
}));
}));
}));
}

function $j_layout_visit$(_book_0, _defs_0, _todo_0, _seen_0, _stops_0) {
  if (_todo_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $kc$(($String$eq$(_h_0, "$layout.open-array")), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  const _x_2 = run_loop($has_name$(_seen_0, _h_0));
  const _x_3 = run_loop($has_name$(_stops_0, _h_0));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $j_layout_visit$(_book_0, _defs_0, _rest_0, _seen_0, _stops_0);
}), run_clo((_x_5) => {
  return $j_layout_def$(_book_0, _defs_0, run_loop($lookup$(_defs_0, _h_0)), _rest_0, {$: "Con", "head": _h_0, "tail": _seen_0}, _stops_0);
}));
}));
  }
}

function $kr_visit$(_book_0, _todo_0, _seen_0, _stops_0) {
  if (_todo_0.$ === "Nil") {
    return _seen_0;
  } else {
    const _name_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $kc$(run_loop($has_name$(_seen_0, _name_0)), run_clo((_x_0) => {
  return $kr_visit$(_book_0, _rest_0, _seen_0, _stops_0);
}), run_clo((_x_1) => {
  return $kr_visit_def$(_book_0, _rest_0, {$: "Con", "head": _name_0, "tail": _seen_0}, _stops_0, run_loop($kr_resolve$(_book_0, _name_0)));
}));
  }
}

function $j_library_roots$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_0 = ($dx$(_d_0));
    const _x_1 = ($Bool$not$(($db$(_d_0))));
    const _x_2 = ($String$eq$(($tg$(($dv$(_d_0)))), "Foreign"));
    return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), (_x_0 === 0))), ($Bool$not$(($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))))), (_x_1 || _x_2))), run_clo((_x_3) => {
  return {$: "Con", "head": ($dn$(_d_0)), "tail": run_loop($j_library_roots$(_rest_0))};
}), run_clo((_x_4) => {
  return $j_library_roots$(_rest_0);
}));
  }
}

function $j_intrinsic$(_name_0) {
  const _x_0 = (_name_0 + "|");
  return $String$contains$("|U32.add|U32.sub|U32.and|U32.or|U32.xor|U32.is_eq|U32.is_ne|U32.is_lt|U32.is_le|U32.is_gt|U32.is_ge|U32.mul|U32.div|U32.mod|U32.inc|U32.shl|U32.shr|U32.shln|U32.shrn|U32.not|U32.is_zero|U32.cmp|U32.to_f32|U32.to_nat|U32.from_nat|F32.add|F32.sub|F32.mul|F32.div|F32.neg|F32.is_eq|F32.is_ne|F32.is_lt|F32.is_le|F32.is_gt|F32.is_ge|F32.sqrt|F32.exp|F32.log|F32.log2|F32.log10|F32.sin|F32.cos|F32.tan|F32.asin|F32.acos|F32.atan|F32.sinh|F32.cosh|F32.tanh|F32.floor|F32.ceil|F32.trunc|F32.abs|F32.pow|F32.atan2|F32.mod|F32.to_u32|F32.bits|F32.show|F32.read|Nat.add|Nat.sub|Nat.mul|Nat.double|Nat.cmp|Nat.is_lt|Nat.divmod|Array.new|Array.set|Array.get|Array.swap|Array.size|Array.clone|IO.pure|IO.bind|IO.try|IO.pass|IO.die|IO.args|IO.print|IO.write|IO.print_err|IO.get_env|IO.now|IO.sleep|IO.random_u32|IO.spawn|IO.fork|IO.join|String.append|String.length|String.eq|String.contains|String.starts_with|String.reverse|String.is_empty|Bool.or|Bool.xor|", ("|" + _x_0));
}

function $ka_defs_except$(_book_0, _ds_0, _stops_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return {$: "Con", "head": run_loop($kc$(run_loop($has_name$(_stops_0, ($dn$(_d_0)))), run_clo((_x_0) => {
  return _d_0;
}), run_clo((_x_1) => {
  return $ka_def$(_book_0, _d_0);
}))), "tail": ($ka_defs_except$(_book_0, _rest_0, _stops_0))};
  }
}

function $kf_namespace$(_book_0, _path_0) {
  return $kf_namespaces$(_book_0, _path_0, "", false);
}

function $kf_scan$(_book_0, _ns_0, _source_0, _word_0, _text_0, _parts_0) {
  const _x_0 = ($String$starts_with$(_source_0, "CID("));
  const _x_1 = ($String$starts_with$(_source_0, "FID("));
  return $kc$(($Bool$and$(($Bool$not$(_word_0)), (_x_0 || _x_1))), run_clo((_x_2) => {
  return $kf_token$(_book_0, _ns_0, _source_0, _text_0, _parts_0);
}), run_clo((_x_3) => {
  return $kf_char$(_book_0, _ns_0, _source_0, _text_0, _parts_0);
}));
}

function $j_program_context$(_book_0, _defs_0) {
  const _x_2 = run_loop($kc$(run_loop($j_io_type$(_book_0, ($dt$(run_loop($lookup$(_book_0, "main")))))), run_clo((_x_0) => {
  return "true";
}), run_clo((_x_1) => {
  return "false";
})));
  const _x_3 = (_x_2 + ");\n");
  const _x_4 = run_loop($j_descriptor$(_book_0, ($dt$(run_loop($lookup$(_book_0, "main")))), 64));
  const _x_5 = ("," + _x_3);
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ($j_defs$(_book_0, _defs_0));
  const _x_8 = ("\nawait runmain(" + _x_6);
  const _x_9 = ($j_schemas$(_book_0, _defs_0));
  const _x_10 = (_x_7 + _x_8);
  const _x_11 = ($j_ctor_metadata$(_defs_0));
  const _x_12 = (_x_9 + _x_10);
  return (_x_11 + _x_12);
}

function $j_library_context$(_book_0, _defs_0) {
  const _x_0 = ($j_defs$(_book_0, _defs_0));
  const _x_1 = ($j_schemas$(_book_0, _defs_0));
  const _x_2 = (_x_0 + "\nexport {G,call,list,ctor};\nexport default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));\n");
  const _x_3 = ($j_ctor_metadata$(_defs_0));
  const _x_4 = (_x_1 + _x_2);
  return (_x_3 + _x_4);
}

function $j_strip$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $j_strip$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $j_builtin_effect$(_name_0) {
  const _x_0 = (_name_0 + "|");
  return $String$contains$("|IO.print|IO.write|IO.print_err|IO.get_env|IO.args|IO.random_u32|IO.spawn|IO.sleep|IO.now|IO.thread_count|Process.run|Chan.new|Chan.send|Chan.recv|Chan.close|File.open|File.read|File.read_bytes|File.read_at|File.size|File.write|File.write_bytes|File.close|TCP.listen|TCP.accept|TCP.connect|TCP.send|TCP.recv|TCP.send_bytes|TCP.recv_bytes|TCP.poll|UDP.bind|UDP.send_to|UDP.recv_from|UDP.poll|Socket.close|Listener.close|Window.open|Window.frame|Window.set_title|Window.grab|Window.close|Audio.open|Audio.write|Audio.close|", ("|" + _x_0));
}

function $j_foreign_path$(_paths_0) {
  if (_paths_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _paths_0["head"];
    const _rest_0 = _paths_0["tail"];
    const _x_0 = ($String$ends_with$(($nm$(_h_0)), ".js\""));
    const _x_1 = ($String$ends_with$(($nm$(_h_0)), ".js"));
    return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return $nm$(_h_0);
}), run_clo((_x_3) => {
  return $j_foreign_path$(_rest_0);
}));
  }
}

function $fpe_render$(_source_0, _error_0) {
  return $f_choose$(($String$eq$(($tg$(_error_0)), "Absent")), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = ($ix$(_error_0));
  return $f_choose$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_error_0)), "Error")), ($String$eq$(($tg$(run_loop($kid$(_error_0, 0)))), "ParseExpected")))), ($String$eq$(($tg$(run_loop($kid$(_error_0, 1)))), "ParseToken")))), (_x_2 > 0))), run_clo((_x_3) => {
  return $fpe_seek$(_source_0, _source_0, 1, 0, _error_0);
}), run_clo((_x_4) => {
  return $nm$(_error_0);
}));
}));
}

function $f_top$(_ts_0, _book_0, _imports_0, _unsafe_0) {
  return $f_choose$(_unsafe_0, run_clo((_x_0) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "def")), run_clo((_x_1) => {
  return $f_top_ready$(_ts_0, _book_0, _imports_0, _unsafe_0);
}), run_clo((_x_2) => {
  return $f_result$(_book_0, ($f_pn$(($f_err$(_ts_0, "expected def after @unsafe")))), _imports_0);
}));
}), run_clo((_x_3) => {
  return $f_top_ready$(_ts_0, _book_0, _imports_0, _unsafe_0);
}));
}

function $f_skip$(_ts_0) {
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), "\n"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), ";"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_skip$(($f_tl$(_ts_0)));
}), run_clo((_x_3) => {
  return _ts_0;
}));
}

function $String$is_empty$(_s_0) {
  if (_s_0 === "") {
    return true;
  } else {
    return false;
  }
}

function $List$reverse$(_xs_0) {
  return $List$reverse$go$(_xs_0, {$: "Nil"});
}

function $f_ascii_char_eq$(_a_0, _b_0) {
  const _x_0 = ($Char$to_u32$(_a_0));
  const _x_1 = ($Char$to_u32$(_b_0));
  return (_x_0 === _x_1);
}

function $f_tail$(_s_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    return _t_0;
  }
}

function $f_ascii_space$(_c_0) {
  return $f_ascii_space_code$(($Char$to_u32$(_c_0)));
}

function $f_scan_comment$(_s_0) {
  const _x_0 = ($String$is_empty$(_s_0));
  const _x_1 = ($f_ascii_char_eq$(($f_head$(_s_0)), "\n"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return _s_0;
}), run_clo((_x_3) => {
  return $f_scan_comment$(($f_tail$(_s_0)));
}));
}

function $f_lex_scanned$(_sc_0, _l_0, _c_0, _d_0, _k_0, _acc_0) {
  const _word_0 = _sc_0["word"];
  const _rest_0 = _sc_0["rest"];
  const _size_0 = _sc_0["size"];
  return $f_choose$((_size_0 === 0), run_clo((_x_0) => {
  return $List$reverse$({$: "Con", "head": {$: "FToken", "text": "unterminated string", "f_line": _l_0, "f_col": _c_0, "f_kind": 3}, "tail": _acc_0});
}), run_clo((_x_1) => {
  return $f_choose$((_k_0 === 2), run_clo((_x_2) => {
  return $f_lex_quote_end$(_word_0, _rest_0, _l_0, _c_0, _d_0, {$: "Con", "head": {$: "FToken", "text": _word_0, "f_line": _l_0, "f_col": _c_0, "f_kind": _k_0}, "tail": _acc_0});
}), run_clo((_x_3) => {
  return $f_lex$(_rest_0, _l_0, ((_c_0 + _size_0) >>> 0), _d_0, {$: "Con", "head": {$: "FToken", "text": _word_0, "f_line": _l_0, "f_col": _c_0, "f_kind": _k_0}, "tail": _acc_0});
}));
}));
}

function $f_scan_quote$(_s_0, _quote_0, _acc_0, _n_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return {$: "FScanned", "word": "", "rest": "", "size": 0};
}), run_clo((_x_1) => {
  return $f_choose$(($f_ascii_char_eq$(($f_head$(_s_0)), _quote_0)), run_clo((_x_2) => {
  return {$: "FScanned", "word": ($String$reverse$((_quote_0 + _acc_0))), "rest": ($f_tail$(_s_0)), "size": ((_n_0 + 1) >>> 0)};
}), run_clo((_x_3) => {
  return $f_choose$(($f_ascii_char_eq$(($f_head$(_s_0)), "\\")), run_clo((_x_4) => {
  return $f_scan_quote$(($f_tail$(($f_tail$(_s_0)))), _quote_0, (($f_head$(($f_tail$(_s_0)))) + ("\\" + _acc_0)), ((_n_0 + 2) >>> 0));
}), run_clo((_x_5) => {
  return $f_scan_quote$(($f_tail$(_s_0)), _quote_0, (($f_head$(_s_0)) + _acc_0), ((_n_0 + 1) >>> 0));
}));
}));
}));
}

function $f_ident$(_c_0) {
  return $f_ascii_ident_code$(($Char$to_u32$(_c_0)));
}

function $f_scan_word$(_s_0, _acc_0, _n_0) {
  return $f_choose$(run_loop($f_choose$(($f_ident$(($f_head$(_s_0)))), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  const _x_2 = ($f_ascii_char_eq$(($f_head$(_s_0)), "+"));
  const _x_3 = ($f_ascii_char_eq$(($f_head$(_s_0)), "-"));
  const _x_4 = ($f_ascii_char_eq$(($f_head$(_acc_0)), "e"));
  const _x_5 = ($f_ascii_char_eq$(($f_head$(_acc_0)), "E"));
  return $Bool$and$(($Bool$and$((_x_2 || _x_3), (_x_4 || _x_5))), ($f_ascii_digit$(($f_head$(($f_tail$(_s_0)))))));
}))), run_clo((_x_6) => {
  return $f_scan_word$(($f_tail$(_s_0)), (($f_head$(_s_0)) + _acc_0), ((_n_0 + 1) >>> 0));
}), run_clo((_x_7) => {
  return {$: "FScanned", "word": ($String$reverse$(_acc_0)), "rest": _s_0, "size": _n_0};
}));
}

function $f_triple_op$(_s_0) {
  const _x_0 = ($f_eq$(($f_three$(_s_0)), ".&."));
  const _x_1 = ($f_eq$(($f_three$(_s_0)), ".|."));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(($f_three$(_s_0)), ".^."));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(($f_three$(_s_0)), "<&>"));
  return (_x_4 || _x_5);
}

function $f_three$(_s_0) {
  return (($f_head$(_s_0)) + (($f_head$(($f_tail$(_s_0)))) + (($f_head$(($f_tail$(($f_tail$(_s_0)))))) + "")));
}

function $f_lex_symbol$(_s_0, _l_0, _c_0, _d_0, _acc_0) {
  const _x_0 = ($f_tx$(_acc_0));
  const _x_1 = [..._x_0].length;
  const _x_2 = ($f_col$(_acc_0));
  const _x_3 = (_x_1 >>> 0);
  const _x_4 = ((_x_2 + _x_3) >>> 0);
  return $f_choose$(($Bool$and$(($f_pair_op$(($f_two$(_s_0)))), ($Bool$not$(($Bool$and$(($Bool$and$(($f_eq$(($f_two$(_s_0)), "++")), ($String$ends_with$(($f_tx$(_acc_0)), "n")))), (_c_0 === _x_4))))))), run_clo((_x_5) => {
  const _x_6 = ($f_tx$(_acc_0));
  const _x_7 = [..._x_6].length;
  const _x_8 = ($f_col$(_acc_0));
  const _x_9 = (_x_7 >>> 0);
  const _x_10 = ((_x_8 + _x_9) >>> 0);
  return $f_lex$(($f_tail$(($f_tail$(_s_0)))), _l_0, ((_c_0 + 2) >>> 0), _d_0, {$: "Con", "head": {$: "FToken", "text": run_loop($f_choose$(($Bool$and$(($f_eq$(($f_two$(_s_0)), ">>")), (_c_0 > _x_10))), run_clo((_x_11) => {
  return ">>op";
}), run_clo((_x_12) => {
  return $f_two$(_s_0);
}))), "f_line": _l_0, "f_col": _c_0, "f_kind": 0}, "tail": _acc_0});
}), run_clo((_x_13) => {
  const _x_14 = ($f_ascii_char_eq$(($f_head$(_s_0)), "("));
  const _x_15 = ($f_ascii_char_eq$(($f_head$(_s_0)), "["));
  const _x_16 = (_x_14 || _x_15);
  const _x_17 = ($f_ascii_char_eq$(($f_head$(_s_0)), "{"));
  return $f_lex$(($f_tail$(_s_0)), _l_0, ((_c_0 + 1) >>> 0), run_loop($f_choose$((_x_16 || _x_17), run_clo((_x_18) => {
  return ((_d_0 + 1) >>> 0);
}), run_clo((_x_19) => {
  const _x_20 = ($f_ascii_char_eq$(($f_head$(_s_0)), ")"));
  const _x_21 = ($f_ascii_char_eq$(($f_head$(_s_0)), "]"));
  const _x_22 = (_x_20 || _x_21);
  const _x_23 = ($f_ascii_char_eq$(($f_head$(_s_0)), "}"));
  return $f_choose$((_x_22 || _x_23), run_clo((_x_24) => {
  return ((_d_0 - 1) >>> 0);
}), run_clo((_x_25) => {
  return _d_0;
}));
}))), {$: "Con", "head": {$: "FToken", "text": run_loop($f_symbol_text$(_s_0, _c_0, _acc_0)), "f_line": _l_0, "f_col": _c_0, "f_kind": 0}, "tail": _acc_0});
}));
}

function $f_fresh_result$(_r_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return $f_fresh_result_end$(($f_fresh_defs$(_book_0, 1)), _err_0, _imports_0);
}

function $has_name$(_ns_0, _name_0) {
  if (_ns_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ns_0["head"];
    const _t_0 = _ns_0["tail"];
    return $kc$(($String$eq$(_h_0, _name_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $has_name$(_t_0, _name_0);
}));
  }
}

function $f_load_source$(_name_0, _ns_0, _source_0, _sources_0, _seen_0, _stack_0) {
  return $f_choose$(($String$is_empty$(($f_source_name$(_source_0)))), run_clo((_x_0) => {
  return {$: "FLoaded", "book": {$: "Nil"}, "error": ("module source not supplied: " + _name_0), "seen": _seen_0};
}), run_clo((_x_1) => {
  return $f_load_parsed$(_name_0, ($f_path_result$(($f_parse_at$(($f_source_text$(_source_0)), _ns_0)), ($f_source_path$(_source_0)), ($f_eq$(_name_0, "Base")))), _sources_0, _seen_0, _stack_0);
}));
}

function $ka_def$(_book_0, _d_0) {
  const _x_0 = ($String$eq$(($tg$(($dv$(_d_0)))), "Absent"));
  const _x_1 = ($String$eq$(($tg$(($dv$(_d_0)))), "Foreign"));
  const _x_2 = ($dx$(_d_0));
  const _x_3 = (_x_0 || _x_1);
  const _x_4 = (_x_2 > 0);
  return {$: "KDef", "name": ($dn$(_d_0)), "kind": ($dk$(_d_0)), "arity": ($da$(_d_0)), "templates": ($dx$(_d_0)), "typ": ($dt$(_d_0)), "value": run_loop($kc$((_x_3 || _x_4), run_clo((_x_5) => {
  return $dv$(_d_0);
}), run_clo((_x_6) => {
  return $annotate$({$: "KEnv", "book": _book_0, "name": ($dn$(_d_0)), "lhs": ($ref$(($dn$(_d_0)))), "pending": 0, "quantities": {$: "Nil"}, "unsafe": ($du$(_d_0))}, {$: "Nil"}, ($dv$(_d_0)), ($dt$(_d_0)));
}))), "ctors": ($dc$(_d_0)), "native": ($db$(_d_0)), "unsafe": ($du$(_d_0))};
}

function $String$eq$fin$(_r_0) {
  const _t_0 = _r_0["fst"];
  const _c_0 = _r_0["snd"];
  return $Cmp$is_eq$(_c_0);
}

function $String$cmp$(_a_0, _b_0) {
  if (_a_0 === "") {
    if (_b_0 === "") {
      return {$: "Tuple", "fst": {$: "Tuple", "fst": "", "snd": ""}, "snd": {$: "EQ"}};
    } else {
      const _h_0 = (_b_0.codePointAt(0) > 0xFFFF ? _b_0.slice(0, 2) : _b_0[0]);
      const _t_0 = (_b_0.codePointAt(0) > 0xFFFF ? _b_0.slice(2) : _b_0.slice(1));
      return {$: "Tuple", "fst": {$: "Tuple", "fst": "", "snd": (_h_0 + _t_0)}, "snd": {$: "LT"}};
    }
  } else {
    const _h_1 = (_a_0.codePointAt(0) > 0xFFFF ? _a_0.slice(0, 2) : _a_0[0]);
    const _t_1 = (_a_0.codePointAt(0) > 0xFFFF ? _a_0.slice(2) : _a_0.slice(1));
    if (_b_0 === "") {
      return {$: "Tuple", "fst": {$: "Tuple", "fst": (_h_1 + _t_1), "snd": ""}, "snd": {$: "GT"}};
    } else {
      const _h2_0 = (_b_0.codePointAt(0) > 0xFFFF ? _b_0.slice(0, 2) : _b_0[0]);
      const _t2_0 = (_b_0.codePointAt(0) > 0xFFFF ? _b_0.slice(2) : _b_0.slice(1));
      return $String$cmp$fin$(_t_1, _t2_0, ($Char$cmp$(_h_1, _h2_0)));
    }
  }
}

function $j_l_names$(_names_0) {
  if (_names_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _names_0["head"];
    return $kc$(($String$starts_with$(_h_0, "$js.")), run_clo((_x_0) => {
  return _h_0;
}), run_clo((_x_1) => {
  return "";
}));
  }
}

function $rm$(_t_0) {
  const _removed_0 = _t_0["removed"];
  return _removed_0;
}

function $j_escape$(_s_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _c_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_0 = ($j_escape_char$(_c_0));
    const _x_1 = ($j_escape$(_t_0));
    return (_x_0 + _x_1);
  }
}

function $j_local$(_id_0) {
  const _x_0 = ($U32$show$(_id_0));
  return ("x" + _x_0);
}

function $ix$(_t_0) {
  const _id_0 = _t_0["id"];
  return _id_0;
}

function $j_apply$(_book_0, _env_0, _t_0, _tail_0, _fty_0) {
  return $j_apply_spine$(_book_0, _env_0, _t_0, _tail_0, _fty_0, run_loop($j_call_spine$(_t_0, {$: "Nil"})));
}

function $j_type$(_book_0, _env_0, _t_0) {
  return $j_type_on$(_book_0, _env_0, _t_0, ($tg$(_t_0)));
}

function $kid$(_t_0, _n_0) {
  return $terms_at$(($ks$(_t_0)), _n_0);
}

function $core_nat$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "LitNat")), run_clo((_x_0) => {
  const _x_1 = ($ix$(_t_0));
  const _x_2 = ($qt$(_t_0));
  const _x_3 = ((_x_2 + 0) >>> 0);
  const _x_4 = ($qt$(_t_0));
  const _x_5 = ($terms_len$(($ks$(_t_0))));
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($nm$(_t_0)), "")), (_x_1 === 0))), (_x_3 === _x_4))), (_x_5 === 0))), ($List$is_empty$(($rm$(_t_0)))));
}), run_clo((_x_6) => {
  return false;
}));
}

function $j_constructor_mode$(_book_0, _env_0, _t_0, _ty_0, _tail_0) {
  return $kc$(($Bool$and$(_tail_0, ($String$eq$(run_loop($j_literal_typed$(_book_0, _t_0, _ty_0)), "")))), run_clo((_x_0) => {
  const _x_1 = ($j_ctor_thunks$(_book_0, _env_0, ($ks$(_t_0)), ($j_specialize$(_book_0, ($dt$(run_loop($j_find_ctor$(_book_0, ($nm$(_t_0)))))), ($ks$(run_loop($wnf$(_book_0, _ty_0))))))));
  const _x_2 = (_x_1 + "])");
  const _x_3 = ($j_quote$(($nm$(_t_0))));
  const _x_4 = (",[" + _x_2);
  const _x_5 = (_x_3 + _x_4);
  return ("build(" + _x_5);
}), run_clo((_x_6) => {
  return $j_constructor$(_book_0, _env_0, _t_0, _ty_0);
}));
}

function $j_lambda$(_book_0, _env_0, _t_0, _ty_0) {
  const _x_0 = run_loop($j_lambda_code$(_book_0, _env_0, _t_0, _ty_0, 0));
  const _x_1 = (_x_0 + "})");
  const _x_2 = ($U32$show$(run_loop($j_lambda_count$(_t_0))));
  const _x_3 = (",function(a){" + _x_1);
  const _x_4 = (_x_2 + _x_3);
  return ("fn(" + _x_4);
}

function $j_match$(_book_0, _env_0, _t_0, _ty_0) {
  const _x_0 = ($j_constructor_count$(_book_0, run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0))))));
  return $kc$((_x_0 === 1), run_clo((_x_1) => {
  const _x_2 = run_loop($j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($j_arm_type$(_book_0, _ty_0, ($nm$(_t_0)))), false));
  const _x_3 = (_x_2 + ")");
  const _x_4 = ($j_quote$(($nm$(_t_0))));
  const _x_5 = (",()=>" + _x_3);
  const _x_6 = (_x_4 + _x_5);
  return ("matcher1(" + _x_6);
}), run_clo((_x_7) => {
  const _x_8 = run_loop($j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 1)), _ty_0, false));
  const _x_9 = (_x_8 + ")");
  const _x_10 = run_loop($j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($j_arm_type$(_book_0, _ty_0, ($nm$(_t_0)))), false));
  const _x_11 = (",()=>" + _x_9);
  const _x_12 = (_x_10 + _x_11);
  const _x_13 = ($j_quote$(($nm$(_t_0))));
  const _x_14 = (",()=>" + _x_12);
  const _x_15 = (_x_13 + _x_14);
  return ("matcher(" + _x_15);
}));
}

function $j_let$(_book_0, _env_0, _xs_0, _ty_0, _tail_0) {
  const _x_0 = ($j_let_values$(_book_0, _env_0, _xs_0));
  const _x_1 = (_x_0 + ")");
  const _x_2 = run_loop($j_expr$(_book_0, ($j_context$(_book_0, _env_0, _xs_0)), ($j_body$(_xs_0)), _ty_0, _tail_0));
  const _x_3 = (")(" + _x_1);
  const _x_4 = (_x_2 + _x_3);
  const _x_5 = ($j_bindings$(_book_0, _env_0, _xs_0));
  const _x_6 = (")=>" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  return ("((" + _x_7);
}

function $j_exprs$(_book_0, _env_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    const _x_0 = run_loop($j_expr$(_book_0, _env_0, _h_0, ($atom$("Absent")), false));
    const _x_1 = ($j_exprs_tail$(_book_0, _env_0, _rest_0));
    return (_x_0 + _x_1);
  }
}

function $U32$show$(_a_0) {
  const _b_0 = _a_0;
  return $U32$show$if$(_b_0, (_b_0 === 0));
}

function $qt$(_t_0) {
  const _quant_0 = _t_0["quant"];
  return _quant_0;
}

function $j_desc_head$(_book_0, _ty_0, _fuel_0) {
  return $j_desc_head_on$(_book_0, _ty_0, _fuel_0, ($nm$(_ty_0)));
}

function $norm_eval$(_book_0, _t_0, _args_0, _left_0, _fallback_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  return $norm_var$(_book_0, _t_0, ($ks$(_t_0)), _args_0, _left_0, _fallback_0);
}), run_clo((_x_1) => {
  return $norm_eval_node$(_book_0, _t_0, _args_0, _left_0, _fallback_0);
}));
}

function $missing$() {
  return {$: "KDef", "name": "", "kind": "Absent", "arity": 0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": false, "unsafe": false};
}

function $index_lookup$(_cache_0, _name_0) {
  return $index_find$(($index_first$(($dc$(_cache_0)))), _name_0, ($index_hash$(_name_0, 2166136261)), 32);
}

function $j_io_shadow_def$(_book_0, _d_0) {
  return $book_put$(_book_0, {$: "KDef", "name": ($dn$(_d_0)), "kind": ($dk$(_d_0)), "arity": ($da$(_d_0)), "templates": ($dx$(_d_0)), "typ": ($dt$(_d_0)), "value": ($atom$("Absent")), "ctors": ($dc$(_d_0)), "native": ($db$(_d_0)), "unsafe": ($du$(_d_0))});
}

function $j_module_export$(_name_0, _implementation_0) {
  const _x_0 = (_implementation_0 + ":undefined,");
  const _x_1 = ("===\"function\"?" + _x_0);
  const _x_2 = (_implementation_0 + _x_1);
  const _x_3 = ($j_quote$(_name_0));
  const _x_4 = (":typeof " + _x_2);
  return (_x_3 + _x_4);
}

function $j_foreign_name$(_name_0) {
  return $j_foreign_chars$(($String$to_lower$(_name_0)));
}

function $book_final_fast$(_book_0, _done_0) {
  return $kc$(run_loop($book_final_large$(_book_0, 256)), run_clo((_x_0) => {
  return $kc$(run_loop($book_final_names_valid$(_book_0)), run_clo((_x_1) => {
  return $kc$(run_loop($book_final_names_valid$(_done_0)), run_clo((_x_2) => {
  return $book_final_scan$(($book_final_reverse$(_book_0, {$: "Nil"})), ($missing$()), {$: "Nil"}, _done_0);
}), run_clo((_x_3) => {
  return $book_final_legacy$(_book_0, _done_0);
}));
}), run_clo((_x_4) => {
  return $book_final_legacy$(_book_0, _done_0);
}));
}), run_clo((_x_5) => {
  return $book_final_legacy$(_book_0, _done_0);
}));
}

function $kp_go$(_t_0, _p_0, _env_0) {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  return $kp_scope$(_env_0, ($ix$(_t_0)), ($nm$(_t_0)));
}), run_clo((_x_1) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Ref")), run_clo((_x_2) => {
  const _x_5 = ($qt$(_t_0));
  const _x_8 = run_loop($kc$(($kp_bound$(_env_0, ($nm$(_t_0)))), run_clo((_x_3) => {
  return "^";
}), run_clo((_x_4) => {
  return "";
})));
  const _x_9 = run_loop($kc$((_x_5 === 3), run_clo((_x_6) => {
  return "!";
}), run_clo((_x_7) => {
  return "";
})));
  const _x_10 = ($nm$(_t_0));
  const _x_11 = (_x_8 + _x_9);
  return (_x_10 + _x_11);
}), run_clo((_x_12) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Typ")), run_clo((_x_13) => {
  const _x_14 = ($qt$(run_loop($kid$(_t_0, 0))));
  return $kc$(($Bool$and$(($kp_eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Qua")), (_x_14 === 1))), run_clo((_x_15) => {
  return "Type";
}), run_clo((_x_16) => {
  const _x_17 = ($qt$(run_loop($kid$(_t_0, 0))));
  return $kc$(($Bool$and$(($kp_eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Qua")), (_x_17 === 2))), run_clo((_x_18) => {
  return "Data";
}), run_clo((_x_19) => {
  const _x_20 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 1, _env_0));
  const _x_21 = (_x_20 + ")");
  return ("Kind(" + _x_21);
}));
}));
}), run_clo((_x_22) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Qnt")), run_clo((_x_23) => {
  return "Quant";
}), run_clo((_x_24) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Qua")), run_clo((_x_25) => {
  const _x_26 = ($U32$show$(($qt$(_t_0))));
  return ("&" + _x_26);
}), run_clo((_x_27) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Min")), run_clo((_x_28) => {
  const _x_29 = run_loop($kp_go$(run_loop($kid$(_t_0, 1)), 3, _env_0));
  const _x_30 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 3, _env_0));
  const _x_31 = (" <&> " + _x_29);
  return $kp_par$((_x_30 + _x_31), (_p_0 > 2));
}), run_clo((_x_32) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "All")), run_clo((_x_33) => {
  const _x_34 = run_loop($kp_go$(run_loop($kid$(_t_0, 1)), 2, ($kp_bind$(_env_0, _t_0))));
  const _x_35 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 3, _env_0));
  const _x_36 = (" -> " + _x_34);
  const _x_37 = (_x_35 + _x_36);
  const _x_38 = ($nm$(_t_0));
  const _x_39 = (":" + _x_37);
  const _x_40 = run_loop($kp_quant$(($qt$(_t_0))));
  const _x_41 = (_x_38 + _x_39);
  const _x_42 = (_x_40 + _x_41);
  return $kp_par$(("@" + _x_42), (_p_0 > 2));
}), run_clo((_x_43) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Lam")), run_clo((_x_44) => {
  const _x_45 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 0, ($kp_bind$(_env_0, _t_0))));
  const _x_46 = ($nm$(_t_0));
  const _x_47 = (" => " + _x_45);
  const _x_48 = run_loop($kp_quant$(($qt$(_t_0))));
  const _x_49 = (_x_46 + _x_47);
  return $kp_par$((_x_48 + _x_49), (_p_0 > 1));
}), run_clo((_x_50) => {
  return $kp_go_tail$(_t_0, _p_0, _env_0);
}));
}));
}));
}));
}));
}));
}));
}));
}

function $graph_strong$(_book_0, _t_0) {
  return $g_start$(_book_0, _t_0, run_loop($norm_max$(run_loop($norm_book_bound$(_book_0)), ($norm_max_term$(_t_0)))));
}

function $driver_holes$(_t_0) {
  const _x_2 = run_loop($kc$(($String$eq$(($tg$(_t_0)), "Hol")), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  return 0;
})));
  const _x_3 = ($driver_holes_terms$(($ks$(_t_0))));
  return ((_x_2 + _x_3) >>> 0);
}

function $dc$(_d_0) {
  const _ctors_0 = _d_0["ctors"];
  return _ctors_0;
}

function $driver_owned_name$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return false;
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_0 = ($Bool$and$(($String$eq$(($dn$(_d_0)), _name_0)), ($Bool$not$(($db$(_d_0))))));
    const _x_1 = ($driver_owned_name$(_rest_0, _name_0));
    return (_x_0 || _x_1);
  }
}

function $index_remove$(_ds_0, _name_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return $kc$(($String$eq$(($dn$(_h_0)), _name_0)), run_clo((_x_0) => {
  return $index_remove$(_rest_0, _name_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": _h_0, "tail": run_loop($index_remove$(_rest_0, _name_0))};
}));
  }
}

function $sp_book$(_st_0) {
  const _book_0 = _st_0["book"];
  return _book_0;
}

function $sp_error$(_st_0) {
  const _error_0 = _st_0["error"];
  return _error_0;
}

function $sp_definition_next$(_rest_0, _st_0, _d_0) {
  const _x_0 = ($dx$(_d_0));
  const _x_1 = (_x_0 > 0);
  const _x_2 = ($String$eq$(($tg$(($dv$(_d_0)))), "Absent"));
  const _x_3 = (_x_1 || _x_2);
  const _x_4 = ($String$eq$(($dk$(_d_0)), "ADT"));
  const _x_5 = (_x_3 || _x_4);
  const _x_6 = ($Bool$not$(run_loop($sp_needed$(($sp_templates$(_st_0)), ($dv$(_d_0))))));
  return $kc$((_x_5 || _x_6), run_clo((_x_7) => {
  return $sp_definition_install$(_rest_0, _st_0, _d_0);
}), run_clo((_x_8) => {
  return $sp_definition_done$(_rest_0, _d_0, run_loop($sp_term$(_st_0, ($dv$(_d_0)), {$: "Nil"}, ($dt$(_d_0)), ($dn$(_d_0)), 0)));
}));
}

function $sp_stamp$(_book_0, _bound_0) {
  return {$: "Con", "head": {$: "KDef", "name": "$kernel.max-id", "kind": "BookBound", "arity": _bound_0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": false, "unsafe": false}, "tail": run_loop($index_remove$(_book_0, "$kernel.max-id"))};
}

function $check_declarations$($0, $1) {
  for (;;) {
    {
      const _todo_0 = $0;
      const _done_0 = $1;
      if (_todo_0.$ === "Nil") {
        return _done_0;
      } else {
        const _d_0 = _todo_0["head"];
        const _rest_0 = _todo_0["tail"];
        $0 = _rest_0;
        $1 = run_loop($book_put$(_done_0, run_loop($kc$(($String$eq$(($tg$(($dv$(_d_0)))), "Foreign")), run_clo((_x_0) => {
  return _d_0;
}), run_clo((_x_1) => {
  return $declared$(_d_0);
})))));
        continue;
      }
    }
  }
}

function $sp_template_book$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_0 = ($dx$(_h_0));
    return $kc$((_x_0 > 0), run_clo((_x_1) => {
  return {$: "Con", "head": _h_0, "tail": run_loop($sp_template_book$(_rest_0))};
}), run_clo((_x_2) => {
  return $sp_template_book$(_rest_0);
}));
  }
}

function $norm_max_defs$($0, $1) {
  for (;;) {
    {
      const _todo_0 = $0;
      const _bound_0 = $1;
      if (_todo_0.$ === "Nil") {
        return _bound_0;
      } else {
        const _h_0 = _todo_0["head"];
        const _rest_0 = _todo_0["tail"];
        $0 = ($norm_defs_join$(($dc$(_h_0)), _rest_0));
        $1 = run_loop($norm_max$(_bound_0, run_loop($norm_max$(($norm_max_term$(($dt$(_h_0)))), ($norm_max_term$(($dv$(_h_0))))))));
        continue;
      }
    }
  }
}

function $nb_contains$(_xs_0, _k_0) {
  if (_xs_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    const _x_0 = ($String$eq$(_h_0, _k_0));
    const _x_1 = ($nb_contains$(_t_0, _k_0));
    return (_x_0 || _x_1);
  }
}

function $book_put$(_book_0, _d_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Con", "head": _d_0, "tail": {$: "Nil"}};
  } else {
    const _h_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($String$eq$(($dk$(_h_0)), "BookCache")), run_clo((_x_0) => {
  return {$: "Con", "head": {$: "KDef", "name": ($dn$(_h_0)), "kind": ($dk$(_h_0)), "arity": ($da$(_h_0)), "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Con", "head": run_loop($index_set$(($index_first$(($dc$(_h_0)))), _d_0, ($index_hash$(($dn$(_d_0)), 2166136261)), 32)), "tail": {$: "Nil"}}, "native": true, "unsafe": false}, "tail": {$: "Con", "head": _d_0, "tail": run_loop($index_put_rest$(_h_0, _rest_0, ($dn$(_d_0))))}};
}), run_clo((_x_1) => {
  return {$: "Con", "head": _d_0, "tail": run_loop($index_remove$({$: "Con", "head": _h_0, "tail": _rest_0}, ($dn$(_d_0))))};
}));
  }
}

function $da$(_d_0) {
  const _arity_0 = _d_0["arity"];
  return _arity_0;
}

function $dx$(_d_0) {
  const _templates_0 = _d_0["templates"];
  return _templates_0;
}

function $du$(_d_0) {
  const _unsafe_0 = _d_0["unsafe"];
  return _unsafe_0;
}

function $nc_add_ctors$($0, $1) {
  for (;;) {
    {
      const _cs_0 = $0;
      const _acc_0 = $1;
      if (_cs_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _t_0 = _cs_0["head"];
        const _k_0 = _t_0["name"];
        const _a_0 = _t_0["arity"];
        const _h_0 = _t_0["hot"];
        const _rest_0 = _cs_0["tail"];
        $0 = _rest_0;
        $1 = run_loop($nt_choose$(($nc_has_ctor$(_acc_0, _k_0)), run_clo((_x_0) => {
  return _acc_0;
}), run_clo((_x_1) => {
  return $List$append$(_acc_0, {$: "Con", "head": {$: "N_Constructor", "name": _k_0, "arity": _a_0, "hot": _h_0}, "tail": {$: "Nil"}});
})));
        continue;
      }
    }
  }
}

function $nc_default_ctors$() {
  return {$: "Con", "head": {$: "N_Constructor", "name": "Tuple", "arity": 2, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "SNil", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "SCon", "arity": 2, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "WCon", "arity": 2, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "WNil", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "Emit", "arity": 1, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "Halt", "arity": 2, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "Done", "arity": 1, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "Fail", "arity": 1, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "Some", "arity": 1, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "None", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "True", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "False", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "Unit", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "LT", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "EQ", "arity": 0, "hot": true}, "tail": {$: "Con", "head": {$: "N_Constructor", "name": "GT", "arity": 0, "hot": true}, "tail": {$: "Nil"}}}}}}}}}}}}}}}}}};
}

function $nc_with_show$(_ss_0, _cs_0, _runtime_0, _requests_0, _pure_0, _d_0) {
  const _src_0 = _d_0["source"];
  const _err_0 = _d_0["error"];
  return $nt_choose$(($String$eq$(run_loop($nv_first$(_err_0, run_loop($nv_program$(_ss_0, _cs_0)))), "")), run_clo((_x_0) => {
  return {$: "NC_Result", "source": run_loop($ne_program$(_runtime_0, {$: "N_Program", "segments": _ss_0, "constructors": _cs_0, "image": {$: "Nil"}, "requests": _requests_0, "declarations": ($nc_helpers$()), "show": _src_0, "pure": _pure_0})), "error": ""};
}), run_clo((_x_1) => {
  return {$: "NC_Result", "source": "", "error": run_loop($nv_first$(_err_0, run_loop($nv_program$(_ss_0, _cs_0))))};
}));
}

function $nc_show_program$(_book_0, _ty_0, _cs_0) {
  return $nc_show_finish$(_cs_0, run_loop($nc_show_nodes$(_book_0, {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}, 0, 0, "", {$: "Nil"})));
}

function $nc_show$(_cells_0) {
  const _x_0 = (_cells_0 + " };\nstatic const char* SHOW_NAMES[] = {\"False\", \"True\", \"Unit\"};\n#endif\n");
  return ("#if !DEVICE\nstatic const u32 SHOW_DESC[] = { " + _x_0);
}

function $nc_compile_def$(_book_0, _name_0, _todo_0, _done_0, _n_0, _bangs_0) {
  const _d_0 = run_loop($lookup$(_book_0, _name_0));
  const _body_0 = run_loop($nc_compact$(run_loop($nc_definition$(_book_0, _d_0, _n_0))));
  const _refs_0 = ($nc_refs$(_body_0));
  const _calls_0 = ($nc_mapped_refs$(_book_0, _refs_0));
  const _forked_0 = run_loop($nc_term_fork$(_body_0));
  const _code_0 = ($nc_mark_code$(run_loop($nd_extend$(_book_0, _body_0, ($nc_lower$(_book_0, _body_0, {$: "Nil"}, ((_n_0 + 1024) >>> 0))), _name_0)), ($nb_contains$(_bangs_0, _name_0)), _forked_0, _calls_0));
  return $nt_choose$(($String$eq$(($dk$(_d_0)), "Absent")), run_clo((_x_0) => {
  return {$: "NC_Book", "segments": {$: "Nil"}, "fresh": _n_0, "error": ("native definition not found: " + _name_0)};
}), run_clo((_x_1) => {
  return $nc_append_book$(_code_0, run_loop($nc_ref_name$(_book_0, _name_0)), _calls_0, _forked_0, run_loop($nc_compile_defs$(_book_0, ($List$append$(_refs_0, _todo_0)), {$: "Con", "head": _name_0, "tail": _done_0}, ($nc_fresh$(_code_0)), _bangs_0)));
}));
}

function $List$append$(_xs_0, _ys_0) {
  if (_xs_0.$ === "Nil") {
    return _ys_0;
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    return {$: "Con", "head": _h_0, "tail": ($List$append$(_t_0, _ys_0))};
  }
}

function $nc_bangs_term$(_t_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  const _x_2 = ($qt$(_t_0));
  return $nt_choose$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ref")), (_x_2 === 3))), run_clo((_x_3) => {
  return {$: "Con", "head": ($nm$(_t_0)), "tail": {$: "Nil"}};
}), run_clo((_x_4) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_5) => {
  return $nc_bangs_term$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_6) => {
  return $nc_bangs_terms$(($ks$(_t_0)));
}));
}));
}));
}

function $nc_c_paths$(_paths_0) {
  if (_paths_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _paths_0["head"];
    const _rest_0 = _paths_0["tail"];
    return $nt_choose$(($String$ends_with$(($nm$(_h_0)), ".c")), run_clo((_x_0) => {
  return {$: "Con", "head": ($nm$(_h_0)), "tail": run_loop($nc_c_paths$(_rest_0))};
}), run_clo((_x_1) => {
  return $nc_c_paths$(_rest_0);
}));
  }
}

function $nc_refs$(_t_0) {
  return $nc_refs_go$({$: "Con", "head": _t_0, "tail": {$: "Nil"}}, {$: "Nil"});
}

function $nc_definition$(_book_0, _d_0, _n_0) {
  const _prim_0 = ($nc_primitive_name$(($dn$(_d_0))));
  return $nt_choose$(($nc_native_def$(_d_0)), run_clo((_x_0) => {
  return $nc_primitive_body$(_prim_0);
}), run_clo((_x_1) => {
  return $nt_choose$(($nc_foreign$(_d_0)), run_clo((_x_2) => {
  return $nc_foreign_tel$(_book_0, ($dt$(_d_0)), ($dn$(_d_0)), {$: "Nil"}, _n_0);
}), run_clo((_x_3) => {
  return $nc_erase$(_book_0, ($dv$(_d_0)));
}));
}));
}

function $nc_primitive_name$(_k_0) {
  return $String$to_lower$(($nt_clean$(_k_0)));
}

function $ni_find$(_k_0, _ops_0) {
  if (_ops_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _ops_0["head"];
    const _n_0 = _t_0["name"];
    const _t_1 = _t_0["template"];
    const _rest_0 = _ops_0["tail"];
    return $nt_choose$(($String$eq$(_k_0, _n_0)), run_clo((_x_0) => {
  return _t_1;
}), run_clo((_x_1) => {
  return $ni_find$(_k_0, _rest_0);
}));
  }
}

function $ni_templates$() {
  return {$: "Con", "head": {$: "ni_Op", "name": "u32_add", "template": "U32_BIN($0, +, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_sub", "template": "U32_BIN($0, -, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_and", "template": "U32_BIN($0, &, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_or", "template": "U32_BIN($0, |, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_xor", "template": "U32_BIN($0, ^, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_mul", "template": "U32_BIN($0, *, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_eq", "template": "U32_BIN($0, ==, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_ne", "template": "U32_BIN($0, !=, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_lt", "template": "U32_BIN($0, <, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_le", "template": "U32_BIN($0, <=, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_gt", "template": "U32_BIN($0, >, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_ge", "template": "U32_BIN($0, >=, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_inc", "template": "U32_BIN($0, +, 1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_shl", "template": "U32_BIN($0, <<, 1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_shr", "template": "U32_BIN($0, >>, 1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_shln", "template": "($1 >= 32 ? 0 : U32_BIN($0, <<, $1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_shrn", "template": "($1 >= 32 ? 0 : U32_BIN($0, >>, $1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_div", "template": "((u32)($1) == 0 ? 0 : (u64)U32_QUO((u32)($0), (u32)($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_mod", "template": "((u32)($1) == 0 ? $0 : U32_BIN($0, -, U32_QUO((u32)($0), (u32)($1)) * $1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_not", "template": "((u64)~(u32)($0))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_is_zero", "template": "U32_BIN($0, ==, 0)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_cmp", "template": "(U32_BIN($0, >, $1) + U32_BIN($0, >=, $1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_to_f32", "template": "f32_rewrap((f32)(u32)($0))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_to_nat", "template": "$0"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "u32_from_nat", "template": "((u64)(u32)($0))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_add", "template": "f32_rewrap(f32_unbox($0) + f32_unbox($1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_sub", "template": "f32_rewrap(f32_unbox($0) - f32_unbox($1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_mul", "template": "f32_rewrap(f32_unbox($0) * f32_unbox($1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_div", "template": "f32_rewrap(f32_unbox($0) / f32_unbox($1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_is_eq", "template": "((u64)(f32_unbox($0) == f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_is_ne", "template": "((u64)(f32_unbox($0) != f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_is_lt", "template": "((u64)(f32_unbox($0) < f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_is_le", "template": "((u64)(f32_unbox($0) <= f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_is_gt", "template": "((u64)(f32_unbox($0) > f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_is_ge", "template": "((u64)(f32_unbox($0) >= f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_sqrt", "template": "f32_rewrap((f32)sqrt(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_exp", "template": "f32_rewrap((f32)exp(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_log", "template": "f32_rewrap((f32)log(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_log2", "template": "f32_rewrap((f32)log2(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_log10", "template": "f32_rewrap((f32)log10(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_sin", "template": "f32_rewrap((f32)sin(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_cos", "template": "f32_rewrap((f32)cos(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_tan", "template": "f32_rewrap((f32)tan(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_asin", "template": "f32_rewrap((f32)asin(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_acos", "template": "f32_rewrap((f32)acos(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_atan", "template": "f32_rewrap((f32)atan(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_sinh", "template": "f32_rewrap((f32)sinh(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_cosh", "template": "f32_rewrap((f32)cosh(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_tanh", "template": "f32_rewrap((f32)tanh(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_floor", "template": "f32_rewrap((f32)floor(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_ceil", "template": "f32_rewrap((f32)ceil(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_trunc", "template": "f32_rewrap((f32)trunc(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_abs", "template": "f32_rewrap((f32)fabs(f32_unbox($0)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_pow", "template": "f32_rewrap((f32)pow(f32_unbox($0), f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_atan2", "template": "f32_rewrap((f32)atan2(f32_unbox($0), f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_mod", "template": "f32_rewrap((f32)fmod(f32_unbox($0), f32_unbox($1)))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_neg", "template": "f32_rewrap(-f32_unbox($0))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_to_u32", "template": "f32_to_u32($0)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_bits", "template": "$0"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_show", "template": "f32_show(e, $0)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "f32_read", "template": "f32_read(e, $0)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "nat_add", "template": "nat_chk(e, $0 + $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "nat_sub", "template": "($0 < $1 ? 0 : $0 - $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "nat_mul", "template": "nat_mul(e, $0, $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "nat_double", "template": "nat_chk(e, $0 + $0)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "nat_cmp", "template": "(($0 > $1) + ($0 >= $1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "nat_is_lt", "template": "($0 < $1)"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "bool_or", "template": "(native_bool($0) | native_bool($1))"}, "tail": {$: "Con", "head": {$: "ni_Op", "name": "bool_xor", "template": "(native_bool($0) ^ native_bool($1))"}, "tail": {$: "Nil"}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}};
}

function $nc_array_known$(_k_0) {
  const _x_0 = ($String$eq$(_k_0, "array_new"));
  const _x_1 = ($String$eq$(_k_0, "array_get"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(_k_0, "array_set"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($String$eq$(_k_0, "array_swap"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($String$eq$(_k_0, "array_size"));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($String$eq$(_k_0, "array_clone"));
  return (_x_8 || _x_9);
}

function $nc_context_pick$(_original_0, _annotated_0) {
  return $nt_choose$(($String$eq$(($dk$(_annotated_0)), "Absent")), run_clo((_x_0) => {
  return _original_0;
}), run_clo((_x_1) => {
  return _annotated_0;
}));
}

function $nc_context_has_cache$(_annotated_0) {
  if (_annotated_0.$ === "Nil") {
    return false;
  } else {
    const _head_0 = _annotated_0["head"];
    const _rest_0 = _annotated_0["tail"];
    return $nt_choose$(($String$eq$(($dk$(_head_0)), "BookCache")), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $nc_context_has_cache$(_rest_0);
}));
  }
}

function $nc_foreign_has$(_paths_0, _path_0) {
  if (_paths_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _paths_0["head"];
    const _rest_0 = _paths_0["tail"];
    const _x_0 = ($String$eq$(($nm$(_h_0)), _path_0));
    const _x_1 = ($nc_foreign_has$(_rest_0, _path_0));
    return (_x_0 || _x_1);
  }
}

function $nt_fid$(_k_0) {
  const _x_0 = ($String$to_upper$(($nt_clean$(_k_0))));
  return ("FID_" + _x_0);
}

function $nc_ref_name$(_book_0, _name_0) {
  return $nt_choose$(($nc_native_def$(run_loop($lookup$(_book_0, _name_0)))), run_clo((_x_0) => {
  return ("$native." + _name_0);
}), run_clo((_x_1) => {
  return _name_0;
}));
}

function $nt_cid$(_k_0) {
  const _x_0 = ($String$to_upper$(($nt_clean$(_k_0))));
  return ("CID_" + _x_0);
}

function $nc_ctor_identity$(_book_0, _name_0) {
  return $kc$(run_loop($nc_ctor_owned$(_book_0, _name_0)), run_clo((_x_0) => {
  return _name_0;
}), run_clo((_x_1) => {
  return $nc_ctor_encode$(_name_0);
}));
}

function $nc_foreign_aliases$(_cs_0, _ns_0, _open_0) {
  if (_cs_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _cs_0["head"];
    const _name_0 = _t_0["name"];
    const _rest_0 = _cs_0["tail"];
    const _x_14 = run_loop($nt_choose$(($Bool$and$(($String$starts_with$(run_loop($nc_ctor_display$(_name_0)), _ns_0)), ($Bool$not$(($String$eq$(($nt_cid$(($String$drop$(run_loop($nc_ctor_display$(_name_0)), [..._ns_0].length)))), ($nt_cid$(_name_0)))))))), run_clo((_x_0) => {
  return $nt_choose$(_open_0, run_clo((_x_1) => {
  const _x_2 = ($nt_cid$(_name_0));
  const _x_3 = (_x_2 + "\n");
  const _x_4 = ($nt_cid$(($String$drop$(run_loop($nc_ctor_display$(_name_0)), [..._ns_0].length))));
  const _x_5 = (" " + _x_3);
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ($nt_cid$(($String$drop$(run_loop($nc_ctor_display$(_name_0)), [..._ns_0].length))));
  const _x_8 = ("\")\n#define " + _x_6);
  const _x_9 = (_x_7 + _x_8);
  return ("#pragma push_macro(\"" + _x_9);
}), run_clo((_x_10) => {
  const _x_11 = ($nt_cid$(($String$drop$(run_loop($nc_ctor_display$(_name_0)), [..._ns_0].length))));
  const _x_12 = (_x_11 + "\")\n");
  return ("#pragma pop_macro(\"" + _x_12);
}));
}), run_clo((_x_13) => {
  return "";
})));
    const _x_15 = ($nc_foreign_aliases$(_rest_0, _ns_0, _open_0));
    return (_x_14 + _x_15);
  }
}

function $nc_ctor_specs$(_book_0, _cs_0, _params_0) {
  if (_cs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _c_0 = _cs_0["head"];
    const _rest_0 = _cs_0["tail"];
    return {$: "Con", "head": {$: "N_Constructor", "name": run_loop($nc_ctor_identity$(_book_0, ($dn$(_c_0)))), "arity": run_loop($nc_live_count$(_book_0, run_loop($nc_skip_tel$(_book_0, ($dt$(_c_0)), _params_0)), ($da$(_c_0)))), "hot": true}, "tail": ($nc_ctor_specs$(_book_0, _rest_0, _params_0))};
  }
}

function $nc_foreign$(_d_0) {
  const _x_0 = ($String$eq$(($tg$(run_loop($nc_unann$(($dv$(_d_0)))))), "Foreign"));
  const _x_1 = ($String$eq$(($tg$(run_loop($nc_unann$(($dv$(_d_0)))))), "Absent"));
  return (_x_0 || _x_1);
}

function $nc_all_args$(_book_0, _ty_0) {
  const _tel_0 = run_loop($wnf$(_book_0, _ty_0));
  return $nt_choose$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_tel_0));
  const _x_2 = ($nt_bool$(($Bool$not$((_x_1 === 0)))));
  const _x_3 = run_loop($nc_all_args$(_book_0, run_loop($kid$(_tel_0, 1))));
  return ((_x_2 + _x_3) >>> 0);
}), run_clo((_x_4) => {
  return 0;
}));
}

function $nc_source_namespace$(_parts_0, _prefix_0, _source_0) {
  if (_parts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _parts_0["head"];
    const _rest_0 = _parts_0["tail"];
    return $nt_choose$(($nc_source_has_id$(_source_0, ($nt_cid$(($nt_join$({$: "Con", "head": _h_0, "tail": _rest_0}, ".")))))), run_clo((_x_0) => {
  return _prefix_0;
}), run_clo((_x_1) => {
  const _x_2 = (_h_0 + ".");
  return $nc_source_namespace$(_rest_0, (_prefix_0 + _x_2), _source_0);
}));
  }
}

function $String$split$(_s_0, _sep_0) {
  if (_s_0 === "") {
    return {$: "Con", "head": "", "tail": {$: "Nil"}};
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    return $String$split$fin$(_h_0, ($String$split$(_t_0, _sep_0)), ($Char$is_eq$(_h_0, _sep_0)));
  }
}

function $String$take$(_s_0, _n_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    if (_n_0 === 0) {
      return "";
    } else {
      const _p_0 = (_n_0 - 1);
      return (_h_0 + ($String$take$(_t_0, _p_0)));
    }
  }
}

function $exact_def$(_a_0, _b_0) {
  const _x_0 = ($da$(_a_0));
  const _x_1 = ($da$(_b_0));
  const _x_2 = ($dx$(_a_0));
  const _x_3 = ($dx$(_b_0));
  const _x_4 = ($db$(_a_0));
  const _x_5 = ($db$(_b_0));
  const _x_6 = ($du$(_a_0));
  const _x_7 = ($du$(_b_0));
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($dn$(_a_0)), ($dn$(_b_0)))), ($String$eq$(($dk$(_a_0)), ($dk$(_b_0)))))), (_x_0 === _x_1))), (_x_2 === _x_3))), ($Bool$not$((_x_4 !== _x_5))))), ($Bool$not$((_x_6 !== _x_7))))), ($exact_term$(($dt$(_a_0)), ($dt$(_b_0)))))), ($exact_term$(($dv$(_a_0)), ($dv$(_b_0)))))), ($exact_defs$(($dc$(_a_0)), ($dc$(_b_0)))));
}

function $fpe_graph_result$(_graph_0, _sources_0, _result_0) {
  const _book_0 = _graph_0["book"];
  const _error_0 = _graph_0["error"];
  const _done_0 = _graph_0["done"];
  return $f_choose$(($String$is_empty$(_error_0)), run_clo((_x_0) => {
  return $fpe_rejected$(_result_0, _book_0, _done_0, _sources_0);
}), run_clo((_x_1) => {
  return _result_0;
}));
}

function $f_graph_result$(_g_0) {
  const _book_0 = _g_0["book"];
  const _err_0 = _g_0["error"];
  return $f_fresh_result$(run_loop($f_graph_fresh_result$(($f_validate_result$({$: "FResult", "book": _book_0, "error": _err_0, "imports": {$: "Nil"}})))));
}

function $f_main_order$(_book_0, _seen_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $f_choose$(run_loop($has_name$(_seen_0, ($dn$(_d_0)))), run_clo((_x_0) => {
  return $f_main_order$(_rest_0, _seen_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": ($dn$(_d_0)), "tail": run_loop($f_main_order$(_rest_0, {$: "Con", "head": ($dn$(_d_0)), "tail": _seen_0}))};
}));
  }
}

function $f_eq$(_a_0, _b_0) {
  return $String$eq$(_a_0, _b_0);
}

function $f_source_name$(_source_0) {
  if (_source_0.$ === "FSource") {
    const _name_0 = _source_0["name"];
    return _name_0;
  } else {
    const _name_1 = _source_0["name"];
    return _name_1;
  }
}

function $kt$(_tag_0, _name_0, _id_0, _quant_0, _kids_0) {
  return {$: "KTerm", "tag": _tag_0, "name": _name_0, "id": _id_0, "quant": _quant_0, "kids": _kids_0, "removed": {$: "Nil"}};
}

function $index_set$(_tree_0, _d_0, _hash_0, _bits_0) {
  return $kc$(($String$eq$(($dk$(_tree_0)), "Absent")), run_clo((_x_0) => {
  return $index_leaf$(_d_0, _hash_0, {$: "Nil"});
}), run_clo((_x_1) => {
  const _x_2 = ($da$(run_loop($index_tip$(_tree_0, _hash_0))));
  return $index_insert$(_tree_0, _d_0, _hash_0, ($index_split_bit$(((_hash_0 ^ _x_2) >>> 0))));
}));
}

function $index_hash$($0, $1) {
  for (;;) {
    {
      const _name_0 = $0;
      const _acc_0 = $1;
      if (_name_0 === "") {
        return _acc_0;
      } else {
        const _h_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(0, 2) : _name_0[0]);
        const _rest_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(2) : _name_0.slice(1));
        const _x_0 = ($Char$to_u32$(_h_0));
        const _x_1 = ((_acc_0 ^ _x_0) >>> 0);
        $0 = _rest_0;
        $1 = (Math.imul(_x_1, 16777619) >>> 0);
        continue;
      }
    }
  }
}

function $f_seed_text_equal$(_a_0, _b_0) {
  if (_a_0 === "") {
    if (_b_0 === "") {
      return true;
    } else {
      return false;
    }
  } else {
    const _x_0 = (_a_0.codePointAt(0) > 0xFFFF ? _a_0.slice(0, 2) : _a_0[0]);
    const _xs_0 = (_a_0.codePointAt(0) > 0xFFFF ? _a_0.slice(2) : _a_0.slice(1));
    if (_b_0 !== "") {
      const _y_0 = (_b_0.codePointAt(0) > 0xFFFF ? _b_0.slice(0, 2) : _b_0[0]);
      const _ys_0 = (_b_0.codePointAt(0) > 0xFFFF ? _b_0.slice(2) : _b_0.slice(1));
      return $f_choose$(($Char$is_eq$(_x_0, _y_0)), run_clo((_x_1) => {
  return $f_seed_text_equal$(_xs_0, _ys_0);
}), run_clo((_x_2) => {
  return false;
}));
    } else {
      return false;
    }
  }
}

function $f_source_text$(_source_0) {
  if (_source_0.$ === "FSource") {
    const _text_0 = _source_0["text"];
    return _text_0;
  } else {
    const _text_1 = _source_0["text"];
    return _text_1;
  }
}

function $fs_source$(_s_0, _ns_0, _sources_0, _g_0, _stack_0, _seed_0) {
  const _book_0 = _g_0["book"];
  const _err_0 = _g_0["error"];
  const _done_0 = _g_0["done"];
  return $f_choose$(($Bool$not$(($String$is_empty$(_err_0)))), run_clo((_x_0) => {
  return {$: "FGraph", "book": _book_0, "error": _err_0, "done": _done_0};
}), run_clo((_x_1) => {
  return $f_choose$(($String$is_empty$(($f_source_path$(_s_0)))), run_clo((_x_2) => {
  return {$: "FGraph", "book": _book_0, "error": "module source was not supplied", "done": _done_0};
}), run_clo((_x_3) => {
  return $f_choose$(run_loop($has_name$(_stack_0, ($f_source_path$(_s_0)))), run_clo((_x_4) => {
  const _x_5 = ($f_source_path$(_s_0));
  return {$: "FGraph", "book": _book_0, "error": ("cyclic import through " + _x_5), "done": _done_0};
}), run_clo((_x_6) => {
  return $fs_cached$(_s_0, _ns_0, _sources_0, {$: "FGraph", "book": _book_0, "error": _err_0, "done": _done_0}, _stack_0, run_loop($f_env$(($f_source_path$(_s_0)), _done_0)), _seed_0);
}));
}));
}));
}

function $dr_count$(_names_0) {
  if (_names_0.$ === "Nil") {
    return 0;
  } else {
    const _rest_0 = _names_0["tail"];
    const _x_0 = ($dr_count$(_rest_0));
    return ((1 + _x_0) >>> 0);
  }
}

function $dr_lines$(_names_0) {
  if (_names_0.$ === "Nil") {
    return "";
  } else {
    const _name_0 = _names_0["head"];
    const _rest_0 = _names_0["tail"];
    const _x_0 = ($dr_lines$(_rest_0));
    const _x_1 = ("\n" + _x_0);
    const _x_2 = (_name_0 + _x_1);
    return ("- " + _x_2);
  }
}

function $dr_relies$(_book_0, _todo_0, _seen_0) {
  if (_todo_0.$ === "Nil") {
    return false;
  } else {
    const _name_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $kc$(run_loop($has_name$(_seen_0, _name_0)), run_clo((_x_0) => {
  return $dr_relies$(_book_0, _rest_0, _seen_0);
}), run_clo((_x_1) => {
  return $dr_relies_def$(_book_0, _rest_0, {$: "Con", "head": _name_0, "tail": _seen_0}, run_loop($kr_resolve$(_book_0, _name_0)));
}));
  }
}

function $dg_prefix_seed$($0, $1, $2, $3, $4, $5, $6) {
  let $pc = 2;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _origins_0 = $1;
      $0 = _book_0;
      $1 = {$: "Nil"};
      $2 = _origins_0;
      $3 = ($book_cached$({$: "Nil"}, ($norm_max_book$(_book_0))));
      $pc = 1; continue;
    }
    case 1: {
      const _book_0 = $0;
      const _validated_0 = $1;
      const _origins_0 = $2;
      const _seed_0 = $3;
      $0 = _book_0;
      $1 = _validated_0;
      $2 = ($check_declarations$(_book_0, _seed_0));
      $3 = _seed_0;
      $4 = _book_0;
      $5 = _origins_0;
      $pc = 2; continue;
    }
    case 2: {
      const _todo_0 = $0;
      const _validated_0 = $1;
      const _done_0 = $2;
      const _seen_0 = $3;
      const _original_0 = $4;
      const _origins_0 = $5;
      if (_validated_0.$ === "Nil") {
        return $dg_suffix_events$(_todo_0, _done_0, _seen_0, _original_0, _origins_0);
      } else {
        const _head_0 = _validated_0["head"];
        const _tail_0 = _validated_0["tail"];
        $0 = _todo_0;
        $1 = _head_0;
        $2 = _tail_0;
        $3 = _done_0;
        $4 = _seen_0;
        $5 = _original_0;
        $6 = _origins_0;
        $pc = 3; continue;
      }
    }
    case 3: {
      const _todo_0 = $0;
      const _head_0 = $1;
      const _tail_0 = $2;
      const _done_0 = $3;
      const _seen_0 = $4;
      const _original_0 = $5;
      const _origins_0 = $6;
      if (_todo_0.$ === "Nil") {
        $0 = _original_0;
        $1 = _origins_0;
        $pc = 0; continue;
      } else {
        const _rest_0 = _todo_0["tail"];
        $0 = _rest_0;
        $1 = _tail_0;
        $2 = run_loop($check_event_install$(_done_0, _head_0, _rest_0));
        $3 = run_loop($book_put$(_seen_0, _head_0));
        $4 = _original_0;
        $5 = _origins_0;
        $pc = 2; continue;
      }
    }
  }
}

function $terms_len$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _ts_0["tail"];
    const _x_0 = ($terms_len$(_t_0));
    return ((1 + _x_0) >>> 0);
  }
}

function $dg_render$(_book_0, _diagnostic_0) {
  const _expected_0 = _diagnostic_0["expected"];
  const _observed_0 = _diagnostic_0["observed"];
  const _has_observed_0 = _diagnostic_0["has_observed"];
  const _context_0 = _diagnostic_0["context"];
  const _definition_0 = _diagnostic_0["definition"];
  const _span_0 = _diagnostic_0["span"];
  const _note_0 = _diagnostic_0["note"];
  return $dg_render_parts$(_book_0, _expected_0, _observed_0, _has_observed_0, ($List$reverse$(_context_0)), _definition_0, _span_0, _note_0);
}

function $dg_has_span$(_s_0) {
  if (_s_0.$ === "DNoSpan") {
    return false;
  } else {
    return true;
  }
}

function $dg_origin_trail$(_origins_0, _name_0, _trail_0) {
  if (_trail_0.$ === "Nil") {
    return {$: "DNoSpan"};
  } else {
    const _h_0 = _trail_0["head"];
    const _rest_0 = _trail_0["tail"];
    return $dg_origin_found$(_origins_0, _name_0, _rest_0, run_loop($dg_origin_scan$(_origins_0, _name_0, _h_0, {$: "DNoSpan"})));
  }
}

function $fp_loaded_result$(_result_0, _done_0, _sources_0, _all_0, _definition_0) {
  const _book_0 = _result_0["book"];
  const _error_0 = _result_0["error"];
  const _imports_0 = _result_0["imports"];
  return {$: "FProvenance", "result": {$: "FResult", "book": _book_0, "error": _error_0, "imports": _imports_0}, "origins": run_loop($f_choose$(($String$is_empty$(_error_0)), run_clo((_x_0) => {
  return $fp_loaded_modules$(($List$reverse$(_done_0)), _book_0, _sources_0, _all_0, _definition_0);
}), run_clo((_x_1) => {
  return {$: "Nil"};
})))};
}

function $j_printable$(_book_0, _ty_0, _seen_0, _fuel_0) {
  return $j_printable_head$(_book_0, run_loop($wnf$(_book_0, _ty_0)), _seen_0, _fuel_0);
}

function $j_layout_def$(_book_0, _defs_0, _d_0, _todo_0, _seen_0, _stops_0) {
  const _x_0 = ($dx$(_d_0));
  return $j_layout_visit$(_book_0, _defs_0, run_loop($kc$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), (_x_0 === 0))), run_clo((_x_1) => {
  return $j_layout_term$(_book_0, {$: "Nil"}, ($dv$(_d_0)), ($dt$(_d_0)), _todo_0);
}), run_clo((_x_2) => {
  return _todo_0;
}))), _seen_0, _stops_0);
}

function $kr_visit_def$(_book_0, _todo_0, _seen_0, _stops_0, _d_0) {
  return $kc$(($String$eq$(($dk$(_d_0)), "Absent")), run_clo((_x_0) => {
  return $kr_visit$(_book_0, _todo_0, _seen_0, _stops_0);
}), run_clo((_x_1) => {
  return $kr_visit$(_book_0, ($kr_dependencies$(_d_0, _stops_0, _todo_0)), {$: "Con", "head": ($dn$(_d_0)), "tail": _seen_0}, _stops_0);
}));
}

function $kr_resolve$(_book_0, _name_0) {
  return $kr_resolve_head$(_book_0, _name_0, run_loop($lookup$(_book_0, _name_0)));
}

function $String$contains$($0, $1, $2) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _s_0 = $0;
      const _p_0 = $1;
      if (_s_0 === "") {
        return $String$is_empty$(_p_0);
      } else {
        const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        $0 = _t_0;
        $1 = _p_0;
        $2 = ($String$starts_with$((_h_0 + _t_0), _p_0));
        $pc = 1; continue;
      }
    }
    case 1: {
      const _t_0 = $0;
      const _p_0 = $1;
      const _here_0 = $2;
      if (!_here_0) {
        $0 = _t_0;
        $1 = _p_0;
        $pc = 0; continue;
      } else {
        return true;
      }
    }
  }
}

function $kf_namespaces$(_ds_0, _path_0, _ns_0, _seen_0) {
  if (_ds_0.$ === "Nil") {
    return $kt$("Namespace", _ns_0, 0, 0, {$: "Nil"});
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    const _value_0 = run_loop($kf_unann$(($dv$(_d_0))));
    return $kc$(($Bool$and$(($String$eq$(($tg$(_value_0)), "Foreign")), ($kf_has_path$(($ks$(_value_0)), _path_0)))), run_clo((_x_0) => {
  const _x_1 = ($db$(_d_0));
  const _x_2 = ($String$eq$(($nm$(_value_0)), ""));
  return $kf_namespace_step$(_rest_0, _path_0, _ns_0, _seen_0, run_loop($kc$((_x_1 || _x_2), run_clo((_x_3) => {
  return "";
}), run_clo((_x_4) => {
  const _x_5 = ($dn$(_d_0));
  const _x_6 = ($nm$(_value_0));
  const _x_7 = [..._x_5].length;
  const _x_8 = [..._x_6].length;
  return $String$take$(($dn$(_d_0)), (_x_7 < _x_8 ? 0 : _x_7 - _x_8));
}))));
}), run_clo((_x_9) => {
  return $kf_namespaces$(_rest_0, _path_0, _ns_0, _seen_0);
}));
  }
}

function $String$starts_with$($0, $1, $2) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _s_0 = $0;
      const _p_0 = $1;
      if (_s_0 === "") {
        if (_p_0 === "") {
          return true;
        } else {
          return false;
        }
      } else {
        const _h_1 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_1 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        if (_p_0 === "") {
          return true;
        } else {
          const _y_0 = (_p_0.codePointAt(0) > 0xFFFF ? _p_0.slice(0, 2) : _p_0[0]);
          const _yt_0 = (_p_0.codePointAt(0) > 0xFFFF ? _p_0.slice(2) : _p_0.slice(1));
          $0 = _t_1;
          $1 = _yt_0;
          $2 = ($Char$is_eq$(_h_1, _y_0));
          $pc = 1; continue;
        }
      }
    }
    case 1: {
      const _t_0 = $0;
      const _pt_0 = $1;
      const _same_0 = $2;
      if (!_same_0) {
        return false;
      } else {
        $0 = _t_0;
        $1 = _pt_0;
        $pc = 0; continue;
      }
    }
  }
}

function $kf_token$(_book_0, _ns_0, _source_0, _text_0, _parts_0) {
  const _prefix_0 = ($String$take$(_source_0, 3));
  const _name_0 = run_loop($kf_name$(($String$drop$(_source_0, 4)), ""));
  const _x_0 = [..._name_0].length;
  const _rest_0 = ($String$drop$(_source_0, nat_chk(4 + _x_0)));
  const _resolved_0 = run_loop($kf_resolve$(_book_0, _ns_0, _prefix_0, _name_0));
  return $kc$(($Bool$and$(($Bool$not$(($String$eq$(_name_0, "")))), ($String$starts_with$(_rest_0, ")")))), run_clo((_x_1) => {
  return $kc$(($String$eq$(_resolved_0, "")), run_clo((_x_2) => {
  const _x_3 = (_name_0 + ") names no constructor or def");
  const _x_4 = ("(" + _x_3);
  return {$: "KF_Source", "parts": {$: "Nil"}, "error": (_prefix_0 + _x_4)};
}), run_clo((_x_5) => {
  return $kf_scan$(_book_0, _ns_0, ($String$drop$(_rest_0, 1)), false, "", {$: "Con", "head": ($kt$(_prefix_0, _resolved_0, 0, 0, {$: "Nil"})), "tail": {$: "Con", "head": ($kt$("Text", ($String$reverse$(_text_0)), 0, 0, {$: "Nil"})), "tail": _parts_0}});
}));
}), run_clo((_x_6) => {
  return $kf_char$(_book_0, _ns_0, _source_0, _text_0, _parts_0);
}));
}

function $kf_char$(_book_0, _ns_0, _source_0, _text_0, _parts_0) {
  if (_source_0 === "") {
    return {$: "KF_Source", "parts": ($List$reverse$({$: "Con", "head": ($kt$("Text", ($String$reverse$(_text_0)), 0, 0, {$: "Nil"})), "tail": _parts_0})), "error": ""};
  } else {
    const _h_0 = (_source_0.codePointAt(0) > 0xFFFF ? _source_0.slice(0, 2) : _source_0[0]);
    const _rest_0 = (_source_0.codePointAt(0) > 0xFFFF ? _source_0.slice(2) : _source_0.slice(1));
    return $kf_scan$(_book_0, _ns_0, _rest_0, ($kf_word$(_h_0)), (_h_0 + _text_0), _parts_0);
  }
}

function $j_ctor_metadata$(_defs_0) {
  if (_defs_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _defs_0["head"];
    const _rest_0 = _defs_0["tail"];
    const _x_0 = ($j_ctor_keys$(($dc$(_d_0)), ($da$(_d_0))));
    const _x_1 = ($j_ctor_metadata$(_rest_0));
    return (_x_0 + _x_1);
  }
}

function $j_schemas$(_book_0, _defs_0) {
  if (_defs_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _defs_0["head"];
    const _rest_0 = _defs_0["tail"];
    const _x_7 = run_loop($kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_0) => {
  const _x_1 = ($j_schema_ctors$(_book_0, ($dc$(_d_0)), ($da$(_d_0))));
  const _x_2 = (_x_1 + "}];\n");
  const _x_3 = ($j_quote$(($dn$(_d_0))));
  const _x_4 = ("]=(p)=>[\"ADT\",{" + _x_2);
  const _x_5 = (_x_3 + _x_4);
  return ("showSchemas[" + _x_5);
}), run_clo((_x_6) => {
  return "";
})));
    const _x_8 = ($j_schemas$(_book_0, _rest_0));
    return (_x_7 + _x_8);
  }
}

function $j_defs$(_book_0, _defs_0) {
  if (_defs_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _defs_0["head"];
    const _rest_0 = _defs_0["tail"];
    const _x_0 = run_loop($j_def$(_book_0, _d_0));
    const _x_1 = ($j_defs$(_book_0, _rest_0));
    return (_x_0 + _x_1);
  }
}

function $String$ends_with$(_s_0, _p_0) {
  return $String$starts_with$(($String$reverse$(_s_0)), ($String$reverse$(_p_0)));
}

function $fpe_seek$(_source_0, _rest_0, _line_0, _column_0, _error_0) {
  const _x_0 = ($ix$(_error_0));
  const _x_1 = ($qt$(_error_0));
  return $f_choose$(($Bool$and$((_line_0 === _x_0), (_column_0 === _x_1))), run_clo((_x_2) => {
  return $fpe_here$(_source_0, _rest_0, _error_0);
}), run_clo((_x_3) => {
  return $f_choose$(($String$is_empty$(_rest_0)), run_clo((_x_4) => {
  return $nm$(_error_0);
}), run_clo((_x_5) => {
  const _x_6 = ($Char$to_u32$(($f_head$(_rest_0))));
  return $f_choose$((_x_6 === 10), run_clo((_x_7) => {
  return $fpe_seek$(_source_0, ($f_tail$(_rest_0)), ((_line_0 + 1) >>> 0), 0, _error_0);
}), run_clo((_x_8) => {
  return $fpe_seek$(_source_0, ($f_tail$(_rest_0)), _line_0, ((_column_0 + 1) >>> 0), _error_0);
}));
}));
}));
}

function $f_tx$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return "<eof>";
  } else {
    const _t_0 = _ts_0["head"];
    const _t_1 = _t_0["text"];
    return _t_1;
  }
}

function $f_top_ready$(_ts_0, _book_0, _imports_0, _unsafe_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "<eof>")), run_clo((_x_0) => {
  return $f_result$(_book_0, ($atom$("Absent")), _imports_0);
}), run_clo((_x_1) => {
  return $f_choose$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "@")), ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "unsafe")))), run_clo((_x_2) => {
  return $f_tops$(($f_tl$(($f_tl$(_ts_0)))), _book_0, _imports_0, true);
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "import")), run_clo((_x_4) => {
  return $f_import_leading$(_ts_0, _book_0, _imports_0, _unsafe_0);
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "law")), run_clo((_x_6) => {
  return $f_law$(($f_tx$(($f_tl$(_ts_0)))), run_loop($f_skip$(($f_tl$(($f_tl$(($f_tl$(_ts_0)))))))), _book_0, _imports_0, {$: "Nil"});
}), run_clo((_x_7) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "def")), run_clo((_x_8) => {
  return $f_def_header$(run_loop($f_space$(($f_tl$(_ts_0)))), _book_0, _imports_0, _unsafe_0);
}), run_clo((_x_9) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "type")), run_clo((_x_10) => {
  return $f_type$(($f_tx$(($f_tl$(_ts_0)))), ($f_tl$(($f_tl$(_ts_0)))), _book_0, _imports_0);
}), run_clo((_x_11) => {
  return $f_result$(_book_0, ($f_pn$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), "@")), run_clo((_x_12) => {
  return $f_err$(_ts_0, "expected def, law, type or import");
}), run_clo((_x_13) => {
  return $fpe_error$(_ts_0, "expected def, law, type or import", "'def', 'type' or 'law'");
}))))), _imports_0);
}));
}));
}));
}));
}));
}));
}

function $f_result$(_book_0, _err_0, _imports_0) {
  return {$: "FRawResult", "book": ($List$reverse$(_book_0)), "error": _err_0, "imports": ($List$reverse$(_imports_0))};
}

function $f_pn$(_p_0) {
  const _n_0 = _p_0["term"];
  return _n_0;
}

function $f_err$(_ts_0, _msg_0) {
  const _x_0 = ($f_tx$(_ts_0));
  const _x_1 = ("; got " + _x_0);
  const _x_2 = (_msg_0 + _x_1);
  const _x_3 = ($U32$show$(($f_col$(_ts_0))));
  const _x_4 = (": " + _x_2);
  const _x_5 = (_x_3 + _x_4);
  const _x_6 = ($U32$show$(($f_line$(_ts_0))));
  const _x_7 = (":" + _x_5);
  const _x_8 = (_x_6 + _x_7);
  return {$: "FParsed", "term": ($kt$("Error", ("line " + _x_8), 0, 0, {$: "Nil"})), "rest": {$: "Nil"}};
}

function $f_tl$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _rest_0 = _ts_0["tail"];
    return _rest_0;
  }
}

function $List$reverse$go$($0, $1) {
  for (;;) {
    {
      const _xs_0 = $0;
      const _acc_0 = $1;
      if (_xs_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        $0 = _t_0;
        $1 = {$: "Con", "head": _h_0, "tail": _acc_0};
        continue;
      }
    }
  }
}

function $Char$to_u32$(_c_0) {
  return _c_0.codePointAt(0);
}

function $f_ascii_space_code$(_code_0) {
  const _x_0 = ((_code_0 - 9) >>> 0);
  const _x_1 = (_code_0 === 32);
  const _x_2 = (_x_0 <= 4);
  return (_x_1 || _x_2);
}

function $f_lex_quote_end$(_word_0, _rest_0, _line_0, _column_0, _depth_0, _tokens_0) {
  if (_word_0 === "") {
    return $f_lex$(_rest_0, _line_0, _column_0, _depth_0, _tokens_0);
  } else {
    const _head_0 = (_word_0.codePointAt(0) > 0xFFFF ? _word_0.slice(0, 2) : _word_0[0]);
    const _tail_0 = (_word_0.codePointAt(0) > 0xFFFF ? _word_0.slice(2) : _word_0.slice(1));
    return $f_choose$(($Char$is_eq$(_head_0, "\n")), run_clo((_x_0) => {
  return $f_lex_quote_end$(_tail_0, _rest_0, ((_line_0 + 1) >>> 0), 0, _depth_0, _tokens_0);
}), run_clo((_x_1) => {
  return $f_lex_quote_end$(_tail_0, _rest_0, _line_0, ((_column_0 + 1) >>> 0), _depth_0, _tokens_0);
}));
  }
}

function $String$reverse$(_s_0) {
  return $String$reverse$go$(_s_0, "");
}

function $f_ascii_ident_code$(_code_0) {
  const _x_0 = ((_code_0 | 32) >>> 0);
  const _x_1 = ((_x_0 - 97) >>> 0);
  const _x_2 = ((_code_0 - 48) >>> 0);
  const _x_3 = (_x_1 <= 25);
  const _x_4 = (_x_2 <= 9);
  const _x_5 = (_x_3 || _x_4);
  const _x_6 = (_code_0 === 95);
  const _x_7 = (_x_5 || _x_6);
  const _x_8 = (_code_0 === 46);
  return (_x_7 || _x_8);
}

function $f_ascii_digit$(_c_0) {
  const _x_0 = ($Char$to_u32$(_c_0));
  const _x_1 = ((_x_0 - 48) >>> 0);
  return (_x_1 <= 9);
}

function $f_pair_op$(_s_0) {
  const _x_0 = ($f_eq$(_s_0, "->"));
  const _x_1 = ($f_eq$(_s_0, "=>"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(_s_0, "<-"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(_s_0, "++"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($f_eq$(_s_0, "<>"));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($f_eq$(_s_0, "=="));
  const _x_10 = (_x_8 || _x_9);
  const _x_11 = ($f_eq$(_s_0, "!="));
  const _x_12 = (_x_10 || _x_11);
  const _x_13 = ($f_eq$(_s_0, "<="));
  const _x_14 = (_x_12 || _x_13);
  const _x_15 = ($f_eq$(_s_0, ">="));
  const _x_16 = (_x_14 || _x_15);
  const _x_17 = ($f_eq$(_s_0, "&&"));
  const _x_18 = (_x_16 || _x_17);
  const _x_19 = ($f_eq$(_s_0, "||"));
  const _x_20 = (_x_18 || _x_19);
  const _x_21 = ($f_eq$(_s_0, "<<"));
  const _x_22 = (_x_20 || _x_21);
  const _x_23 = ($f_eq$(_s_0, ">>"));
  return (_x_22 || _x_23);
}

function $f_two$(_s_0) {
  return (($f_head$(_s_0)) + (($f_head$(($f_tail$(_s_0)))) + ""));
}

function $f_col$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _ts_0["head"];
    const _c_0 = _t_0["f_col"];
    return _c_0;
  }
}

function $f_symbol_text$(_s_0, _c_0, _acc_0) {
  const _x_0 = ($f_tx$(_acc_0));
  const _x_1 = [..._x_0].length;
  const _x_2 = ($f_col$(_acc_0));
  const _x_3 = (_x_1 >>> 0);
  const _x_4 = ((_x_2 + _x_3) >>> 0);
  return $f_choose$(($Bool$and$(($Bool$and$(($f_ascii_char_eq$(($f_head$(_s_0)), "+")), ($f_ascii_alpha$(($f_head$(($f_tail$(_s_0)))))))), ($Bool$not$(($Bool$and$(($String$ends_with$(($f_tx$(_acc_0)), "n")), (_x_4 === _c_0))))))), run_clo((_x_5) => {
  return "+bind";
}), run_clo((_x_6) => {
  const _x_7 = ($f_tx$(_acc_0));
  const _x_8 = [..._x_7].length;
  const _x_9 = ($f_col$(_acc_0));
  const _x_10 = (_x_8 >>> 0);
  const _x_11 = ((_x_9 + _x_10) >>> 0);
  return $f_choose$(($Bool$and$(($f_ascii_char_eq$(($f_head$(_s_0)), ">")), (_c_0 > _x_11))), run_clo((_x_12) => {
  return ">op";
}), run_clo((_x_13) => {
  return (($f_head$(_s_0)) + "");
}));
}));
}

function $f_fresh_result_end$(_r_0, _err_0, _imports_0) {
  const _book_0 = _r_0["defs"];
  return {$: "FResult", "book": _book_0, "error": _err_0, "imports": _imports_0};
}

function $f_fresh_defs$(_ds_0, _next_0) {
  return $f_fresh_book_stack$(_ds_0, _next_0);
}

function $f_load_parsed$(_name_0, _r_0, _sources_0, _seen_0, _stack_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $f_load_imports$(_imports_0, _sources_0, {$: "Con", "head": _name_0, "tail": _seen_0}, {$: "Con", "head": _name_0, "tail": _stack_0}, _book_0);
}), run_clo((_x_1) => {
  return {$: "FLoaded", "book": _book_0, "error": _err_0, "seen": _seen_0};
}));
}

function $f_path_result$(_r_0, _path_0, _native_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return {$: "FResult", "book": ($f_path_defs$(_book_0, run_loop($f_path_dir$(_path_0)), _native_0)), "error": _err_0, "imports": _imports_0};
}

function $f_parse_at$(_source_0, _namespace_0) {
  return $f_qual_result$(($f_elaborate$(($f_parse$(_source_0)))), _namespace_0);
}

function $annotate$(_e_0, _ctx_0, _t_0, _ty_0) {
  return $ka_wrap$(run_loop($ka_node$(_e_0, _ctx_0, run_loop($core_beta$(_t_0)), run_loop($wnf$(($cb$(_e_0)), _ty_0)))), _ty_0);
}

function $ref$(_name_0) {
  return $kt$("Ref", _name_0, 0, 0, {$: "Nil"});
}

function $Cmp$is_eq$(_c_0) {
  if (_c_0.$ === "LT") {
    return false;
  } else if (_c_0.$ === "EQ") {
    return true;
  } else {
    return false;
  }
}

function $String$cmp$fin$(_t1_0, _t2_0, _hc_0) {
  const _t_0 = _hc_0["fst"];
  const _h1b_0 = _t_0["fst"];
  const _h2b_0 = _t_0["snd"];
  const _t_1 = _hc_0["snd"];
  if (_t_1.$ === "LT") {
    return {$: "Tuple", "fst": {$: "Tuple", "fst": (_h1b_0 + _t1_0), "snd": (_h2b_0 + _t2_0)}, "snd": {$: "LT"}};
  } else if (_t_1.$ === "EQ") {
    return $String$cmp$rec$(_h1b_0, _h2b_0, ($String$cmp$(_t1_0, _t2_0)));
  } else {
    return {$: "Tuple", "fst": {$: "Tuple", "fst": (_h1b_0 + _t1_0), "snd": (_h2b_0 + _t2_0)}, "snd": {$: "GT"}};
  }
}

function $Char$cmp$(_a_0, _b_0) {
  const _x_0 = _a_0.codePointAt(0);
  const _x_1 = _b_0.codePointAt(0);
  return {$: "Tuple", "fst": {$: "Tuple", "fst": _a_0, "snd": _b_0}, "snd": cmp_new(_x_0, _x_1)};
}

function $j_escape_char$(_c_0) {
  return $j_escape_char_on$(_c_0, ($Char$to_u32$(_c_0)));
}

function $j_apply_spine$(_book_0, _env_0, _t_0, _tail_0, _fty_0, _spine_0) {
  return $kc$(run_loop($j_choice_call$(_book_0, _spine_0)), run_clo((_x_0) => {
  return $j_choice_emit$(_book_0, _env_0, _spine_0, _tail_0);
}), run_clo((_x_1) => {
  return $j_apply_regular$(_book_0, _env_0, _t_0, _tail_0, _fty_0, _spine_0);
}));
}

function $j_call_spine$(_t_0, _args_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $j_call_spine$(run_loop($kid$(_t_0, 0)), _args_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_2) => {
  return $j_call_spine$(run_loop($kid$(_t_0, 0)), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _args_0});
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ref")), run_clo((_x_4) => {
  return $kt$("Call", ($nm$(_t_0)), 0, 0, _args_0);
}), run_clo((_x_5) => {
  return $atom$("Absent");
}));
}));
}));
}

function $j_type_on$(_book_0, _env_0, _t_0, _key_0) {
  return $kc$(($String$eq$(_key_0, "Ann")), run_clo((_x_0) => {
  return $kid$(_t_0, 1);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(_key_0, "Var")), run_clo((_x_2) => {
  return $j_env$(_env_0, ($ix$(_t_0)));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(_key_0, "Ref")), run_clo((_x_4) => {
  return $dt$(run_loop($lookup$(_book_0, ($nm$(_t_0)))));
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(_key_0, "App")), run_clo((_x_6) => {
  return $j_app_type$(run_loop($wnf$(_book_0, run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_t_0, 0)))))), run_loop($kid$(_t_0, 1)));
}), run_clo((_x_7) => {
  return $atom$("Absent");
}));
}));
}));
}));
}

function $terms_at$(_ts_0, _n_0) {
  if (_ts_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _h_0 = _ts_0["head"];
    const _t_0 = _ts_0["tail"];
    return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return _h_0;
}), run_clo((_x_1) => {
  return $terms_at$(_t_0, ((_n_0 - 1) >>> 0));
}));
  }
}

function $List$is_empty$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return true;
  } else {
    return false;
  }
}

function $j_literal_typed$(_book_0, _t_0, _ty_0) {
  const _literal_0 = run_loop($j_literal$(_t_0));
  return $kc$(($String$eq$(_literal_0, "")), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  return $j_literal_provenance$(_book_0, run_loop($wnf$(_book_0, _ty_0)), _literal_0);
}));
}

function $j_ctor_thunks$(_book_0, _env_0, _args_0, _tel_0) {
  if (_args_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    const _x_0 = ($qt$(_tel_0));
    const _x_3 = ($j_ctor_thunks$(_book_0, _env_0, _rest_0, run_loop($j_app_type$(_tel_0, _h_0))));
    const _x_4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_tel_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return "null";
}), run_clo((_x_2) => {
  return $j_expr$(_book_0, _env_0, _h_0, run_loop($kid$(_tel_0, 0)), true);
})));
    const _x_5 = ("," + _x_3);
    const _x_6 = (_x_4 + _x_5);
    return ("()=>" + _x_6);
  }
}

function $j_specialize$($0, $1, $2) {
  for (;;) {
    {
      const _book_0 = $0;
      const _tel_0 = $1;
      const _args_0 = $2;
      if (_args_0.$ === "Nil") {
        return _tel_0;
      } else {
        const _h_0 = _args_0["head"];
        const _rest_0 = _args_0["tail"];
        $0 = _book_0;
        $1 = run_loop($j_app_type$(run_loop($wnf$(_book_0, _tel_0)), _h_0));
        $2 = _rest_0;
        continue;
      }
    }
  }
}

function $j_find_ctor$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return $missing$();
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $j_found_ctor$(run_loop($lookup$(($dc$(_d_0)), _name_0)), _rest_0, _name_0);
  }
}

function $j_constructor$(_book_0, _env_0, _t_0, _ty_0) {
  return $j_constructor_literal$(_book_0, _env_0, _t_0, _ty_0, run_loop($j_literal_typed$(_book_0, _t_0, _ty_0)));
}

function $j_lambda_count$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $j_lambda_count$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_2) => {
  const _x_3 = run_loop($j_lambda_count$(run_loop($kid$(_t_0, 0))));
  return ((1 + _x_3) >>> 0);
}), run_clo((_x_4) => {
  return 0;
}));
}));
}

function $j_lambda_code$(_book_0, _env_0, _t_0, _ty_0, _at_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $j_lambda_code$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)), _at_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_2) => {
  return $j_lambda_bind$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)), _at_0);
}), run_clo((_x_3) => {
  const _x_4 = run_loop($j_expr$(_book_0, _env_0, _t_0, _ty_0, true));
  const _x_5 = (_x_4 + ";");
  return ("return " + _x_5);
}));
}));
}

function $j_constructor_count$(_book_0, _ty_0) {
  return $j_count_constructors$(($dc$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), ($rm$(_ty_0)));
}

function $j_arm_type$(_book_0, _ty_0, _name_0) {
  return $j_arm_tel$(_book_0, ($j_specialize$(_book_0, ($dt$(run_loop($j_find_ctor$(_book_0, _name_0)))), ($ks$(run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0)))))))), run_loop($kid$(_ty_0, 1)));
}

function $j_bindings$(_book_0, _env_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return "";
    } else {
      const _x_0 = ($j_bindings$(_book_0, _env_0, _t_0));
      const _x_1 = ($j_local$(($ix$(_h_0))));
      const _x_2 = ("," + _x_0);
      return (_x_1 + _x_2);
    }
  }
}

function $j_context$(_book_0, _env_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return _env_0;
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return _env_0;
    } else {
      return {$: "Con", "head": ($kt$("Env", "", ($ix$(_h_0)), 0, {$: "Con", "head": run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_h_0, 0)))), "tail": {$: "Nil"}})), "tail": ($j_context$(_book_0, _env_0, _t_0))};
    }
  }
}

function $j_body$($0) {
  for (;;) {
    {
      const _xs_0 = $0;
      if (_xs_0.$ === "Nil") {
        return $atom$("Absent");
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        if (_t_0.$ === "Nil") {
          return _h_0;
        } else {
          $0 = _t_0;
          continue;
        }
      }
    }
  }
}

function $j_let_values$(_book_0, _env_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return "";
    } else {
      const _x_0 = ($qt$(_h_0));
      const _x_3 = ($j_let_values$(_book_0, _env_0, _t_0));
      const _x_4 = run_loop($kc$((_x_0 === 0), run_clo((_x_1) => {
  return "null";
}), run_clo((_x_2) => {
  return $j_expr$(_book_0, _env_0, run_loop($kid$(_h_0, 0)), ($atom$("Absent")), false);
})));
      const _x_5 = ("," + _x_3);
      return (_x_4 + _x_5);
    }
  }
}

function $j_exprs_tail$(_book_0, _env_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    const _x_0 = run_loop($j_expr$(_book_0, _env_0, _h_0, ($atom$("Absent")), false));
    const _x_1 = ($j_exprs_tail$(_book_0, _env_0, _rest_0));
    const _x_2 = (_x_0 + _x_1);
    return ("," + _x_2);
  }
}

function $U32$show$if$(_a_0, _z_0) {
  if (_z_0) {
    return "0";
  } else {
    return $U32$show$go$(10, _a_0, "");
  }
}

function $j_desc_head_on$(_book_0, _ty_0, _fuel_0, _key_0) {
  return $kc$(($String$eq$(_key_0, "Char")), run_clo((_x_0) => {
  return "[\"Char\"]";
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(_key_0, "F32")), run_clo((_x_2) => {
  return "[\"F32\"]";
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(_key_0, "List")), run_clo((_x_4) => {
  const _x_5 = run_loop($j_descriptor$(_book_0, run_loop($kid$(_ty_0, 1)), _fuel_0));
  const _x_6 = (_x_5 + "]");
  return ("[\"List\"," + _x_6);
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(_key_0, "Array")), run_clo((_x_8) => {
  const _x_9 = run_loop($j_descriptor$(_book_0, run_loop($kid$(_ty_0, 0)), _fuel_0));
  const _x_10 = (_x_9 + "]");
  return ("[\"Array\"," + _x_10);
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(_key_0, "Sigma")), run_clo((_x_12) => {
  const _x_13 = run_loop($j_descriptor$(_book_0, run_loop($kid$(run_loop($kid$(_ty_0, 3)), 0)), _fuel_0));
  const _x_14 = (_x_13 + "]");
  const _x_15 = run_loop($j_descriptor$(_book_0, run_loop($kid$(_ty_0, 2)), _fuel_0));
  const _x_16 = ("," + _x_14);
  const _x_17 = (_x_15 + _x_16);
  return ("[\"Tuple\"," + _x_17);
}), run_clo((_x_18) => {
  return $kc$(($String$eq$(($tg$(_ty_0)), "Var")), run_clo((_x_19) => {
  const _x_20 = ($j_local$(($ix$(_ty_0))));
  const _x_21 = (_x_20 + ")");
  const _x_22 = ($j_local$(($ix$(_ty_0))));
  const _x_23 = ("===\"undefined\"?null:" + _x_21);
  const _x_24 = (_x_22 + _x_23);
  return ("(typeof " + _x_24);
}), run_clo((_x_25) => {
  return $kc$(($String$eq$(($tg$(_ty_0)), "ADT")), run_clo((_x_26) => {
  const _x_27 = ($j_desc_args$(_book_0, ($ks$(_ty_0)), _fuel_0));
  const _x_28 = (_x_27 + "]]");
  const _x_29 = ($j_quote$(($nm$(_ty_0))));
  const _x_30 = (",[" + _x_28);
  const _x_31 = (_x_29 + _x_30);
  return ("[\"Named\"," + _x_31);
}), run_clo((_x_32) => {
  return "null";
}));
}));
}));
}));
}));
}));
}));
}

function $norm_var$(_book_0, _t_0, _values_0, _args_0, _left_0, _fallback_0) {
  if (_values_0.$ === "Nil") {
    return $norm_apply$(_t_0, _args_0);
  } else {
    const _h_0 = _values_0["head"];
    return $norm_eval$(_book_0, _h_0, _args_0, _left_0, _fallback_0);
  }
}

function $norm_eval_node$(_book_0, _t_0, _args_0, _left_0, _fallback_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $norm_eval$(_book_0, run_loop($kid$(_t_0, 0)), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _args_0}, _left_0, _fallback_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_2) => {
  return $norm_eval$(_book_0, run_loop($kid$(_t_0, 0)), _args_0, _left_0, _fallback_0);
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Let")), run_clo((_x_4) => {
  return $norm_eval$(_book_0, run_loop($norm_let$(($ks$(_t_0)))), _args_0, _left_0, _fallback_0);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ref")), run_clo((_x_6) => {
  return $norm_ref$(_book_0, _t_0, _args_0, run_loop($lookup$(_book_0, ($nm$(_t_0)))));
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Min")), run_clo((_x_8) => {
  return $norm_apply$(run_loop($norm_min$(_book_0, run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)))), _args_0);
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_10) => {
  return $kc$(($String$eq$(($tg$(run_loop($wnf$(_book_0, run_loop($kid$(_t_0, 0)))))), "Rfl")), run_clo((_x_11) => {
  return $norm_eval$(_book_0, run_loop($kid$(_t_0, 2)), _args_0, _left_0, _fallback_0);
}), run_clo((_x_12) => {
  return $norm_apply$(_t_0, _args_0);
}));
}), run_clo((_x_13) => {
  return $norm_args$(_book_0, _t_0, _args_0, _left_0, _fallback_0);
}));
}));
}));
}));
}));
}));
}

function $index_find$(_tree_0, _name_0, _hash_0, _bits_0) {
  return $kc$(($String$eq$(($dk$(_tree_0)), "Absent")), run_clo((_x_0) => {
  return $missing$();
}), run_clo((_x_1) => {
  const _x_2 = ($dx$(_tree_0));
  return $kc$((_x_2 === 0), run_clo((_x_3) => {
  const _x_4 = ($da$(_tree_0));
  return $kc$((_x_4 === _hash_0), run_clo((_x_5) => {
  return $index_bucket$(($dc$(_tree_0)), _name_0);
}), run_clo((_x_6) => {
  return $missing$();
}));
}), run_clo((_x_7) => {
  const _x_8 = ($dx$(_tree_0));
  const _x_9 = ((_hash_0 & _x_8) >>> 0);
  return $index_find$(run_loop($index_child$(_tree_0, ($Bool$not$((_x_9 === 0))))), _name_0, _hash_0, _bits_0);
}));
}));
}

function $index_first$(_ds_0) {
  if (_ds_0.$ === "Nil") {
    return $missing$();
  } else {
    const _h_0 = _ds_0["head"];
    return _h_0;
  }
}

function $j_foreign_chars$(_name_0) {
  if (_name_0 === "") {
    return "";
  } else {
    const _h_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(0, 2) : _name_0[0]);
    const _rest_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(2) : _name_0.slice(1));
    const _x_0 = ($Char$is_eq$(_h_0, "."));
    const _x_1 = ($Char$is_eq$(_h_0, "/"));
    const _x_4 = run_loop($kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return "_";
}), run_clo((_x_3) => {
  return $Char$show$(_h_0);
})));
    const _x_5 = ($j_foreign_chars$(_rest_0));
    return (_x_4 + _x_5);
  }
}

function $String$to_lower$(_s_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    return (($Char$to_lower$(_h_0)) + ($String$to_lower$(_t_0)));
  }
}

function $book_final_large$(_book_0, _remaining_0) {
  if (_book_0.$ === "Nil") {
    return (_remaining_0 === 0);
  } else {
    const _rest_0 = _book_0["tail"];
    return $kc$((_remaining_0 === 0), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $book_final_large$(_rest_0, ((_remaining_0 - 1) >>> 0));
}));
  }
}

function $book_final_names_valid$(_book_0) {
  if (_book_0.$ === "Nil") {
    return true;
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(run_loop($book_final_name_valid$(($dn$(_d_0)))), run_clo((_x_0) => {
  return $book_final_names_valid$(_rest_0);
}), run_clo((_x_1) => {
  return false;
}));
  }
}

function $book_final_scan$(_book_0, _seen_0, _kept_0, _done_0) {
  if (_book_0.$ === "Nil") {
    return $book_final_reverse$(_kept_0, run_loop($book_final_filter$(_done_0, _seen_0)));
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $book_final_step$(_d_0, _rest_0, _seen_0, _kept_0, _done_0, ($index_hash$(($dn$(_d_0)), 2166136261)));
  }
}

function $book_final_reverse$($0, $1) {
  for (;;) {
    {
      const _book_0 = $0;
      const _done_0 = $1;
      if (_book_0.$ === "Nil") {
        return _done_0;
      } else {
        const _d_0 = _book_0["head"];
        const _rest_0 = _book_0["tail"];
        $0 = _rest_0;
        $1 = {$: "Con", "head": _d_0, "tail": _done_0};
        continue;
      }
    }
  }
}

function $book_final_legacy$($0, $1) {
  for (;;) {
    {
      const _book_0 = $0;
      const _done_0 = $1;
      if (_book_0.$ === "Nil") {
        return _done_0;
      } else {
        const _d_0 = _book_0["head"];
        const _rest_0 = _book_0["tail"];
        $0 = _rest_0;
        $1 = {$: "Con", "head": _d_0, "tail": run_loop($index_remove$(_done_0, ($dn$(_d_0))))};
        continue;
      }
    }
  }
}

function $kp_eq$(_a_0, _b_0) {
  return $String$eq$(_a_0, _b_0);
}

function $kp_scope$(_env_0, _id_0, _name_0) {
  if (_env_0.$ === "Nil") {
    const _x_0 = ($U32$show$(_id_0));
    const _x_1 = ("^" + _x_0);
    return (_name_0 + _x_1);
  } else {
    const _t_0 = _env_0["head"];
    const _n_0 = _t_0["name"];
    const _i_0 = _t_0["id"];
    const _tail_0 = _env_0["tail"];
    return $kc$(($kp_eq$(_n_0, _name_0)), run_clo((_x_2) => {
  return $kc$((_i_0 === _id_0), run_clo((_x_3) => {
  return _name_0;
}), run_clo((_x_4) => {
  const _x_5 = ($U32$show$(run_loop($kp_index$(_tail_0, _id_0))));
  const _x_6 = ("^" + _x_5);
  return (_name_0 + _x_6);
}));
}), run_clo((_x_7) => {
  return $kp_scope$(_tail_0, _id_0, _name_0);
}));
  }
}

function $kp_bound$(_env_0, _name_0) {
  if (_env_0.$ === "Nil") {
    return false;
  } else {
    const _t_0 = _env_0["head"];
    const _n_0 = _t_0["name"];
    const _t_1 = _env_0["tail"];
    const _x_0 = ($kp_eq$(_n_0, _name_0));
    const _x_1 = ($kp_bound$(_t_1, _name_0));
    return (_x_0 || _x_1);
  }
}

function $kp_par$(_s_0, _yes_0) {
  return $kc$(_yes_0, run_clo((_x_0) => {
  const _x_1 = (_s_0 + ")");
  return ("(" + _x_1);
}), run_clo((_x_2) => {
  return _s_0;
}));
}

function $kp_quant$(_q_0) {
  return $kc$((_q_0 === 0), run_clo((_x_0) => {
  return "-";
}), run_clo((_x_1) => {
  return $kc$((_q_0 === 2), run_clo((_x_2) => {
  return "+";
}), run_clo((_x_3) => {
  return "";
}));
}));
}

function $kp_bind$(_env_0, _t_0) {
  return {$: "Con", "head": {$: "KPName", "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "depth": ($kp_depth$(_env_0))}, "tail": _env_0};
}

function $kp_go_tail$(_t_0, _p_0, _env_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  const _x_1 = ($U32$show$(($qt$(_t_0))));
  return (_x_1 + "n");
}), run_clo((_x_2) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "App")), run_clo((_x_3) => {
  return $kp_application$(run_loop($kp_spine$(_t_0, {$: "Nil"})), _p_0, _env_0);
}), run_clo((_x_4) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "ADT")), run_clo((_x_5) => {
  return $kp_adt$(_t_0, _p_0, _env_0);
}), run_clo((_x_6) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_7) => {
  return $kp_ctor$(_t_0, _p_0, _env_0);
}), run_clo((_x_8) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Mat")), run_clo((_x_9) => {
  const _x_10 = run_loop($kp_matches$(_t_0, _env_0));
  const _x_11 = (_x_10 + "}");
  return ("\\{" + _x_11);
}), run_clo((_x_12) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Efq")), run_clo((_x_13) => {
  return "\\{}";
}), run_clo((_x_14) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Eql")), run_clo((_x_15) => {
  const _x_16 = run_loop($kp_go$(run_loop($kid$(_t_0, 2)), 2, _env_0));
  const _x_17 = (_x_16 + "}");
  const _x_18 = run_loop($kp_go$(run_loop($kid$(_t_0, 1)), 2, _env_0));
  const _x_19 = (" : " + _x_17);
  const _x_20 = (_x_18 + _x_19);
  const _x_21 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 2, _env_0));
  const _x_22 = (" == " + _x_20);
  const _x_23 = (_x_21 + _x_22);
  return ("{" + _x_23);
}), run_clo((_x_24) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Rfl")), run_clo((_x_25) => {
  return "{==}";
}), run_clo((_x_26) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Hol")), run_clo((_x_27) => {
  const _x_28 = ($nm$(_t_0));
  return ("?" + _x_28);
}), run_clo((_x_29) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Ann")), run_clo((_x_30) => {
  const _x_31 = run_loop($kp_go$(run_loop($kid$(_t_0, 1)), 2, _env_0));
  const _x_32 = (_x_31 + "}");
  const _x_33 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 2, _env_0));
  const _x_34 = (" : " + _x_32);
  const _x_35 = (_x_33 + _x_34);
  return ("{" + _x_35);
}), run_clo((_x_36) => {
  return $kp_go_last$(_t_0, _p_0, _env_0);
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $g_start$(_book_0, _t_0, _bound_0) {
  return $g_snf_go$(($book_cached$(_book_0, _bound_0)), {$: "GState", "heap": {$: "GEmpty"}, "next": 1}, _t_0, {$: "Nil"}, ((_bound_0 + 1) >>> 0));
}

function $norm_max$(_a_0, _b_0) {
  return $kc$((_a_0 <= _b_0), run_clo((_x_0) => {
  return _b_0;
}), run_clo((_x_1) => {
  return _a_0;
}));
}

function $norm_book_bound$(_book_0) {
  if (_book_0.$ === "Nil") {
    return 0;
  } else {
    const _h_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($String$eq$(($dk$(_h_0)), "BookCache")), run_clo((_x_0) => {
  return $da$(_h_0);
}), run_clo((_x_1) => {
  return $norm_bound_found$({$: "Con", "head": _h_0, "tail": _rest_0}, run_loop($lookup$({$: "Con", "head": _h_0, "tail": _rest_0}, "$kernel.max-id")));
}));
  }
}

function $norm_max_term$(_t_0) {
  return $norm_max_walk$({$: "Con", "head": _t_0, "tail": {$: "Nil"}}, 0);
}

function $driver_holes_terms$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($driver_holes$(_t_0));
    const _x_1 = ($driver_holes_terms$(_rest_0));
    return ((_x_0 + _x_1) >>> 0);
  }
}

function $sp_needed$(_book_0, _t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ref")), run_clo((_x_0) => {
  const _x_1 = ($dx$(run_loop($lookup$(_book_0, ($nm$(_t_0))))));
  return (_x_1 > 0);
}), run_clo((_x_2) => {
  return $sp_neededs$(_book_0, ($ks$(_t_0)));
}));
}

function $sp_templates$(_st_0) {
  const _templates_0 = _st_0["templates"];
  return _templates_0;
}

function $sp_definition_install$(_rest_0, _st_0, _d_0) {
  return $sp_definitions$(_rest_0, {$: "KSpecState", "book": run_loop($check_event_install$(($sp_book$(_st_0)), _d_0, _rest_0)), "memo": ($sp_memo$(_st_0)), "serial": ($sp_serial$(_st_0)), "fresh": ($sp_fresh$(_st_0)), "error": ($sp_error$(_st_0)), "templates": ($sp_templates$(_st_0))});
}

function $sp_definition_done$(_rest_0, _d_0, _r_0) {
  return $sp_definition_install$(_rest_0, ($sp_state$(_r_0)), {$: "KDef", "name": ($dn$(_d_0)), "kind": ($dk$(_d_0)), "arity": ($da$(_d_0)), "templates": ($dx$(_d_0)), "typ": ($dt$(_d_0)), "value": ($sp_value$(_r_0)), "ctors": ($dc$(_d_0)), "native": ($db$(_d_0)), "unsafe": ($du$(_d_0))});
}

function $sp_term$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0) {
  return $kc$(($Bool$not$(($String$eq$(($sp_error$(_st_0)), "")))), run_clo((_x_0) => {
  return {$: "KSpecTerm", "state": _st_0, "term": _t_0};
}), run_clo((_x_1) => {
  const _x_2 = ($String$eq$(($tg$(_t_0)), "App"));
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Ref"));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $sp_spine$(_st_0, _t_0, {$: "Nil"}, _ctx_0, _owner_0, _depth_0);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_6) => {
  return $sp_annotation$(_t_0, run_loop($sp_term$(_st_0, run_loop($kid$(_t_0, 0)), _ctx_0, run_loop($kid$(_t_0, 1)), _owner_0, _depth_0)));
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_8) => {
  return $sp_lambda$(_st_0, _t_0, _ctx_0, run_loop($wnf$(($sp_book$(_st_0)), _goal_0)), _owner_0, _depth_0);
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Mat")), run_clo((_x_10) => {
  return $sp_match$(_st_0, _t_0, _ctx_0, run_loop($wnf$(($sp_book$(_st_0)), _goal_0)), _owner_0, _depth_0);
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_12) => {
  return $sp_constructor$(_st_0, _t_0, _ctx_0, run_loop($wnf$(($sp_book$(_st_0)), _goal_0)), _owner_0, _depth_0);
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Let")), run_clo((_x_14) => {
  return $sp_let_result$(_t_0, run_loop($sp_let$(_st_0, ($ks$(_t_0)), _ctx_0, _ctx_0, _goal_0, _owner_0, _depth_0)));
}), run_clo((_x_15) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_16) => {
  return $sp_rewrite$(_st_0, _t_0, _ctx_0, _owner_0, _depth_0);
}), run_clo((_x_17) => {
  return {$: "KSpecTerm", "state": _st_0, "term": _t_0};
}));
}));
}));
}));
}));
}));
}));
}));
}

function $declared$(_d_0) {
  return {$: "KDef", "name": ($dn$(_d_0)), "kind": ($dk$(_d_0)), "arity": ($da$(_d_0)), "templates": ($dx$(_d_0)), "typ": ($dt$(_d_0)), "value": ($atom$("Absent")), "ctors": ($dc$(_d_0)), "native": ($db$(_d_0)), "unsafe": ($du$(_d_0))};
}

function $norm_defs_join$(_a_0, _b_0) {
  if (_a_0.$ === "Nil") {
    return _b_0;
  } else {
    const _h_0 = _a_0["head"];
    const _rest_0 = _a_0["tail"];
    return {$: "Con", "head": _h_0, "tail": ($norm_defs_join$(_rest_0, _b_0))};
  }
}

function $index_put_rest$(_cache_0, _rest_0, _name_0) {
  return $kc$(($Bool$and$(($Bool$not$(($String$eq$(_name_0, "")))), ($String$eq$(($dn$(run_loop($index_lookup$(_cache_0, _name_0)))), "")))), run_clo((_x_0) => {
  return _rest_0;
}), run_clo((_x_1) => {
  return $index_remove$(_rest_0, _name_0);
}));
}

function $nc_has_ctor$(_cs_0, _key_0) {
  if (_cs_0.$ === "Nil") {
    return false;
  } else {
    const _t_0 = _cs_0["head"];
    const _k_0 = _t_0["name"];
    const _rest_0 = _cs_0["tail"];
    const _x_0 = ($String$eq$(_k_0, _key_0));
    const _x_1 = ($nc_has_ctor$(_rest_0, _key_0));
    return (_x_0 || _x_1);
  }
}

function $nv_first$(_a_0, _b_0) {
  return $nt_choose$(($String$eq$(_a_0, "")), run_clo((_x_0) => {
  return _b_0;
}), run_clo((_x_1) => {
  return _a_0;
}));
}

function $nv_program$(_ss_0, _cs_0) {
  const _x_0 = ($nt_count$(_ss_0));
  const _x_1 = ($nt_count$(_cs_0));
  const _x_2 = (_x_0 > 65532);
  const _x_3 = (_x_1 > 65536);
  return $nt_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return "native identifier exceeds 65535";
}), run_clo((_x_5) => {
  return $nv_first$(run_loop($nv_unique$(($nv_ctor_names$(_cs_0)), {$: "Con", "head": "CID_ARITY_T", "tail": {$: "Con", "head": "CID_HOT_T", "tail": {$: "Con", "head": "FID_ARITY_T", "tail": {$: "Con", "head": "FID_FLAG_T", "tail": {$: "Con", "head": "FID_RESW_T", "tail": {$: "Nil"}}}}}})), run_loop($nv_first$(run_loop($nv_unique$(($nv_seg_names$(_ss_0)), {$: "Nil"})), run_loop($nv_first$(run_loop($nv_ctors$(_cs_0)), run_loop($nv_segs$(_ss_0)))))));
}));
}

function $ne_program$(_src_0, _p_0) {
  const _ss_0 = _p_0["segments"];
  const _cs_0 = _p_0["constructors"];
  const _image_0 = _p_0["image"];
  const _requests_0 = _p_0["requests"];
  const _decls_0 = _p_0["declarations"];
  const _show_0 = _p_0["show"];
  const _pure_0 = _p_0["pure"];
  const _x_0 = ($nb_emit$(_ss_0, _cs_0, ($nt_count$(_image_0)), _pure_0));
  const _a_0 = run_loop($ne_fill$(_src_0, "// Tables\n// ======", (_x_0 + _show_0)));
  const _x_1 = ($nt_count$(_image_0));
  const _x_4 = run_loop($nt_choose$((_x_1 === 0), run_clo((_x_2) => {
  return "0";
}), run_clo((_x_3) => {
  return $nt_join$(_image_0, ", ");
})));
  const _x_5 = (" };\n" + _decls_0);
  const _x_6 = (_x_4 + _x_5);
  const _b_0 = run_loop($ne_fill$(_a_0, "// Spins\n// =====", ("CONSTV u64 STAT_IMG[] = { " + _x_6)));
  const _c_0 = run_loop($ne_fill$(_b_0, "// Segments\n// ========", ($ne_segments$(_ss_0))));
  return $ne_fill$(_c_0, "// Requests\n// ========", _requests_0);
}

function $nc_helpers$() {
  return "INLINE bool native_bool(Term t) { return t == 1 || (term_tag(t) == TAG_PAK && term_aux(t) == CID_TRUE); }\nINLINE Term native_word(Env e, u32 x) {\n  Term w = term_pak(CID_WNIL, 0);\n  for (u32 i = 32; i > 0; i--) {\n    Loc p = heap_alloc(e, 1);\n    e.mem[p] = (x >> (i - 1)) & 1;\n    e.mem[p + 1] = rfc_seal(e, w);\n    w = term_ctr(CID_WCON, p);\n  }\n  return w;\n}\n";
}

function $nc_show_finish$(_cs_0, _d_0) {
  const _src_0 = _d_0["source"];
  const _err_0 = _d_0["error"];
  const _x_0 = ($nt_join$(($nc_show_names$(_cs_0)), ", "));
  const _x_1 = (_x_0 + " };\n#endif\n");
  const _x_2 = ("static const char* SHOW_NAMES[] = { " + _x_1);
  const _x_3 = (_src_0 + _x_2);
  return {$: "NC_Show", "source": ("#if !DEVICE\n" + _x_3), "error": _err_0};
}

function $nc_show_nodes$(_book_0, _types_0, _i_0, _offset_0, _defs_0, _cells_0) {
  const _x_0 = ($terms_len$(_types_0));
  return $nt_choose$((_i_0 === _x_0), run_clo((_x_1) => {
  const _x_2 = ($nt_join$(_cells_0, ", "));
  const _x_3 = (_x_2 + " };\n");
  const _x_4 = ("static const u32 SHOW_DESC[] = { " + _x_3);
  return {$: "NC_Show", "source": (_defs_0 + _x_4), "error": ""};
}), run_clo((_x_5) => {
  return $nt_choose$((_i_0 > 4096), run_clo((_x_6) => {
  return {$: "NC_Show", "source": "", "error": "native readback type graph exceeds 4096 nodes"};
}), run_clo((_x_7) => {
  return $nc_show_step$(_book_0, _i_0, _offset_0, _defs_0, _cells_0, run_loop($nc_show_node$(_book_0, run_loop($wnf$(_book_0, run_loop($terms_at$(_types_0, _i_0)))), _types_0)));
}));
}));
}

function $nc_compact$(_t_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  return $kt$("NWord", ($U32$show$(($qt$(_t_0)))), 0, 0, {$: "Nil"});
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_2) => {
  return $nc_compact_ctor$(_t_0, run_loop($nc_literal$(_t_0)));
}), run_clo((_x_3) => {
  return $kt$(($tg$(_t_0)), ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), ($nc_compact_list$(($ks$(_t_0)))));
}));
}));
}

function $nc_mapped_refs$(_book_0, _refs_0) {
  if (_refs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _refs_0["head"];
    const _rest_0 = _refs_0["tail"];
    return {$: "Con", "head": run_loop($nc_ref_name$(_book_0, _h_0)), "tail": ($nc_mapped_refs$(_book_0, _rest_0))};
  }
}

function $nc_term_fork$(_t_0) {
  return $nc_terms_fork$({$: "Con", "head": _t_0, "tail": {$: "Nil"}});
}

function $nc_mark_code$(_c_0, _bang_0, _forked_0, _calls_0) {
  const _body_0 = _c_0["body"];
  const _ss_0 = _c_0["segments"];
  const _n_0 = _c_0["fresh"];
  const _err_0 = _c_0["error"];
  return {$: "NC_Code", "body": _body_0, "segments": ($nc_mark_segments$(_ss_0, _bang_0, _forked_0, _calls_0)), "fresh": _n_0, "error": _err_0};
}

function $nd_extend$(_book_0, _body_0, _base_0, _name_0) {
  const _params_0 = run_loop($nd_bindings$(_body_0, {$: "Nil"}));
  const _x_0 = ($nt_count$(_params_0));
  return $nt_choose$((_x_0 === 0), run_clo((_x_1) => {
  return _base_0;
}), run_clo((_x_2) => {
  return $nd_join$(_base_0, ($nc_lower$(_book_0, run_loop($nd_body$(_body_0)), _params_0, ($nc_fresh$(_base_0)))), run_loop($nc_ref_name$(_book_0, _name_0)), _params_0);
}));
}

function $nc_lower$(_book_0, _t_0, _env_0, _n_0) {
  return $nc_prepend$(($nc_drop_dead$(_env_0, _t_0)), run_loop($nc_lower_live$(_book_0, _t_0, run_loop($nc_live_env$(_env_0, _t_0)), _n_0)));
}

function $nc_append_book$(_code_0, _name_0, _calls_0, _forked_0, _rest_0) {
  const _segs_0 = _rest_0["segments"];
  const _fresh_0 = _rest_0["fresh"];
  const _err_0 = _rest_0["error"];
  return {$: "NC_Book", "segments": {$: "Con", "head": {$: "N_Segment", "name": _name_0, "params": {$: "Nil"}, "result": 1, "frame": {$: "N_Direct"}, "body": ($nc_body$(_code_0)), "refs": _calls_0, "host": false, "spin": false, "fork": _forked_0, "bang": false}, "tail": ($nt_append$(($nc_segs$(_code_0)), _segs_0))}, "fresh": _fresh_0, "error": run_loop($nt_choose$(($String$eq$(($nc_error$(_code_0)), "")), run_clo((_x_0) => {
  return _err_0;
}), run_clo((_x_1) => {
  return $nc_error$(_code_0);
})))};
}

function $nc_fresh$(_x_0) {
  const _n_0 = _x_0["fresh"];
  return _n_0;
}

function $nc_bangs_terms$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return $List$append$(run_loop($nc_bangs_term$(_h_0)), ($nc_bangs_terms$(_rest_0)));
  }
}

function $nc_refs_go$($0, $1) {
  for (;;) {
    {
      const _todo_0 = $0;
      const _acc_0 = $1;
      if (_todo_0.$ === "Nil") {
        return $nt_reverse$(_acc_0, {$: "Nil"});
      } else {
        const _h_0 = _todo_0["head"];
        const _rest_0 = _todo_0["tail"];
        $0 = ($nt_append$(($ks$(_h_0)), _rest_0));
        $1 = run_loop($nt_choose$(($String$eq$(($tg$(_h_0)), "Ref")), run_clo((_x_0) => {
  return {$: "Con", "head": ($nm$(_h_0)), "tail": _acc_0};
}), run_clo((_x_1) => {
  return _acc_0;
})));
        continue;
      }
    }
  }
}

function $nc_primitive_body$(_k_0) {
  return $nc_prim_lambdas$(_k_0, run_loop($nc_primitive_arity$(_k_0)), 0);
}

function $nc_foreign_tel$(_book_0, _ty_0, _name_0, _args_0, _n_0) {
  const _tel_0 = run_loop($wnf$(_book_0, _ty_0));
  return $nt_choose$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_tel_0));
  return $nt_choose$((_x_1 === 0), run_clo((_x_2) => {
  return $nc_foreign_tel$(_book_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), ($atom$("Typ")))), _name_0, _args_0, ((_n_0 + 1) >>> 0));
}), run_clo((_x_3) => {
  return $kt$("Lam", "", ($nc_id$(_n_0)), 1, {$: "Con", "head": run_loop($nc_foreign_tel$(_book_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), ($var$("", ($nc_id$(_n_0)))))), _name_0, ($List$append$(_args_0, {$: "Con", "head": ($var$("", ($nc_id$(_n_0)))), "tail": {$: "Nil"}})), ((_n_0 + 1) >>> 0))), "tail": {$: "Nil"}});
}));
}), run_clo((_x_4) => {
  return $kt$("NCtr", _name_0, 0, 0, _args_0);
}));
}

function $nc_erase$(_book_0, _t_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  return $var$(($nm$(_t_0)), ($ix$(_t_0)));
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_2) => {
  return $nc_erase_annotated$(_book_0, run_loop($kid$(_t_0, 0)), run_loop($wnf$(_book_0, run_loop($kid$(_t_0, 1)))));
}), run_clo((_x_3) => {
  const _x_4 = ($qt$(_t_0));
  return $nt_choose$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Lam")), (_x_4 === 0))), run_clo((_x_5) => {
  return $nc_erase$(_book_0, run_loop($kid$(_t_0, 0)));
}), run_clo((_x_6) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_7) => {
  return $nc_erase_app$(_book_0, _t_0);
}), run_clo((_x_8) => {
  const _x_9 = ($String$eq$(($tg$(_t_0)), "Ctr"));
  const _x_10 = ($String$eq$(($tg$(_t_0)), "Mat"));
  return $kt$(($tg$(_t_0)), run_loop($nt_choose$((_x_9 || _x_10), run_clo((_x_11) => {
  return $nc_ctor_identity$(_book_0, ($nm$(_t_0)));
}), run_clo((_x_12) => {
  return $nm$(_t_0);
}))), ($ix$(_t_0)), ($qt$(_t_0)), ($nc_erase_list$(_book_0, ($ks$(_t_0)))));
}));
}));
}));
}));
}

function $nt_clean$(_s_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_0 = ($Char$is_alpha$(_h_0));
    const _x_1 = ($Char$is_digit$(_h_0));
    const _x_2 = (_x_0 || _x_1);
    const _x_3 = ($Char$is_eq$(_h_0, "_"));
    const _x_6 = run_loop($nt_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return (_h_0 + "");
}), run_clo((_x_5) => {
  return "_";
})));
    const _x_7 = ($nt_clean$(_t_0));
    return (_x_6 + _x_7);
  }
}

function $String$to_upper$(_s_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    return (($Char$to_upper$(_h_0)) + ($String$to_upper$(_t_0)));
  }
}

function $nc_ctor_owned$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return false;
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_0) => {
  return $kc$(($String$eq$(($dk$(run_loop($lookup$(($dc$(_d_0)), _name_0)))), "Ctr")), run_clo((_x_1) => {
  return $db$(_d_0);
}), run_clo((_x_2) => {
  return $nc_ctor_owned$(_rest_0, _name_0);
}));
}), run_clo((_x_3) => {
  return $nc_ctor_owned$(_rest_0, _name_0);
}));
  }
}

function $nc_ctor_encode$(_name_0) {
  const _x_0 = ($nc_ctor_codes$(_name_0));
  return ("$ctor." + _x_0);
}

function $nc_ctor_display$(_name_0) {
  return $kc$(($String$starts_with$(_name_0, "$ctor.")), run_clo((_x_0) => {
  return $nc_ctor_decode$(($String$drop$(_name_0, [..."$ctor."].length)), 0, 0, "", _name_0);
}), run_clo((_x_1) => {
  return _name_0;
}));
}

function $String$drop$($0, $1) {
  for (;;) {
    {
      const _s_0 = $0;
      const _n_0 = $1;
      if (_s_0 === "") {
        return "";
      } else {
        const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        if (_n_0 === 0) {
          return (_h_0 + _t_0);
        } else {
          const _p_0 = (_n_0 - 1);
          $0 = _t_0;
          $1 = _p_0;
          continue;
        }
      }
    }
  }
}

function $nc_live_count$(_book_0, _tel_0, _left_0) {
  return $nt_choose$((_left_0 === 0), run_clo((_x_0) => {
  return 0;
}), run_clo((_x_1) => {
  return $nc_live_count_head$(_book_0, run_loop($wnf$(_book_0, _tel_0)), _left_0);
}));
}

function $nc_skip_tel$(_book_0, _tel_0, _n_0) {
  return $nt_choose$((_n_0 === 0), run_clo((_x_0) => {
  return _tel_0;
}), run_clo((_x_1) => {
  return $nc_skip_tel$(_book_0, run_loop($kid$(run_loop($wnf$(_book_0, _tel_0)), 1)), ((_n_0 - 1) >>> 0));
}));
}

function $nt_bool$(_b_0) {
  if (_b_0) {
    return 1;
  } else {
    return 0;
  }
}

function $nc_source_has_id$(_source_0, _name_0) {
  const _x_0 = ($String$contains$(_source_0, (_name_0 + ",")));
  const _x_1 = ($String$contains$(_source_0, (_name_0 + ")")));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$contains$(_source_0, (_name_0 + " ")));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($String$contains$(_source_0, (_name_0 + "\n")));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($String$contains$(_source_0, (_name_0 + "\t")));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($String$contains$(_source_0, (_name_0 + ";")));
  const _x_10 = (_x_8 || _x_9);
  const _x_11 = ($String$contains$(_source_0, (_name_0 + "]")));
  return (_x_10 || _x_11);
}

function $nt_join$(_xs_0, _sep_0) {
  return $nt_join_go$(_xs_0, _sep_0, "", true);
}

function $String$split$fin$(_c_0, _r_0, _cut_0) {
  if (!_cut_0) {
    return $String$split$push$(_c_0, _r_0);
  } else {
    return {$: "Con", "head": "", "tail": _r_0};
  }
}

function $exact_term$(_a_0, _b_0) {
  const _x_0 = ($ix$(_a_0));
  const _x_1 = ($ix$(_b_0));
  const _x_2 = ($qt$(_a_0));
  const _x_3 = ($qt$(_b_0));
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_a_0)), ($tg$(_b_0)))), ($String$eq$(($nm$(_a_0)), ($nm$(_b_0)))))), (_x_0 === _x_1))), (_x_2 === _x_3))), ($exact_terms$(($ks$(_a_0)), ($ks$(_b_0)))))), ($exact_names$(($rm$(_a_0)), ($rm$(_b_0)))));
}

function $exact_defs$(_a_0, _b_0) {
  if (_a_0.$ === "Nil") {
    return $defs_empty$(_b_0);
  } else {
    const _h_0 = _a_0["head"];
    const _rest_0 = _a_0["tail"];
    return $exact_defs_head$(_h_0, _rest_0, _b_0);
  }
}

function $fpe_rejected$(_result_0, _book_0, _done_0, _sources_0) {
  const _out_0 = _result_0["book"];
  const _error_0 = _result_0["error"];
  const _imports_0 = _result_0["imports"];
  return {$: "FResult", "book": _out_0, "error": run_loop($f_choose$(($String$is_empty$(_error_0)), run_clo((_x_0) => {
  return _error_0;
}), run_clo((_x_1) => {
  return $fpe_selected$(_error_0, run_loop($fpe_find$(_book_0, 0)), _done_0, _sources_0);
}))), "imports": _imports_0};
}

function $f_graph_fresh_result$(_r_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return {$: "FResult", "book": _book_0, "error": run_loop($f_graph_fresh_names$(_book_0, ($missing$()))), "imports": _imports_0};
}), run_clo((_x_1) => {
  return {$: "FResult", "book": _book_0, "error": _err_0, "imports": _imports_0};
}));
}

function $f_validate_result$(_r_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return {$: "FResult", "book": _book_0, "error": run_loop($f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $f_error_defs$(_book_0);
}), run_clo((_x_1) => {
  return _err_0;
}))), "imports": _imports_0};
}

function $index_leaf$(_d_0, _hash_0, _ds_0) {
  return {$: "KDef", "name": "", "kind": "IndexLeaf", "arity": _hash_0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Con", "head": _d_0, "tail": run_loop($index_remove$(_ds_0, ($dn$(_d_0))))}, "native": true, "unsafe": false};
}

function $index_insert$(_tree_0, _d_0, _hash_0, _mask_0) {
  const _x_0 = ($dx$(_tree_0));
  const _x_1 = ($dx$(_tree_0));
  const _x_2 = (_x_0 === 0);
  const _x_3 = (_mask_0 < _x_1);
  return $kc$(($Bool$and$(($Bool$not$((_mask_0 === 0))), (_x_2 || _x_3))), run_clo((_x_4) => {
  return $index_join$(_tree_0, _d_0, _hash_0, _mask_0);
}), run_clo((_x_5) => {
  const _x_6 = ($dx$(_tree_0));
  return $kc$((_x_6 === 0), run_clo((_x_7) => {
  return $index_leaf$(_d_0, _hash_0, ($dc$(_tree_0)));
}), run_clo((_x_8) => {
  const _x_9 = ($dx$(_tree_0));
  const _x_10 = ((_hash_0 & _x_9) >>> 0);
  return $kc$((_x_10 === 0), run_clo((_x_11) => {
  return $index_node$(($da$(_tree_0)), ($dx$(_tree_0)), run_loop($index_insert$(run_loop($index_child$(_tree_0, false)), _d_0, _hash_0, _mask_0)), run_loop($index_child$(_tree_0, true)));
}), run_clo((_x_12) => {
  return $index_node$(($da$(_tree_0)), ($dx$(_tree_0)), run_loop($index_child$(_tree_0, false)), run_loop($index_insert$(run_loop($index_child$(_tree_0, true)), _d_0, _hash_0, _mask_0)));
}));
}));
}));
}

function $index_split_bit$(_diff_0) {
  const _x_0 = ((0 - _diff_0) >>> 0);
  return ((_diff_0 & _x_0) >>> 0);
}

function $index_tip$(_tree_0, _hash_0) {
  const _x_0 = ($dx$(_tree_0));
  return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return _tree_0;
}), run_clo((_x_2) => {
  const _x_3 = ($dx$(_tree_0));
  const _x_4 = ((_hash_0 & _x_3) >>> 0);
  return $index_tip$(run_loop($index_child$(_tree_0, ($Bool$not$((_x_4 === 0))))), _hash_0);
}));
}

function $fs_cached$(_s_0, _ns_0, _sources_0, _g_0, _stack_0, _entry_0, _seed_0) {
  return $f_choose$(($f_eq$(($tg$(_entry_0)), "Absent")), run_clo((_x_0) => {
  return $f_choose$(($Bool$and$(($Bool$and$(($String$is_empty$(_ns_0)), ($f_eq$(($f_source_name$(_s_0)), "Base")))), ($f_eq$(($f_source_path$(_s_0)), ($fs_path$(_seed_0)))))), run_clo((_x_1) => {
  return $fs_inject$(_g_0, _seed_0);
}), run_clo((_x_2) => {
  return $fs_parsed$(_s_0, _ns_0, _sources_0, _g_0, {$: "Con", "head": ($f_source_path$(_s_0)), "tail": _stack_0}, ($f_parse_source$(_s_0)), _seed_0);
}));
}), run_clo((_x_3) => {
  return _g_0;
}));
}

function $f_env$(_name_0, _env_0) {
  if (_env_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _x_0 = _env_0["head"];
    const _xs_0 = _env_0["tail"];
    const _x_1 = ($Bool$not$(($f_eq$(_name_0, "_"))));
    const _x_2 = ($f_eq$(($tg$(_x_0)), "RewriteVar"));
    return $f_choose$(($Bool$and$(($f_eq$(_name_0, ($nm$(_x_0)))), (_x_1 || _x_2))), run_clo((_x_3) => {
  return _x_0;
}), run_clo((_x_4) => {
  return $f_env$(_name_0, _xs_0);
}));
  }
}

function $dr_relies_def$(_book_0, _todo_0, _seen_0, _d_0) {
  const _x_0 = ($du$(_d_0));
  const _x_1 = ($Bool$and$(($String$eq$(($tg$(($dv$(_d_0)))), "Foreign")), ($Bool$not$(($db$(_d_0))))));
  return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return true;
}), run_clo((_x_3) => {
  return $dr_relies$(_book_0, ($kr_dependencies$(_d_0, {$: "Nil"}, _todo_0)), _seen_0);
}));
}

function $dg_suffix_events$(_todo_0, _done_0, _seen_0, _original_0, _origins_0) {
  if (_todo_0.$ === "Nil") {
    return $dg_suffix_finish$(_done_0, _seen_0, _original_0, _origins_0, run_loop($check_open$(_done_0)));
  } else {
    const _d_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $dg_suffix_guard$(_rest_0, _done_0, _d_0, _seen_0, _original_0, _origins_0, run_loop($event_error$(_seen_0, _d_0, run_loop($lookup$(_seen_0, ($dn$(_d_0)))))));
  }
}

function $dg_prefix_step$($0, $1, $2, $3, $4, $5, $6) {
  let $pc = 3;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _origins_0 = $1;
      $0 = _book_0;
      $1 = {$: "Nil"};
      $2 = _origins_0;
      $3 = ($book_cached$({$: "Nil"}, ($norm_max_book$(_book_0))));
      $pc = 1; continue;
    }
    case 1: {
      const _book_0 = $0;
      const _validated_0 = $1;
      const _origins_0 = $2;
      const _seed_0 = $3;
      $0 = _book_0;
      $1 = _validated_0;
      $2 = ($check_declarations$(_book_0, _seed_0));
      $3 = _seed_0;
      $4 = _book_0;
      $5 = _origins_0;
      $pc = 2; continue;
    }
    case 2: {
      const _todo_0 = $0;
      const _validated_0 = $1;
      const _done_0 = $2;
      const _seen_0 = $3;
      const _original_0 = $4;
      const _origins_0 = $5;
      if (_validated_0.$ === "Nil") {
        return $dg_suffix_events$(_todo_0, _done_0, _seen_0, _original_0, _origins_0);
      } else {
        const _head_0 = _validated_0["head"];
        const _tail_0 = _validated_0["tail"];
        $0 = _todo_0;
        $1 = _head_0;
        $2 = _tail_0;
        $3 = _done_0;
        $4 = _seen_0;
        $5 = _original_0;
        $6 = _origins_0;
        $pc = 3; continue;
      }
    }
    case 3: {
      const _todo_0 = $0;
      const _head_0 = $1;
      const _tail_0 = $2;
      const _done_0 = $3;
      const _seen_0 = $4;
      const _original_0 = $5;
      const _origins_0 = $6;
      if (_todo_0.$ === "Nil") {
        $0 = _original_0;
        $1 = _origins_0;
        $pc = 0; continue;
      } else {
        const _rest_0 = _todo_0["tail"];
        $0 = _rest_0;
        $1 = _tail_0;
        $2 = run_loop($check_event_install$(_done_0, _head_0, _rest_0));
        $3 = run_loop($book_put$(_seen_0, _head_0));
        $4 = _original_0;
        $5 = _origins_0;
        $pc = 2; continue;
      }
    }
  }
}

function $dg_render_parts$(_book_0, _expected_0, _observed_0, _has_observed_0, _ctx_0, _name_0, _span_0, _note_0) {
  const _x_7 = ($terms_len$(_ctx_0));
  const _x_13 = run_loop($dg_location$(_name_0, _span_0));
  const _x_14 = run_loop($kc$(($String$eq$(_note_0, "")), run_clo((_x_11) => {
  return "";
}), run_clo((_x_12) => {
  return ("\n" + _note_0);
})));
  const _x_15 = run_loop($kc$((_x_7 === 0), run_clo((_x_8) => {
  return "";
}), run_clo((_x_9) => {
  const _x_10 = ($dg_context$(_book_0, _ctx_0, {$: "Nil"}, run_loop($dg_context_width$(_ctx_0))));
  return ("\nContext:" + _x_10);
})));
  const _x_16 = (_x_13 + _x_14);
  const _x_17 = run_loop($kc$(_has_observed_0, run_clo((_x_0) => {
  const _x_1 = run_loop($dg_expr$(_book_0, _observed_0, ($dg_scope$(_ctx_0, {$: "Nil"}))));
  const _x_2 = run_loop($dg_expr$(_book_0, _expected_0, ($dg_scope$(_ctx_0, {$: "Nil"}))));
  const _x_3 = ("\n- observed : " + _x_1);
  const _x_4 = (_x_2 + _x_3);
  return ("\n- expected : " + _x_4);
}), run_clo((_x_5) => {
  const _x_6 = run_loop($dg_expr$(_book_0, _expected_0, ($dg_scope$(_ctx_0, {$: "Nil"}))));
  return ("\n- message  : " + _x_6);
})));
  const _x_18 = (_x_15 + _x_16);
  const _x_19 = (_x_17 + _x_18);
  return ("Error:" + _x_19);
}

function $dg_origin_found$(_origins_0, _name_0, _rest_0, _found_0) {
  return $kc$(($dg_has_span$(_found_0)), run_clo((_x_0) => {
  return _found_0;
}), run_clo((_x_1) => {
  return $dg_origin_trail$(_origins_0, _name_0, _rest_0);
}));
}

function $dg_origin_scan$(_origins_0, _name_0, _t_0, _found_0) {
  if (_origins_0.$ === "Nil") {
    return _found_0;
  } else {
    const _t_1 = _origins_0["head"];
    const _definition_0 = _t_1["definition"];
    const _term_0 = _t_1["term"];
    const _source_0 = _t_1["source"];
    const _begin_0 = _t_1["begin"];
    const _end_0 = _t_1["end"];
    const _rest_0 = _origins_0["tail"];
    return $kc$(($Bool$and$(($String$eq$(_name_0, _definition_0)), run_loop($norm_exact$(_t_0, _term_0)))), run_clo((_x_0) => {
  const _x_1 = ($Bool$not$(($dg_has_span$(_found_0))));
  const _x_2 = ($dg_span_same$(_found_0, {$: "DSpan", "source": _source_0, "begin": _begin_0, "end": _end_0}));
  return $kc$((_x_1 || _x_2), run_clo((_x_3) => {
  return $dg_origin_scan$(_rest_0, _name_0, _t_0, {$: "DSpan", "source": _source_0, "begin": _begin_0, "end": _end_0});
}), run_clo((_x_4) => {
  return {$: "DNoSpan"};
}));
}), run_clo((_x_5) => {
  return $dg_origin_scan$(_rest_0, _name_0, _t_0, _found_0);
}));
  }
}

function $fp_loaded_modules$(_done_0, _book_0, _sources_0, _all_0, _definition_0) {
  if (_done_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _entry_0 = _done_0["head"];
    const _rest_0 = _done_0["tail"];
    return $List$append$(run_loop($fp_loaded_module$(run_loop($fp_loaded_take$(_book_0, ($ix$(_entry_0)))), run_loop($f_graph_source$(($nm$(_entry_0)), _sources_0)), _all_0, _definition_0)), ($fp_loaded_modules$(_rest_0, run_loop($fp_loaded_drop$(_book_0, ($ix$(_entry_0)))), _sources_0, _all_0, _definition_0)));
  }
}

function $j_printable_head$(_book_0, _ty_0, _seen_0, _fuel_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "Eql")), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "ADT")), ($Bool$not$(($String$eq$(($nm$(_ty_0)), "IO.OP")))))), ($String$eq$(($dk$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), "ADT")))), run_clo((_x_2) => {
  return $j_printable_adt$(_book_0, _ty_0, _seen_0, _fuel_0);
}), run_clo((_x_3) => {
  return false;
}));
}));
}

function $j_layout_term$(_book_0, _env_0, _t_0, _ty_0, _todo_0) {
  return $j_layout_kind$(_book_0, _env_0, _t_0, _ty_0, _todo_0, ($tg$(_t_0)));
}

function $kr_dependencies$(_d_0, _stops_0, _todo_0) {
  return $List$append$(($kr_refs$(($dt$(_d_0)), ($kr_ctor_refs$(($dc$(_d_0)), run_loop($kc$(run_loop($has_name$(_stops_0, ($dn$(_d_0)))), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return $kr_refs$(($dv$(_d_0)), {$: "Nil"});
}))))))), _todo_0);
}

function $kr_resolve_head$(_book_0, _name_0, _d_0) {
  return $kc$(($String$eq$(($dk$(_d_0)), "Absent")), run_clo((_x_0) => {
  return $kr_parent$(_book_0, _name_0);
}), run_clo((_x_1) => {
  return _d_0;
}));
}

function $String$contains$if$($0, $1, $2) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _s_0 = $0;
      const _p_0 = $1;
      if (_s_0 === "") {
        return $String$is_empty$(_p_0);
      } else {
        const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        $0 = _t_0;
        $1 = _p_0;
        $2 = ($String$starts_with$((_h_0 + _t_0), _p_0));
        $pc = 1; continue;
      }
    }
    case 1: {
      const _t_0 = $0;
      const _p_0 = $1;
      const _here_0 = $2;
      if (!_here_0) {
        $0 = _t_0;
        $1 = _p_0;
        $pc = 0; continue;
      } else {
        return true;
      }
    }
  }
}

function $kf_unann$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $kf_unann$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $kf_has_path$(_paths_0, _path_0) {
  if (_paths_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _paths_0["head"];
    const _rest_0 = _paths_0["tail"];
    const _x_0 = ($String$eq$(($nm$(_h_0)), _path_0));
    const _x_1 = ($kf_has_path$(_rest_0, _path_0));
    return (_x_0 || _x_1);
  }
}

function $kf_namespace_step$(_rest_0, _path_0, _ns_0, _seen_0, _prefix_0) {
  return $kc$(($Bool$and$(_seen_0, ($Bool$not$(($String$eq$(_ns_0, _prefix_0)))))), run_clo((_x_0) => {
  return $kt$("Error", (_path_0 + " is imported from two namespaces"), 0, 0, {$: "Nil"});
}), run_clo((_x_1) => {
  return $kf_namespaces$(_rest_0, _path_0, _prefix_0, true);
}));
}

function $String$starts_with$if$($0, $1, $2) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _s_0 = $0;
      const _p_0 = $1;
      if (_s_0 === "") {
        if (_p_0 === "") {
          return true;
        } else {
          return false;
        }
      } else {
        const _h_1 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_1 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        if (_p_0 === "") {
          return true;
        } else {
          const _y_0 = (_p_0.codePointAt(0) > 0xFFFF ? _p_0.slice(0, 2) : _p_0[0]);
          const _yt_0 = (_p_0.codePointAt(0) > 0xFFFF ? _p_0.slice(2) : _p_0.slice(1));
          $0 = _t_1;
          $1 = _yt_0;
          $2 = ($Char$is_eq$(_h_1, _y_0));
          $pc = 1; continue;
        }
      }
    }
    case 1: {
      const _t_0 = $0;
      const _pt_0 = $1;
      const _same_0 = $2;
      if (!_same_0) {
        return false;
      } else {
        $0 = _t_0;
        $1 = _pt_0;
        $pc = 0; continue;
      }
    }
  }
}

function $kf_name$(_source_0, _acc_0) {
  if (_source_0 === "") {
    return $String$reverse$(_acc_0);
  } else {
    const _h_0 = (_source_0.codePointAt(0) > 0xFFFF ? _source_0.slice(0, 2) : _source_0[0]);
    const _rest_0 = (_source_0.codePointAt(0) > 0xFFFF ? _source_0.slice(2) : _source_0.slice(1));
    const _x_0 = ($kf_word$(_h_0));
    const _x_1 = ($Char$is_eq$(_h_0, "."));
    const _x_2 = (_x_0 || _x_1);
    const _x_3 = ($Char$is_eq$(_h_0, "/"));
    const _x_4 = (_x_2 || _x_3);
    const _x_5 = ($Char$is_eq$(_h_0, "~"));
    const _x_6 = (_x_4 || _x_5);
    const _x_7 = ($Char$is_eq$(_h_0, "-"));
    return $kc$((_x_6 || _x_7), run_clo((_x_8) => {
  return $kf_name$(_rest_0, (_h_0 + _acc_0));
}), run_clo((_x_9) => {
  return $String$reverse$(_acc_0);
}));
  }
}

function $kf_resolve$(_book_0, _ns_0, _prefix_0, _name_0) {
  return $kc$(($kf_known$(_book_0, _prefix_0, (_ns_0 + _name_0))), run_clo((_x_0) => {
  return (_ns_0 + _name_0);
}), run_clo((_x_1) => {
  return $kc$(($kf_known$(_book_0, _prefix_0, _name_0)), run_clo((_x_2) => {
  return _name_0;
}), run_clo((_x_3) => {
  return "";
}));
}));
}

function $kf_word$(_c_0) {
  const _n_0 = ($Char$to_u32$(_c_0));
  const _x_0 = ($Bool$and$((_n_0 >= 48), (_n_0 <= 57)));
  const _x_1 = ($Bool$and$((_n_0 >= 65), (_n_0 <= 90)));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($Bool$and$((_n_0 >= 97), (_n_0 <= 122)));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($Char$is_eq$(_c_0, "_"));
  return (_x_4 || _x_5);
}

function $j_ctor_keys$(_ctors_0, _params_0) {
  if (_ctors_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _ctors_0["head"];
    const _rest_0 = _ctors_0["tail"];
    const _x_4 = ($j_ctor_keys$(_rest_0, _params_0));
    const _x_5 = run_loop($j_field_keys$(($dt$(_d_0)), _params_0));
    const _x_6 = ("];\n" + _x_4);
    const _x_7 = (_x_5 + _x_6);
    const _x_8 = ($j_quote$(($dn$(_d_0))));
    const _x_9 = ("]=[" + _x_7);
    const _x_10 = (_x_8 + _x_9);
    const _x_11 = ($j_quote$(run_loop($kc$(($String$eq$(($nm$(($dv$(_d_0)))), "")), run_clo((_x_2) => {
  return $dn$(_d_0);
}), run_clo((_x_3) => {
  return $nm$(($dv$(_d_0)));
})))));
    const _x_12 = (";constructors[" + _x_10);
    const _x_13 = (_x_11 + _x_12);
    const _x_14 = ($j_quote$(($dn$(_d_0))));
    const _x_15 = ("]=" + _x_13);
    const _x_16 = (_x_14 + _x_15);
    const _x_17 = run_loop($kc$(($db$(_d_0)), run_clo((_x_0) => {
  return "true";
}), run_clo((_x_1) => {
  return "false";
})));
    const _x_18 = (";constructorOwn[" + _x_16);
    const _x_19 = (_x_17 + _x_18);
    const _x_20 = ($j_quote$(($dn$(_d_0))));
    const _x_21 = ("]=" + _x_19);
    const _x_22 = (_x_20 + _x_21);
    return ("constructorNative[" + _x_22);
  }
}

function $j_schema_ctors$(_book_0, _ctors_0, _params_0) {
  if (_ctors_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _ctors_0["head"];
    const _rest_0 = _ctors_0["tail"];
    const _x_0 = ($j_schema_ctors$(_book_0, _rest_0, _params_0));
    const _x_1 = run_loop($j_schema_params$(_book_0, ($dt$(_d_0)), _params_0, 0));
    const _x_2 = ("})()," + _x_0);
    const _x_3 = (_x_1 + _x_2);
    const _x_4 = ($j_quote$(($dn$(_d_0))));
    const _x_5 = (":(()=>{" + _x_3);
    return (_x_4 + _x_5);
  }
}

function $j_def$(_book_0, _d_0) {
  return $kc$(($String$eq$(($tg$(($dv$(_d_0)))), "Foreign")), run_clo((_x_0) => {
  return $j_foreign_def$(_book_0, _d_0);
}), run_clo((_x_1) => {
  const _x_2 = ($dx$(_d_0));
  return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), (_x_2 === 0))), ($Bool$not$(($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))))), ($Bool$not$(($String$eq$(($tg$(($dv$(_d_0)))), "Foreign")))))), run_clo((_x_3) => {
  const _x_8 = run_loop($kc$(($Bool$and$(($db$(_d_0)), ($j_intrinsic$(($dn$(_d_0)))))), run_clo((_x_4) => {
  const _x_5 = ($j_quote$(($dn$(_d_0))));
  const _x_6 = (_x_5 + "))");
  return ("if(!Object.hasOwn(G," + _x_6);
}), run_clo((_x_7) => {
  return "";
})));
  const _x_9 = run_loop($j_l_def$(_book_0, _d_0));
  return (_x_8 + _x_9);
}), run_clo((_x_10) => {
  return "";
}));
}));
}

function $fpe_here$(_source_0, _rest_0, _error_0) {
  return $f_choose$(($String$is_empty$(_rest_0)), run_clo((_x_0) => {
  return $f_choose$(($String$eq$(($nm$(run_loop($kid$(_error_0, 1)))), "<eof>")), run_clo((_x_1) => {
  return $fpe_message$(_source_0, _error_0, "end of input");
}), run_clo((_x_2) => {
  return $nm$(_error_0);
}));
}), run_clo((_x_3) => {
  const _x_4 = ($Char$to_u32$(($f_head$(_rest_0))));
  const _x_5 = ($Char$to_u32$(($f_head$(($nm$(run_loop($kid$(_error_0, 1))))))));
  const _x_6 = ($Char$to_u32$(($f_head$(_rest_0))));
  const _x_7 = ($Bool$not$((_x_4 === _x_5)));
  const _x_8 = (_x_6 > 65535);
  const _x_9 = ($Char$to_u32$(($f_head$(_rest_0))));
  const _x_10 = ($Char$to_u32$(($f_head$(_rest_0))));
  const _x_11 = (_x_7 || _x_8);
  const _x_12 = ($Bool$and$((_x_9 >= 55296), (_x_10 <= 57343)));
  return $f_choose$((_x_11 || _x_12), run_clo((_x_13) => {
  return $nm$(_error_0);
}), run_clo((_x_14) => {
  const _x_15 = (($f_head$(_rest_0)) + "");
  const _x_16 = (_x_15 + "'");
  return $fpe_message$(_source_0, _error_0, ("'" + _x_16));
}));
}));
}

function $f_import_leading$(_ts_0, _book_0, _imports_0, _unsafe_0) {
  if (_book_0.$ === "Nil") {
    return $f_choose$(_unsafe_0, run_clo((_x_0) => {
  return $f_result$({$: "Nil"}, ($f_pn$(($f_err$(_ts_0, "expected def after @unsafe")))), _imports_0);
}), run_clo((_x_1) => {
  return $f_import$(($f_tl$(_ts_0)), {$: "Nil"}, _imports_0);
}));
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $f_result$({$: "Con", "head": _d_0, "tail": _rest_0}, ($f_pn$(($fpe_error$(_ts_0, "expected def, law or type; imports must precede declarations", "'def', 'type' or 'law'")))), _imports_0);
  }
}

function $f_law$(_name_0, _ts_0, _book_0, _imports_0, _clauses_0) {
  return $f_choose$(($Bool$and$(($f_valid_name$(_name_0)), ($f_eq$(($dk$(run_loop($f_find$(_name_0, _book_0)))), "Missing")))), run_clo((_x_0) => {
  return $f_law_base$(_name_0, _ts_0, _book_0, _imports_0, _clauses_0);
}), run_clo((_x_1) => {
  return $f_result$(_book_0, ($kt$("Error", ("invalid or reserved law name: " + _name_0), 0, 0, {$: "Nil"})), _imports_0);
}));
}

function $f_def_header$(_ts_0, _book_0, _imports_0, _unsafe_0) {
  const _x_0 = ($f_line$(_ts_0));
  const _x_1 = ($f_line$(($f_tl$(_ts_0))));
  const _x_2 = ($f_tx$(_ts_0));
  const _x_3 = [..._x_2].length;
  const _x_4 = ($f_col$(_ts_0));
  const _x_5 = (_x_3 >>> 0);
  const _x_6 = ($f_col$(($f_tl$(_ts_0))));
  const _x_7 = ((_x_4 + _x_5) >>> 0);
  const _suffix_0 = ($Bool$and$(($Bool$and$(($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "?")), (_x_0 === _x_1))), (_x_6 === _x_7)));
  const _rest_0 = run_loop($f_space$(run_loop($f_choose$(_suffix_0, run_clo((_x_8) => {
  return $f_tl$(($f_tl$(_ts_0)));
}), run_clo((_x_9) => {
  return $f_tl$(_ts_0);
})))));
  return $f_choose$(($Bool$not$(($f_valid_name$(($f_tx$(_ts_0)))))), run_clo((_x_10) => {
  const _x_11 = ($f_tx$(_ts_0));
  const _x_12 = (_x_11 + "')");
  return $f_result$(_book_0, ($f_pn$(($fpe_error$(_ts_0, "invalid definition name", ("a name (words joined by dots, got '" + _x_12))))), _imports_0);
}), run_clo((_x_13) => {
  return $f_choose$(($f_eq$(($f_tx$(_rest_0)), "(")), run_clo((_x_14) => {
  return $f_def$(($f_tx$(_ts_0)), run_loop($f_tele$(($f_tl$(_rest_0)), ")", {$: "Nil"})), _book_0, _imports_0, (_unsafe_0 || _suffix_0));
}), run_clo((_x_15) => {
  return $f_result$(_book_0, ($f_pn$(($fpe_error$(_rest_0, "expected (", "'('")))), _imports_0);
}));
}));
}

function $f_space$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "\n")), run_clo((_x_0) => {
  return $f_space$(($f_tl$(_ts_0)));
}), run_clo((_x_1) => {
  return _ts_0;
}));
}

function $f_type$(_name_0, _ts_0, _book_0, _imports_0) {
  return $f_choose$(($Bool$and$(($f_valid_name$(_name_0)), ($f_eq$(($dk$(run_loop($f_find$(_name_0, _book_0)))), "Missing")))), run_clo((_x_0) => {
  return $f_type_named$(_name_0, _ts_0, _book_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_result$(_book_0, ($kt$("Error", ("invalid or reserved datatype name: " + _name_0), 0, 0, {$: "Nil"})), _imports_0);
}));
}

function $fpe_error$(_ts_0, _legacy_0, _expected_0) {
  return $fpe_legacy$(_ts_0, ($nm$(($f_pn$(($f_err$(_ts_0, _legacy_0)))))), _expected_0);
}

function $f_line$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _ts_0["head"];
    const _l_0 = _t_0["f_line"];
    return _l_0;
  }
}

function $String$reverse$go$($0, $1) {
  for (;;) {
    {
      const _s_0 = $0;
      const _acc_0 = $1;
      if (_s_0 === "") {
        return _acc_0;
      } else {
        const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        $0 = _t_0;
        $1 = (_h_0 + _acc_0);
        continue;
      }
    }
  }
}

function $f_ascii_alpha$(_c_0) {
  const _x_0 = ($Char$to_u32$(_c_0));
  const _x_1 = ((_x_0 | 32) >>> 0);
  const _x_2 = ((_x_1 - 97) >>> 0);
  return (_x_2 <= 25);
}

function $f_fresh_book_stack$(_book_0, _next_0) {
  return $ffd_walk$(_book_0, _next_0, {$: "Nil"}, {$: "Nil"});
}

function $f_load_imports$(_imports_0, _sources_0, _seen_0, _stack_0, _book_0) {
  if (_imports_0.$ === "Nil") {
    return {$: "FLoaded", "book": _book_0, "error": "", "seen": _seen_0};
  } else {
    const _im_0 = _imports_0["head"];
    const _rest_0 = _imports_0["tail"];
    return $f_load_import_next$(_rest_0, _sources_0, _stack_0, _book_0, run_loop($f_load_module$(($nm$(_im_0)), run_loop($f_choose$(($f_eq$(($nm$(_im_0)), "Base")), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  return $nm$(_im_0);
}))), _sources_0, _seen_0, _stack_0)));
  }
}

function $f_path_defs$(_ds_0, _dir_0, _native_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    const _x_2 = ($db$(_d_0));
    return {$: "Con", "head": {$: "KDef", "name": ($dn$(_d_0)), "kind": ($dk$(_d_0)), "arity": ($da$(_d_0)), "templates": ($dx$(_d_0)), "typ": ($dt$(_d_0)), "value": run_loop($f_choose$(($f_eq$(($tg$(($dv$(_d_0)))), "Foreign")), run_clo((_x_0) => {
  return $f_path_term$(($dv$(_d_0)), _dir_0);
}), run_clo((_x_1) => {
  return $dv$(_d_0);
}))), "ctors": ($f_path_defs$(($dc$(_d_0)), _dir_0, _native_0)), "native": (_native_0 || _x_2), "unsafe": ($du$(_d_0))}, "tail": ($f_path_defs$(_rest_0, _dir_0, _native_0))};
  }
}

function $f_qual_result$(_r_0, _ns_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return {$: "FResult", "book": run_loop($f_qual_optional$(_book_0, _book_0, _ns_0, _imports_0)), "error": _err_0, "imports": _imports_0};
}

function $f_elaborate$(_r_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return $f_validate_result$({$: "FResult", "book": ($f_elab_defs$(_book_0, run_loop($f_family_book$(_book_0)))), "error": _err_0, "imports": _imports_0});
}

function $ka_wrap$(_t_0, _ty_0) {
  return $kt$("Ann", "", 0, 0, {$: "Con", "head": _t_0, "tail": {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}});
}

function $ka_node$(_e_0, _ctx_0, _t_0, _ty_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  return $kc$(($core_nat_type$(($cb$(_e_0)), _ty_0)), run_clo((_x_1) => {
  return _t_0;
}), run_clo((_x_2) => {
  return $ka_node$(_e_0, _ctx_0, run_loop($core_nat_step$(_t_0)), _ty_0);
}));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_4) => {
  return $ka_node$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), run_loop($wnf$(($cb$(_e_0)), run_loop($kid$(_t_0, 1)))));
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_6) => {
  return $ka_lam$(_e_0, _ctx_0, _t_0, _ty_0);
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_8) => {
  return $kc$(run_loop($ka_spine_eligible$(_t_0)), run_clo((_x_9) => {
  return $ka_app_spine$(_e_0, _ctx_0, _t_0);
}), run_clo((_x_10) => {
  return $ka_app$(_e_0, _ctx_0, _t_0, run_loop($wnf$(($cb$(_e_0)), run_loop($ka_type$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)))))));
}));
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_12) => {
  return $kt$("Ctr", ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), run_loop($ka_args_cached$(_e_0, _ctx_0, run_loop($tele_fill$(($cb$(_e_0)), ($dt$(run_loop($lookup$(($dc$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_ty_0)))))), ($nm$(_t_0)))))), ($ks$(_ty_0)))), ($ks$(_t_0)))));
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Mat")), run_clo((_x_14) => {
  return $ka_mat$(_e_0, _ctx_0, _t_0, _ty_0, run_loop($wnf$(($cb$(_e_0)), run_loop($kid$(_ty_0, 0)))));
}), run_clo((_x_15) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Let")), run_clo((_x_16) => {
  return $kt$("Let", ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), run_loop($ka_let$(_e_0, _ctx_0, _ctx_0, ($ks$(_t_0)), _ty_0)));
}), run_clo((_x_17) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_18) => {
  return $ka_rwt$(_e_0, _ctx_0, _t_0, run_loop($wnf$(($cb$(_e_0)), run_loop($ka_type$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)))))));
}), run_clo((_x_19) => {
  return _t_0;
}));
}));
}));
}));
}));
}));
}));
}));
}

function $core_beta$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $core_apply$(run_loop($core_beta$(run_loop($kid$(_t_0, 0)))), run_loop($kid$(_t_0, 1)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $cb$(_e_0) {
  const _book_0 = _e_0["book"];
  return _book_0;
}

function $String$cmp$rec$(_h1b_0, _h2b_0, _rr_0) {
  const _t_0 = _rr_0["fst"];
  const _t1b_0 = _t_0["fst"];
  const _t2b_0 = _t_0["snd"];
  const _r_0 = _rr_0["snd"];
  return {$: "Tuple", "fst": {$: "Tuple", "fst": (_h1b_0 + _t1b_0), "snd": (_h2b_0 + _t2b_0)}, "snd": _r_0};
}

function $j_escape_char_on$(_c_0, _key_0) {
  if (_key_0 == 34) {
    return "\\\"";
  } else if (_key_0 == 10) {
    return "\\n";
  } else if ((_key_0 & 3) == 2) {
    const _9_0 = u32_to_word(_key_0)["tail"]["tail"]["head"];
    const _10_0 = u32_to_word(_key_0)["tail"]["tail"]["tail"];
    return $Char$show$(($Char$from_u32$(word_to_u32({$: "WCon", "head": false, "tail": {$: "WCon", "head": true, "tail": {$: "WCon", "head": _9_0, "tail": _10_0}}}))));
  } else if (_key_0 == 92) {
    return "\\\\";
  } else if ((_key_0 & 7) == 4) {
    const _127_0 = u32_to_word(_key_0)["tail"]["tail"]["tail"]["head"];
    const _128_0 = u32_to_word(_key_0)["tail"]["tail"]["tail"]["tail"];
    return $Char$show$(($Char$from_u32$(word_to_u32({$: "WCon", "head": false, "tail": {$: "WCon", "head": false, "tail": {$: "WCon", "head": true, "tail": {$: "WCon", "head": _127_0, "tail": _128_0}}}}))));
  } else if (_key_0 == 0) {
    return "\\x00";
  } else if ((_key_0 & 7) == 0) {
    const _185_0 = u32_to_word(_key_0)["tail"]["tail"]["tail"]["head"];
    const _186_0 = u32_to_word(_key_0)["tail"]["tail"]["tail"]["tail"];
    return $Char$show$(($Char$from_u32$(word_to_u32({$: "WCon", "head": false, "tail": {$: "WCon", "head": false, "tail": {$: "WCon", "head": false, "tail": {$: "WCon", "head": _185_0, "tail": _186_0}}}}))));
  } else if (_key_0 == 13) {
    return "\\r";
  } else if (_key_0 == 9) {
    return "\\t";
  } else {
    const _243_0 = u32_to_word(_key_0)["tail"]["head"];
    const _244_0 = u32_to_word(_key_0)["tail"]["tail"];
    return $Char$show$(($Char$from_u32$(word_to_u32({$: "WCon", "head": true, "tail": {$: "WCon", "head": _243_0, "tail": _244_0}}))));
  }
}

function $j_choice_call$(_book_0, _spine_0) {
  const _x_0 = ($terms_len$(($ks$(_spine_0))));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_spine_0)), "Call")), (_x_0 === 4))), run_clo((_x_1) => {
  return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(_spine_0, 2)))))), "Lam")), ($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(_spine_0, 3)))))), "Lam")))), ($String$eq$(run_loop($j_l_name$(run_loop($j_strip$(run_loop($kid$(_spine_0, 2)))))), "")))), ($String$eq$(run_loop($j_l_name$(run_loop($j_strip$(run_loop($kid$(_spine_0, 3)))))), "")))), run_clo((_x_2) => {
  return $j_choice_definition$(_book_0, run_loop($lookup$(_book_0, ($nm$(_spine_0)))));
}), run_clo((_x_3) => {
  return false;
}));
}), run_clo((_x_4) => {
  return false;
}));
}

function $j_choice_emit$(_book_0, _env_0, _spine_0, _tail_0) {
  return $j_choice_after_type$(_book_0, _env_0, ($ks$(_spine_0)), _tail_0, run_loop($wnf$(_book_0, run_loop($j_app_type$(run_loop($wnf$(_book_0, ($dt$(run_loop($lookup$(_book_0, ($nm$(_spine_0)))))))), run_loop($kid$(_spine_0, 0)))))));
}

function $j_apply_regular$(_book_0, _env_0, _t_0, _tail_0, _fty_0, _spine_0) {
  const _x_0 = ($terms_len$(($ks$(_spine_0))));
  const _x_1 = ($terms_len$(($ks$(_spine_0))));
  const _x_2 = run_loop($j_call_arity$(run_loop($lookup$(_book_0, ($nm$(_spine_0))))));
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_spine_0)), "Call")), (_x_0 > 1))), (_x_1 <= _x_2))), run_clo((_x_3) => {
  const _x_6 = ($j_apply_args$(_book_0, _env_0, ($ks$(_spine_0)), ($dt$(run_loop($lookup$(_book_0, ($nm$(_spine_0))))))));
  const _x_7 = (_x_6 + "])");
  const _x_8 = ($j_quote$(($nm$(_spine_0))));
  const _x_9 = ("),[" + _x_7);
  const _x_10 = (_x_8 + _x_9);
  const _x_11 = run_loop($kc$(_tail_0, run_clo((_x_4) => {
  return "jump(";
}), run_clo((_x_5) => {
  return "call(";
})));
  const _x_12 = ("get(G," + _x_10);
  return (_x_11 + _x_12);
}), run_clo((_x_13) => {
  return $j_apply_one$(_book_0, _env_0, _t_0, _tail_0, _fty_0);
}));
}

function $j_env$(_env_0, _id_0) {
  if (_env_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _h_0 = _env_0["head"];
    const _rest_0 = _env_0["tail"];
    const _x_0 = ($ix$(_h_0));
    return $kc$((_x_0 === _id_0), run_clo((_x_1) => {
  return $kid$(_h_0, 0);
}), run_clo((_x_2) => {
  return $j_env$(_rest_0, _id_0);
}));
  }
}

function $j_app_type$(_ty_0, _arg_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  return $subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), _arg_0);
}), run_clo((_x_1) => {
  return $atom$("Absent");
}));
}

function $j_literal$(_t_0) {
  return $j_literal_node$(run_loop($j_strip$(_t_0)));
}

function $j_literal_provenance$(_book_0, _ty_0, _literal_0) {
  const _d_0 = run_loop($lookup$(_book_0, ($nm$(_ty_0))));
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "ADT")), ($String$eq$(($dk$(_d_0)), "ADT")))), ($Bool$not$(($db$(_d_0)))))), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  return _literal_0;
}));
}

function $j_found_ctor$(_found_0, _rest_0, _name_0) {
  return $kc$(($String$eq$(($dk$(_found_0)), "Absent")), run_clo((_x_0) => {
  return $j_find_ctor$(_rest_0, _name_0);
}), run_clo((_x_1) => {
  return _found_0;
}));
}

function $j_constructor_literal$(_book_0, _env_0, _t_0, _ty_0, _literal_0) {
  return $kc$(($String$eq$(_literal_0, "")), run_clo((_x_0) => {
  const _x_1 = ($j_ctor_args$(_book_0, _env_0, ($ks$(_t_0)), ($j_specialize$(_book_0, ($dt$(run_loop($j_find_ctor$(_book_0, ($nm$(_t_0)))))), ($ks$(run_loop($wnf$(_book_0, _ty_0))))))));
  const _x_2 = (_x_1 + "])");
  const _x_3 = ($j_quote$(($nm$(_t_0))));
  const _x_4 = (",[" + _x_2);
  const _x_5 = (_x_3 + _x_4);
  return ("ctor(" + _x_5);
}), run_clo((_x_6) => {
  return _literal_0;
}));
}

function $j_lambda_bind$(_book_0, _env_0, _t_0, _ty_0, _at_0) {
  const _x_0 = ($qt$(_ty_0));
  const _x_5 = run_loop($j_lambda_code$(_book_0, {$: "Con", "head": ($kt$("Env", "", ($ix$(_t_0)), 0, {$: "Con", "head": run_loop($kid$(_ty_0, 0)), "tail": {$: "Nil"}})), "tail": _env_0}, run_loop($kid$(_t_0, 0)), run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))), ((_at_0 + 1) >>> 0)));
  const _x_6 = run_loop($kc$(($Bool$and$((_x_0 === 0), ($String$eq$(($tg$(_ty_0)), "All")))), run_clo((_x_1) => {
  return "null";
}), run_clo((_x_2) => {
  const _x_3 = ($U32$show$(_at_0));
  const _x_4 = (_x_3 + "]");
  return ("a[" + _x_4);
})));
  const _x_7 = (";" + _x_5);
  const _x_8 = (_x_6 + _x_7);
  const _x_9 = ($j_local$(($ix$(_t_0))));
  const _x_10 = ("=" + _x_8);
  const _x_11 = (_x_9 + _x_10);
  return ("const " + _x_11);
}

function $j_count_constructors$(_ctors_0, _removed_0) {
  if (_ctors_0.$ === "Nil") {
    return 0;
  } else {
    const _d_0 = _ctors_0["head"];
    const _rest_0 = _ctors_0["tail"];
    const _x_2 = run_loop($kc$(run_loop($has_name$(_removed_0, ($dn$(_d_0)))), run_clo((_x_0) => {
  return 0;
}), run_clo((_x_1) => {
  return 1;
})));
    const _x_3 = ($j_count_constructors$(_rest_0, _removed_0));
    return ((_x_2 + _x_3) >>> 0);
  }
}

function $j_arm_tel$(_book_0, _tel_0, _ret_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return $all$(($qt$(_tel_0)), ($nm$(_tel_0)), ($ix$(_tel_0)), run_loop($kid$(_tel_0, 0)), run_loop($j_arm_tel$(_book_0, run_loop($kid$(_tel_0, 1)), _ret_0)));
}), run_clo((_x_1) => {
  return _ret_0;
}));
}

function $U32$show$go$($0, $1, $2, $3) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _f_0 = $0;
      const _n_0 = $1;
      const _acc_0 = $2;
      if (_f_0 === 0) {
        return _acc_0;
      } else {
        const _g_0 = (_f_0 - 1);
        $0 = _g_0;
        $1 = _acc_0;
        $2 = _n_0;
        $3 = (_n_0 === 0);
        $pc = 1; continue;
      }
    }
    case 1: {
      const _g_0 = $0;
      const _acc_0 = $1;
      const _n_0 = $2;
      const _z_0 = $3;
      if (_z_0) {
        return _acc_0;
      } else {
        const _x_0 = (10 === 0 ? _n_0 : _n_0 % 10);
        $0 = _g_0;
        $1 = (10 === 0 ? 0 : (_n_0 / 10) >>> 0);
        $2 = (char_new(((48 + _x_0) >>> 0)) + _acc_0);
        $pc = 0; continue;
      }
    }
  }
}

function $j_desc_args$(_book_0, _args_0, _fuel_0) {
  if (_args_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    const _x_0 = ($j_desc_args$(_book_0, _rest_0, _fuel_0));
    const _x_1 = run_loop($j_descriptor$(_book_0, _h_0, _fuel_0));
    const _x_2 = ("," + _x_0);
    return (_x_1 + _x_2);
  }
}

function $norm_apply$($0, $1) {
  for (;;) {
    {
      const _t_0 = $0;
      const _args_0 = $1;
      if (_args_0.$ === "Nil") {
        return _t_0;
      } else {
        const _h_0 = _args_0["head"];
        const _rest_0 = _args_0["tail"];
        $0 = ($app$(_t_0, _h_0));
        $1 = _rest_0;
        continue;
      }
    }
  }
}

function $norm_let$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return $norm_let_tail$(_h_0, _rest_0);
  }
}

function $norm_ref$(_book_0, _t_0, _args_0, _d_0) {
  return $kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_0) => {
  const _x_1 = ($da$(_d_0));
  return $kc$((_x_1 === 0), run_clo((_x_2) => {
  return $norm_apply$(($kt$("ADT", ($nm$(_t_0)), 0, 0, {$: "Nil"})), _args_0);
}), run_clo((_x_3) => {
  return $norm_apply$(_t_0, _args_0);
}));
}), run_clo((_x_4) => {
  const _x_5 = ($String$eq$(($tg$(($dv$(_d_0)))), "Absent"));
  const _x_6 = ($String$eq$(($tg$(($dv$(_d_0)))), "Foreign"));
  const _x_7 = ($da$(_d_0));
  const _x_8 = ($terms_len$(_args_0));
  return $kc$(($Bool$and$(($Bool$not$((_x_5 || _x_6))), (_x_7 <= _x_8))), run_clo((_x_9) => {
  return $norm_eval$(_book_0, ($dv$(_d_0)), _args_0, ($da$(_d_0)), ($norm_apply$(_t_0, _args_0)));
}), run_clo((_x_10) => {
  return $norm_apply$(_t_0, _args_0);
}));
}));
}

function $norm_min$(_book_0, _a_0, _b_0) {
  return $norm_min_left$(_book_0, run_loop($wnf$(_book_0, _a_0)), _b_0);
}

function $norm_args$(_book_0, _t_0, _args_0, _left_0, _fallback_0) {
  if (_args_0.$ === "Nil") {
    return _t_0;
  } else {
    const _x_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_1) => {
  return $norm_eval$(_book_0, run_loop($subst$(run_loop($kid$(_t_0, 0)), ($ix$(_t_0)), _x_0)), _rest_0, run_loop($norm_dec$(_left_0)), _fallback_0);
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Mat")), run_clo((_x_3) => {
  return $norm_match$(_book_0, _t_0, _t_0, _x_0, run_loop($wnf$(_book_0, _x_0)), _rest_0, _left_0, _fallback_0);
}), run_clo((_x_4) => {
  return $kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Efq")), ($Bool$not$((_left_0 === 0))))), run_clo((_x_5) => {
  return _fallback_0;
}), run_clo((_x_6) => {
  return $norm_apply$(_t_0, {$: "Con", "head": _x_0, "tail": _rest_0});
}));
}));
}));
  }
}

function $index_bucket$(_ds_0, _name_0) {
  if (_ds_0.$ === "Nil") {
    return $missing$();
  } else {
    const _h_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return $kc$(($String$eq$(($dn$(_h_0)), _name_0)), run_clo((_x_0) => {
  return _h_0;
}), run_clo((_x_1) => {
  return $index_bucket$(_rest_0, _name_0);
}));
  }
}

function $index_child$(_tree_0, _right_0) {
  return $index_child_list$(($dc$(_tree_0)), _right_0);
}

function $Char$show$(_c_0) {
  return (_c_0 + "");
}

function $Char$to_lower$(_c_0) {
  const _x_0 = ($Bool$to_u32$(($Char$is_upper$(_c_0))));
  const _x_1 = _c_0.codePointAt(0);
  const _x_2 = (Math.imul(_x_0, 32) >>> 0);
  return char_new(((_x_1 + _x_2) >>> 0));
}

function $book_final_name_valid$(_name_0) {
  if (_name_0 === "") {
    return true;
  } else {
    const _h_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(0, 2) : _name_0[0]);
    const _rest_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(2) : _name_0.slice(1));
    const _x_0 = ($Char$to_u32$(_h_0));
    const _x_1 = ((_x_0 - 55296) >>> 0);
    return $kc$((_x_1 <= 2047), run_clo((_x_2) => {
  return false;
}), run_clo((_x_3) => {
  return $book_final_name_valid$(_rest_0);
}));
  }
}

function $book_final_filter$(_done_0, _seen_0) {
  if (_done_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _done_0["head"];
    const _rest_0 = _done_0["tail"];
    return $kc$(($book_final_seen$(_seen_0, ($dn$(_d_0)), ($index_hash$(($dn$(_d_0)), 2166136261)))), run_clo((_x_0) => {
  return $book_final_filter$(_rest_0, _seen_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": _d_0, "tail": run_loop($book_final_filter$(_rest_0, _seen_0))};
}));
  }
}

function $book_final_step$(_d_0, _rest_0, _seen_0, _kept_0, _done_0, _hash_0) {
  return $kc$(($book_final_seen$(_seen_0, ($dn$(_d_0)), _hash_0)), run_clo((_x_0) => {
  return $book_final_scan$(_rest_0, _seen_0, _kept_0, _done_0);
}), run_clo((_x_1) => {
  return $book_final_scan$(_rest_0, run_loop($index_set$(_seen_0, {$: "KDef", "name": ($dn$(_d_0)), "kind": "$final.seen", "arity": 0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": true, "unsafe": false}, _hash_0, 32)), {$: "Con", "head": _d_0, "tail": _kept_0}, _done_0);
}));
}

function $kp_index$(_env_0, _id_0) {
  if (_env_0.$ === "Nil") {
    return _id_0;
  } else {
    const _t_0 = _env_0["head"];
    const _i_0 = _t_0["id"];
    const _depth_0 = _t_0["depth"];
    const _tail_0 = _env_0["tail"];
    return $kc$((_i_0 === _id_0), run_clo((_x_0) => {
  return _depth_0;
}), run_clo((_x_1) => {
  return $kp_index$(_tail_0, _id_0);
}));
  }
}

function $kp_depth$(_env_0) {
  if (_env_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _env_0["tail"];
    const _x_0 = ($kp_depth$(_t_0));
    return ((1 + _x_0) >>> 0);
  }
}

function $kp_application$(_s_0, _p_0, _env_0) {
  const _xs_0 = _s_0["items"];
  const _h_0 = _s_0["tail"];
  const _x_0 = ($terms_len$(_xs_0));
  return $kc$(($Bool$and$(($Bool$and$(($kp_is$(_h_0, "Ref", "Exists")), (_x_0 === 2))), ($kp_eq$(($tg$(run_loop($terms_at$(_xs_0, 1)))), "Lam")))), run_clo((_x_1) => {
  return $kp_exists$(run_loop($terms_at$(_xs_0, 0)), run_loop($terms_at$(_xs_0, 1)), _p_0, _env_0);
}), run_clo((_x_2) => {
  const _x_3 = ($kp_join$(($kp_each$(_xs_0, 1, _env_0)), ", "));
  const _x_4 = (_x_3 + ")");
  const _x_5 = run_loop($kp_go$(_h_0, 3, _env_0));
  const _x_6 = ("(" + _x_4);
  return (_x_5 + _x_6);
}));
}

function $kp_spine$(_t_0, _acc_0) {
  return $kc$(($kp_eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $kp_spine$(run_loop($kid$(_t_0, 0)), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _acc_0});
}), run_clo((_x_1) => {
  return {$: "KPChain", "items": _acc_0, "tail": _t_0};
}));
}

function $kp_adt$(_t_0, _p_0, _env_0) {
  const _x_0 = ($terms_len$(($ks$(_t_0))));
  const _x_5 = run_loop($kc$(($Bool$and$((_x_0 === 0), ($Bool$not$(($kp_has_removed$(($rm$(_t_0)))))))), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  const _x_3 = ($kp_join$(($kp_each$(($ks$(_t_0)), 1, _env_0)), ", "));
  const _x_4 = (_x_3 + ">");
  return ("<" + _x_4);
})));
  const _x_6 = ($kp_removed$(($rm$(_t_0))));
  const _x_7 = ($nm$(_t_0));
  const _x_8 = (_x_5 + _x_6);
  return $kp_par$((_x_7 + _x_8), ($Bool$and$(($kp_has_removed$(($rm$(_t_0)))), (_p_0 > 2))));
}

function $kp_ctor$(_t_0, _p_0, _env_0) {
  return $kp_ctor_number$(run_loop($kp_number$(_t_0)), _t_0, _p_0, _env_0);
}

function $kp_matches$(_t_0, _env_0) {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Mat")), run_clo((_x_0) => {
  const _x_4 = run_loop($kp_go$(run_loop($kid$(_t_0, 0)), 2, _env_0));
  const _x_5 = run_loop($kc$(($kp_eq$(($tg$(run_loop($kid$(_t_0, 1)))), "Efq")), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  const _x_3 = run_loop($kp_matches$(run_loop($kid$(_t_0, 1)), _env_0));
  return ("; " + _x_3);
})));
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ($nm$(_t_0));
  const _x_8 = (": " + _x_6);
  return (_x_7 + _x_8);
}), run_clo((_x_9) => {
  return $kp_go$(_t_0, 2, _env_0);
}));
}

function $kp_go_last$(_t_0, _p_0, _env_0) {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Sub")), run_clo((_x_0) => {
  return $kp_go$(run_loop($kid$(_t_0, 1)), _p_0, _env_0);
}), run_clo((_x_1) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_2) => {
  return $kp_rewrite$(_t_0, _p_0, _env_0);
}), run_clo((_x_3) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Let")), run_clo((_x_4) => {
  return $kp_let$(_t_0, _p_0, _env_0);
}), run_clo((_x_5) => {
  return $kc$(($kp_eq$(($tg$(_t_0)), "Literal")), run_clo((_x_6) => {
  return $nm$(_t_0);
}), run_clo((_x_7) => {
  const _x_8 = ($nm$(_t_0));
  const _x_9 = (_x_8 + ">");
  const _x_10 = ($tg$(_t_0));
  const _x_11 = (":" + _x_9);
  const _x_12 = (_x_10 + _x_11);
  return ("<" + _x_12);
}));
}));
}));
}));
}

function $g_snf_go$(_book_0, _st_0, _t_0, _stack_0, _fresh_0) {
  return $g_snf_head$(_book_0, _stack_0, _fresh_0, run_loop($g_wnf$(_book_0, _st_0, _t_0)));
}

function $norm_bound_found$(_book_0, _stamp_0) {
  return $kc$(($String$eq$(($dk$(_stamp_0)), "BookBound")), run_clo((_x_0) => {
  return $da$(_stamp_0);
}), run_clo((_x_1) => {
  return $norm_max_book$(_book_0);
}));
}

function $norm_max_walk$($0, $1) {
  for (;;) {
    {
      const _todo_0 = $0;
      const _bound_0 = $1;
      if (_todo_0.$ === "Nil") {
        return _bound_0;
      } else {
        const _h_0 = _todo_0["head"];
        const _rest_0 = _todo_0["tail"];
        $0 = ($norm_join$(($ks$(_h_0)), _rest_0));
        $1 = run_loop($norm_max$(_bound_0, ($ix$(_h_0))));
        continue;
      }
    }
  }
}

function $sp_neededs$(_book_0, _ts_0) {
  if (_ts_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return $kc$(run_loop($sp_needed$(_book_0, _h_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $sp_neededs$(_book_0, _rest_0);
}));
  }
}

function $check_event_install$(_done_0, _d_0, _rest_0) {
  return $kc$(($String$eq$(($dk$(run_loop($lookup$(_rest_0, ($dn$(_d_0)))))), "Absent")), run_clo((_x_0) => {
  return $book_put$(_done_0, _d_0);
}), run_clo((_x_1) => {
  return _done_0;
}));
}

function $sp_memo$(_st_0) {
  const _memo_0 = _st_0["memo"];
  return _memo_0;
}

function $sp_serial$(_st_0) {
  const _serial_0 = _st_0["serial"];
  return _serial_0;
}

function $sp_fresh$(_st_0) {
  const _fresh_0 = _st_0["fresh"];
  return _fresh_0;
}

function $sp_state$(_r_0) {
  const _state_0 = _r_0["state"];
  return _state_0;
}

function $sp_value$(_r_0) {
  const _term_0 = _r_0["term"];
  return _term_0;
}

function $sp_spine$(_st_0, _t_0, _xs_0, _ctx_0, _owner_0, _depth_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $sp_spine$(_st_0, run_loop($kid$(_t_0, 0)), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _xs_0}, _ctx_0, _owner_0, _depth_0);
}), run_clo((_x_1) => {
  return $sp_head$(_st_0, _t_0, _xs_0, _ctx_0, _owner_0, _depth_0, run_loop($lookup$(($sp_book$(_st_0)), ($nm$(run_loop($strip$(_t_0)))))));
}));
}

function $sp_annotation$(_t_0, _r_0) {
  return {$: "KSpecTerm", "state": ($sp_state$(_r_0)), "term": {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": {$: "Con", "head": ($sp_value$(_r_0)), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Nil"}}}, "removed": ($rm$(_t_0))}};
}

function $sp_lambda$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0) {
  return $sp_single$(_t_0, run_loop($sp_term$(_st_0, run_loop($kid$(_t_0, 0)), ($ctx_bind$(_ctx_0, ($ix$(_t_0)), ($qt$(_goal_0)), ($nm$(_t_0)), run_loop($kid$(_goal_0, 0)))), run_loop($subst$(run_loop($kid$(_goal_0, 1)), ($ix$(_goal_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))), _owner_0, _depth_0)));
}

function $sp_match$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0) {
  return $sp_match_type$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0, run_loop($wnf$(($sp_book$(_st_0)), run_loop($kid$(_goal_0, 0)))));
}

function $sp_constructor$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0) {
  return $sp_ctor_done$(_t_0, ($sp_args$(_st_0, ($ks$(_t_0)), _ctx_0, run_loop($tele_fill$(($sp_book$(_st_0)), ($dt$(run_loop($lookup$(($dc$(run_loop($lookup$(($sp_book$(_st_0)), ($nm$(_goal_0)))))), ($nm$(_t_0)))))), ($ks$(_goal_0)))), _owner_0, _depth_0)));
}

function $sp_let_result$(_t_0, _r_0) {
  return $sp_ctor_done$(_t_0, _r_0);
}

function $sp_let$(_st_0, _xs_0, _outer_0, _ctx_0, _goal_0, _owner_0, _depth_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "KSpecTerms", "state": ($sp_fail$(_st_0, "let has no body")), "terms": {$: "Nil"}};
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $kc$(($String$eq$(($tg$(_h_0)), "Bind")), run_clo((_x_0) => {
  return $sp_let_binding$(_st_0, _h_0, _rest_0, _outer_0, _ctx_0, _goal_0, _owner_0, _depth_0, ($sp_type$(_st_0, run_loop($kid$(_h_0, 0)), _outer_0, _owner_0)));
}), run_clo((_x_1) => {
  return $sp_let_body$(run_loop($sp_term$(_st_0, _h_0, _ctx_0, _goal_0, _owner_0, _depth_0)));
}));
  }
}

function $sp_rewrite$(_st_0, _t_0, _ctx_0, _owner_0, _depth_0) {
  return $sp_rewrite_type$(_st_0, _t_0, _ctx_0, _owner_0, _depth_0, run_loop($wnf$(($sp_book$(_st_0)), ($sp_type$(_st_0, run_loop($kid$(_t_0, 0)), _ctx_0, _owner_0)))));
}

function $nt_count$(_xs_0) {
  return $nt_count_go$(_xs_0, 0);
}

function $nv_unique$(_xs_0, _seen_0) {
  return $nv_unique_index$(($List$append$(_seen_0, _xs_0)), ($missing$()));
}

function $nv_ctor_names$(_cs_0) {
  if (_cs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _cs_0["head"];
    const _k_0 = _t_0["name"];
    const _rest_0 = _cs_0["tail"];
    return {$: "Con", "head": ($nt_cid$(_k_0)), "tail": ($nv_ctor_names$(_rest_0))};
  }
}

function $nv_seg_names$(_ss_0) {
  return $nv_seg_names_go$(_ss_0, {$: "Nil"});
}

function $nv_ctors$(_cs_0) {
  if (_cs_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _cs_0["head"];
    const _k_0 = _t_0["name"];
    const _a_0 = _t_0["arity"];
    const _rest_0 = _cs_0["tail"];
    return $nt_choose$((_a_0 > 255), run_clo((_x_0) => {
  return ("native constructor arity exceeds 255: " + _k_0);
}), run_clo((_x_1) => {
  return $nv_ctors$(_rest_0);
}));
  }
}

function $nv_segs$(_ss_0) {
  if (_ss_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _ss_0["head"];
    const _k_0 = _t_0["name"];
    const _ps_0 = _t_0["params"];
    const _r_0 = _t_0["result"];
    const _rest_0 = _ss_0["tail"];
    const _x_0 = ($nt_count$(_ps_0));
    const _x_1 = (_x_0 > 255);
    const _x_2 = (_r_0 > 255);
    return $nt_choose$((_x_1 || _x_2), run_clo((_x_3) => {
  return ("native segment arity exceeds 255: " + _k_0);
}), run_clo((_x_4) => {
  return $nv_segs$(_rest_0);
}));
  }
}

function $ne_fill$(_src_0, _mark_0, _text_0) {
  const _x_0 = ("\n\n" + _text_0);
  return $nt_replace$(_src_0, _mark_0, (_mark_0 + _x_0));
}

function $nb_emit$(_ss_0, _cs_0, _image_size_0, _pure_0) {
  const _x_0 = ($U32$show$(($nt_bool$(_pure_0))));
  const _x_1 = (_x_0 + "\n");
  const _x_2 = ($nb_dispatch$(_ss_0));
  const _x_3 = ("\n#define MAIN_FID FID_MAIN\n#define MAIN_PURE " + _x_1);
  const _x_4 = (_x_2 + _x_3);
  const _x_5 = ($U32$show$(_image_size_0));
  const _x_6 = ("\n#define WL_TABLE " + _x_4);
  const _x_7 = (_x_5 + _x_6);
  const _x_8 = ("#define STAT_LEN " + _x_7);
  const _x_9 = ($nb_ctr_hot$(_cs_0));
  const _x_10 = (" };\n" + _x_8);
  const _x_11 = (_x_9 + _x_10);
  const _x_12 = ("CONSTV u8 CID_HOT_T[] = { " + _x_11);
  const _x_13 = ($nb_ctr_arity$(_cs_0));
  const _x_14 = (" };\n" + _x_12);
  const _x_15 = (_x_13 + _x_14);
  const _x_16 = ("CONSTV u8 CID_ARITY_T[] = { " + _x_15);
  const _x_17 = ($nb_result_words$(_ss_0));
  const _x_18 = (" };\n" + _x_16);
  const _x_19 = (_x_17 + _x_18);
  const _x_20 = ("CONSTV u8 FID_RESW_T[] = { " + _x_19);
  const _x_21 = ($nb_flags$(_ss_0, run_loop($nb_fork_close$(_ss_0, ($nb_fork_roots$(_ss_0)), ($nt_count$(_ss_0))))));
  const _x_22 = (" };\n" + _x_20);
  const _x_23 = (_x_21 + _x_22);
  const _x_24 = ("CONSTV u8 FID_FLAG_T[] = { " + _x_23);
  const _x_25 = ($nb_arities$(_ss_0));
  const _x_26 = (" };\n" + _x_24);
  const _x_27 = (_x_25 + _x_26);
  const _x_28 = ($nb_bank$(_ss_0));
  const _x_29 = ("CONSTV u8 FID_ARITY_T[] = { " + _x_27);
  const _x_30 = ($nb_ctr_ids$(_cs_0, 0));
  const _x_31 = (_x_28 + _x_29);
  const _x_32 = ($nb_seg_ids$(_ss_0, 0));
  const _x_33 = (_x_30 + _x_31);
  return (_x_32 + _x_33);
}

function $ne_segments$(_ss_0) {
  return $ne_segments_go$(_ss_0, "");
}

function $nc_show_names$(_cs_0) {
  if (_cs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _cs_0["head"];
    const _k_0 = _t_0["name"];
    const _rest_0 = _cs_0["tail"];
    const _x_0 = ($nc_quote_chars$(run_loop($nc_ctor_display$(_k_0))));
    const _x_1 = (_x_0 + "\"");
    return {$: "Con", "head": ("\"" + _x_1), "tail": ($nc_show_names$(_rest_0))};
  }
}

function $nc_show_step$(_book_0, _i_0, _offset_0, _defs_0, _cells_0, _d_0) {
  return $nt_choose$(($String$eq$(($nc_desc_error$(_d_0)), "")), run_clo((_x_0) => {
  const _x_1 = ($nt_count$(($nc_desc_cells$(_d_0))));
  const _x_2 = ($U32$show$(_offset_0));
  const _x_3 = (_x_2 + "\n");
  const _x_4 = ($U32$show$(_i_0));
  const _x_5 = (" " + _x_3);
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ("#define SD_" + _x_6);
  return $nc_show_nodes$(_book_0, ($nc_desc_types$(_d_0)), ((_i_0 + 1) >>> 0), ((_offset_0 + _x_1) >>> 0), (_defs_0 + _x_7), ($List$append$(_cells_0, ($nc_desc_cells$(_d_0)))));
}), run_clo((_x_8) => {
  return {$: "NC_Show", "source": "", "error": ($nc_desc_error$(_d_0))};
}));
}

function $nc_show_node$(_book_0, _ty_0, _types_0) {
  const _k_0 = run_loop($nt_choose$(($db$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), run_clo((_x_0) => {
  return $nm$(_ty_0);
}), run_clo((_x_1) => {
  return "";
})));
  return $nt_choose$(($String$eq$(_k_0, "U32")), run_clo((_x_2) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "0", "tail": {$: "Nil"}}, "types": _types_0, "error": ""};
}), run_clo((_x_3) => {
  return $nt_choose$(($String$eq$(_k_0, "F32")), run_clo((_x_4) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "1", "tail": {$: "Nil"}}, "types": _types_0, "error": ""};
}), run_clo((_x_5) => {
  return $nt_choose$(($String$eq$(_k_0, "Nat")), run_clo((_x_6) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "2", "tail": {$: "Nil"}}, "types": _types_0, "error": ""};
}), run_clo((_x_7) => {
  return $nt_choose$(($String$eq$(_k_0, "Char")), run_clo((_x_8) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "3", "tail": {$: "Con", "head": "0", "tail": {$: "Nil"}}}, "types": _types_0, "error": ""};
}), run_clo((_x_9) => {
  return $nt_choose$(($String$eq$(_k_0, "String")), run_clo((_x_10) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "4", "tail": {$: "Nil"}}, "types": _types_0, "error": ""};
}), run_clo((_x_11) => {
  return $nt_choose$(($String$eq$(_k_0, "Bool")), run_clo((_x_12) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "7", "tail": {$: "Con", "head": "0", "tail": {$: "Con", "head": "2", "tail": {$: "Con", "head": "CID_FALSE", "tail": {$: "Con", "head": "CID_FALSE", "tail": {$: "Con", "head": "0", "tail": {$: "Con", "head": "CID_TRUE", "tail": {$: "Con", "head": "CID_TRUE", "tail": {$: "Con", "head": "0", "tail": {$: "Nil"}}}}}}}}}}, "types": _types_0, "error": ""};
}), run_clo((_x_13) => {
  return $nt_choose$(($String$eq$(($tg$(_ty_0)), "Eql")), run_clo((_x_14) => {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "5", "tail": {$: "Nil"}}, "types": _types_0, "error": ""};
}), run_clo((_x_15) => {
  return $nt_choose$(($String$eq$(_k_0, "Array")), run_clo((_x_16) => {
  return $nc_show_array$(run_loop($nc_show_ref$(_book_0, run_loop($kid$(_ty_0, 0)), _types_0)));
}), run_clo((_x_17) => {
  return $nt_choose$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "ADT")), ($String$eq$(($dk$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), "ADT")))), ($Bool$not$(($String$eq$(_k_0, "IO.OP")))))), run_clo((_x_18) => {
  return $nc_show_data$(_book_0, _ty_0, _types_0);
}), run_clo((_x_19) => {
  return {$: "NC_Desc", "cells": {$: "Nil"}, "types": _types_0, "error": "native readback cannot print a function, type, or dependent field"};
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $nc_compact_ctor$(_t_0, _lit_0) {
  const _valid_0 = _lit_0["valid"];
  const _value_0 = _lit_0["value"];
  return $nt_choose$(_valid_0, run_clo((_x_0) => {
  return $kt$("NWord", ($U32$show$(_value_0)), 0, 0, {$: "Nil"});
}), run_clo((_x_1) => {
  return $kt$(($tg$(_t_0)), ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), ($nc_compact_list$(($ks$(_t_0)))));
}));
}

function $nc_literal$(_t_0) {
  const _x_0 = ($String$eq$(($nm$(_t_0)), "U32"));
  const _x_1 = ($String$eq$(($nm$(_t_0)), "F32"));
  return $nt_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $nc_word_literal$(run_loop($kid$(_t_0, 0)), 0, 0);
}), run_clo((_x_3) => {
  return $nc_nat_literal$(_t_0, 0);
}));
}

function $nc_compact_list$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": run_loop($nc_compact$(_h_0)), "tail": ($nc_compact_list$(_rest_0))};
  }
}

function $nc_terms_fork$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($terms_len$(($ks$(_h_0))));
    const _x_1 = ($Bool$and$(($String$eq$(($tg$(_h_0)), "Let")), (_x_0 > 2)));
    const _x_2 = ($Bool$and$(($String$eq$(($tg$(_h_0)), "App")), ($String$eq$(($tg$(run_loop($nc_call_head$(_h_0)))), "Var"))));
    return $nt_choose$((_x_1 || _x_2), run_clo((_x_3) => {
  return true;
}), run_clo((_x_4) => {
  return $nc_terms_fork$(($nt_append$(($ks$(_h_0)), _rest_0)));
}));
  }
}

function $nc_mark_segments$(_ss_0, _bang_0, _forked_0, _calls_0) {
  return $nc_mark_segments_go$(_ss_0, _bang_0, _forked_0, _calls_0, {$: "Nil"});
}

function $nd_bindings$(_t_0, _acc_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_0) => {
  return $nd_bindings$(run_loop($kid$(_t_0, 0)), {$: "Con", "head": ($nc_binding$(($ix$(_t_0)))), "tail": _acc_0});
}), run_clo((_x_1) => {
  return $nt_reverse$(_acc_0, {$: "Nil"});
}));
}

function $nd_join$(_base_0, _body_0, _name_0, _params_0) {
  return {$: "NC_Code", "body": ($nc_body$(_base_0)), "segments": ($nt_append$(($nc_segs$(_base_0)), {$: "Con", "head": {$: "N_Segment", "name": ($nd_name$(_name_0)), "params": ($nc_params$(_params_0)), "result": 1, "frame": {$: "N_Direct"}, "body": ($nc_body$(_body_0)), "refs": {$: "Nil"}, "host": false, "spin": false, "fork": false, "bang": false}, "tail": ($nc_segs$(_body_0))})), "fresh": ($nc_fresh$(_body_0)), "error": run_loop($nc_first_error$(_base_0, _body_0))};
}

function $nd_body$(_t_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_0) => {
  return $nd_body$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $nc_prepend$(_code_0, _x_0) {
  const _body_0 = _x_0["body"];
  const _segs_0 = _x_0["segments"];
  const _fresh_0 = _x_0["fresh"];
  const _err_0 = _x_0["error"];
  return {$: "NC_Code", "body": (_code_0 + _body_0), "segments": _segs_0, "fresh": _fresh_0, "error": _err_0};
}

function $nc_drop_dead$(_env_0, _t_0) {
  if (_env_0.$ === "Nil") {
    return "";
  } else {
    const _t_1 = _env_0["head"];
    const _id_0 = _t_1["id"];
    const _word_0 = _t_1["word"];
    const _rest_0 = _env_0["tail"];
    const _x_3 = run_loop($nt_choose$(run_loop($nc_occurs$(_t_0, _id_0)), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = (_word_0 + ");\n");
  return ("term_sink(e, " + _x_2);
})));
    const _x_4 = ($nc_drop_dead$(_rest_0, _t_0));
    return (_x_3 + _x_4);
  }
}

function $nc_lower_live$(_book_0, _t_0, _env_0, _n_0) {
  const _tag_0 = ($tg$(_t_0));
  return $nt_choose$(($String$eq$(_tag_0, "NWord")), run_clo((_x_0) => {
  const _x_1 = ($nm$(_t_0));
  return $nc_return$((_x_1 + "ull"), _n_0);
}), run_clo((_x_2) => {
  return $nt_choose$(($String$eq$(_tag_0, "Var")), run_clo((_x_3) => {
  return $nt_choose$(($String$eq$(run_loop($nc_word$(($ix$(_t_0)), _env_0)), "NATIVE_UNBOUND_VARIABLE")), run_clo((_x_4) => {
  const _x_5 = ($U32$show$(($ix$(_t_0))));
  return $nc_fail$(("native unbound variable " + _x_5), _n_0);
}), run_clo((_x_6) => {
  return $nc_return$(run_loop($nc_word$(($ix$(_t_0)), _env_0)), _n_0);
}));
}), run_clo((_x_7) => {
  return $nt_choose$(($String$eq$(_tag_0, "Ref")), run_clo((_x_8) => {
  return {$: "NC_Code", "body": ($ne_jump$({$: "Nil"}, run_loop($nc_ref_name$(_book_0, ($nm$(_t_0)))))), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}), run_clo((_x_9) => {
  const _x_10 = ($String$eq$(_tag_0, "Ann"));
  const _x_11 = ($String$eq$(_tag_0, "Loc"));
  const _x_12 = (_x_10 || _x_11);
  const _x_13 = ($String$eq$(_tag_0, "Src"));
  const _x_14 = (_x_12 || _x_13);
  const _x_15 = ($String$eq$(_tag_0, "Cut"));
  const _x_16 = (_x_14 || _x_15);
  const _x_17 = ($String$eq$(_tag_0, "Slf"));
  const _x_18 = (_x_16 || _x_17);
  const _x_19 = ($String$eq$(_tag_0, "Ins"));
  return $nt_choose$((_x_18 || _x_19), run_clo((_x_20) => {
  return $nc_lower$(_book_0, run_loop($kid$(_t_0, 0)), _env_0, _n_0);
}), run_clo((_x_21) => {
  return $nt_choose$(($String$eq$(_tag_0, "Lam")), run_clo((_x_22) => {
  return $nc_lambda$(_book_0, _t_0, _env_0, _n_0);
}), run_clo((_x_23) => {
  return $nt_choose$(($String$eq$(_tag_0, "App")), run_clo((_x_24) => {
  return $nd_app$(_book_0, _t_0, _env_0, _n_0);
}), run_clo((_x_25) => {
  return $nt_choose$(($String$eq$(_tag_0, "Let")), run_clo((_x_26) => {
  const _x_27 = ($terms_len$(($ks$(_t_0))));
  return $nt_choose$((_x_27 > 2), run_clo((_x_28) => {
  return $nc_parallel$(_book_0, ($ks$(_t_0)), _env_0, _n_0);
}), run_clo((_x_29) => {
  return $nc_lets$(_book_0, ($ks$(_t_0)), _env_0, _n_0);
}));
}), run_clo((_x_30) => {
  return $nt_choose$(($String$eq$(_tag_0, "NSeqLet")), run_clo((_x_31) => {
  return $nc_lets$(_book_0, ($ks$(_t_0)), _env_0, _n_0);
}), run_clo((_x_32) => {
  return $nt_choose$(($String$eq$(_tag_0, "Ctr")), run_clo((_x_33) => {
  return $nc_lower_ctor$(_book_0, _t_0, _env_0, _n_0, run_loop($nc_literal$(_t_0)));
}), run_clo((_x_34) => {
  return $nt_choose$(($String$eq$(_tag_0, "NCtr")), run_clo((_x_35) => {
  return $nc_constructor$(($nm$(_t_0)), ($nc_values$(($ks$(_t_0)), _env_0)), _n_0);
}), run_clo((_x_36) => {
  return $nt_choose$(($String$eq$(_tag_0, "NApply")), run_clo((_x_37) => {
  return $nc_apply_code$(($nc_values$(($ks$(_t_0)), _env_0)), _n_0);
}), run_clo((_x_38) => {
  return $nt_choose$(($String$eq$(_tag_0, "NCall")), run_clo((_x_39) => {
  return {$: "NC_Code", "body": ($ne_jump$(($nc_values$(($ks$(_t_0)), _env_0)), ($nm$(_t_0)))), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}), run_clo((_x_40) => {
  const _x_41 = ($String$eq$(_tag_0, "Rfl"));
  const _x_42 = ($String$eq$(_tag_0, "Typ"));
  const _x_43 = (_x_41 || _x_42);
  const _x_44 = ($String$eq$(_tag_0, "All"));
  const _x_45 = (_x_43 || _x_44);
  const _x_46 = ($String$eq$(_tag_0, "Qua"));
  const _x_47 = (_x_45 || _x_46);
  const _x_48 = ($String$eq$(_tag_0, "ADT"));
  const _x_49 = (_x_47 || _x_48);
  const _x_50 = ($String$eq$(_tag_0, "Eql"));
  return $nt_choose$((_x_49 || _x_50), run_clo((_x_51) => {
  return $nc_return$("0", _n_0);
}), run_clo((_x_52) => {
  return $nt_choose$(($String$eq$(_tag_0, "Mat")), run_clo((_x_53) => {
  return $nc_match$(_book_0, _t_0, _env_0, _n_0);
}), run_clo((_x_54) => {
  return $nt_choose$(($String$eq$(_tag_0, "NMatch")), run_clo((_x_55) => {
  return $nc_match_apply$(_book_0, _t_0, _env_0, _n_0);
}), run_clo((_x_56) => {
  return $nt_choose$(($String$eq$(_tag_0, "NOp")), run_clo((_x_57) => {
  return $nc_intrinsic$(($nm$(_t_0)), ($nc_values$(($ks$(_t_0)), _env_0)), _n_0);
}), run_clo((_x_58) => {
  return $nt_choose$(($String$eq$(_tag_0, "Efq")), run_clo((_x_59) => {
  return {$: "NC_Code", "body": "err_post(e.mem, ERR_FIDS); return 0;\n", "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}), run_clo((_x_60) => {
  return $nt_choose$(($String$eq$(_tag_0, "Rwt")), run_clo((_x_61) => {
  return $nc_lower$(_book_0, run_loop($kid$(_t_0, 2)), _env_0, _n_0);
}), run_clo((_x_62) => {
  return $nc_fail$(("native lowering does not support core node " + _tag_0), _n_0);
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $nc_live_env$(_env_0, _t_0) {
  if (_env_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_1 = _env_0["head"];
    const _id_0 = _t_1["id"];
    const _word_0 = _t_1["word"];
    const _rest_0 = _env_0["tail"];
    return $nt_choose$(run_loop($nc_occurs$(_t_0, _id_0)), run_clo((_x_0) => {
  return {$: "Con", "head": {$: "NC_Binding", "id": _id_0, "word": _word_0}, "tail": run_loop($nc_live_env$(_rest_0, _t_0))};
}), run_clo((_x_1) => {
  return $nc_live_env$(_rest_0, _t_0);
}));
  }
}

function $nc_body$(_x_0) {
  const _body_0 = _x_0["body"];
  return _body_0;
}

function $nt_append$(_xs_0, _ys_0) {
  return $nt_reverse$(($nt_reverse$(_xs_0, {$: "Nil"})), _ys_0);
}

function $nc_segs$(_x_0) {
  const _segs_0 = _x_0["segments"];
  return _segs_0;
}

function $nc_error$(_x_0) {
  const _err_0 = _x_0["error"];
  return _err_0;
}

function $nt_reverse$($0, $1) {
  for (;;) {
    {
      const _xs_0 = $0;
      const _acc_0 = $1;
      if (_xs_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        $0 = _t_0;
        $1 = {$: "Con", "head": _h_0, "tail": _acc_0};
        continue;
      }
    }
  }
}

function $nc_prim_lambdas$(_k_0, _n_0, _i_0) {
  return $nt_choose$((_i_0 === _n_0), run_clo((_x_0) => {
  return $kt$("NOp", _k_0, 0, 0, run_loop($nc_prim_args$(_n_0, 0)));
}), run_clo((_x_1) => {
  return $kt$("Lam", "", ((4000000000 + _i_0) >>> 0), 1, {$: "Con", "head": run_loop($nc_prim_lambdas$(_k_0, _n_0, ((_i_0 + 1) >>> 0))), "tail": {$: "Nil"}});
}));
}

function $nc_primitive_arity$(_k_0) {
  const _fmt_0 = run_loop($ni_find$(_k_0, ($ni_templates$())));
  const _x_0 = ($String$eq$(_k_0, "array_set"));
  const _x_1 = ($String$eq$(_k_0, "array_swap"));
  return $nt_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return 3;
}), run_clo((_x_3) => {
  const _x_4 = ($String$eq$(_k_0, "array_new"));
  const _x_5 = ($String$eq$(_k_0, "array_get"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($String$eq$(_k_0, "nat_divmod"));
  return $nt_choose$((_x_6 || _x_7), run_clo((_x_8) => {
  return 2;
}), run_clo((_x_9) => {
  return $nt_choose$(($String$eq$(_fmt_0, run_loop($nt_replace$(_fmt_0, "$1", "?")))), run_clo((_x_10) => {
  return 1;
}), run_clo((_x_11) => {
  return 2;
}));
}));
}));
}

function $subst$(_t_0, _id_0, _v_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  const _x_1 = ($ix$(_t_0));
  return $kc$((_x_1 === _id_0), run_clo((_x_2) => {
  return _v_0;
}), run_clo((_x_3) => {
  return _t_0;
}));
}), run_clo((_x_4) => {
  return $subst_node$(_t_0, _id_0, _v_0);
}));
}

function $nc_id$(_n_0) {
  return ((4294967295 - _n_0) >>> 0);
}

function $var$(_name_0, _id_0) {
  return $kt$("Var", _name_0, _id_0, 0, {$: "Nil"});
}

function $nc_erase_annotated$(_book_0, _t_0, _ty_0) {
  return $nt_choose$(($String$eq$(($tg$(_ty_0)), "Eql")), run_clo((_x_0) => {
  return $atom$("Rfl");
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_2) => {
  return $kt$("Ctr", run_loop($nt_choose$(($db$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), run_clo((_x_3) => {
  return $nm$(_t_0);
}), run_clo((_x_4) => {
  return $nc_ctor_identity$(_book_0, ($nm$(_t_0)));
}))), ($ix$(_t_0)), ($qt$(_t_0)), run_loop($nc_erase_args$(_book_0, ($nc_tele_fill$(_book_0, ($dt$(run_loop($lookup$(($dc$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), ($nm$(_t_0)))))), ($ks$(_ty_0)))), ($ks$(_t_0)))));
}), run_clo((_x_5) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Mat")), run_clo((_x_6) => {
  return $nc_erase_mat$(_book_0, _t_0, run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0)))));
}), run_clo((_x_7) => {
  return $nc_erase$(_book_0, _t_0);
}));
}));
}));
}

function $nc_erase_app$(_book_0, _t_0) {
  return $nt_choose$(($String$eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Ann")), run_clo((_x_0) => {
  const _x_1 = ($qt$(run_loop($wnf$(_book_0, run_loop($kid$(run_loop($kid$(_t_0, 0)), 1))))));
  return $nt_choose$((_x_1 === 0), run_clo((_x_2) => {
  return $nc_erase$(_book_0, run_loop($kid$(_t_0, 0)));
}), run_clo((_x_3) => {
  return $kt$(($tg$(_t_0)), ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), ($nc_erase_list$(_book_0, ($ks$(_t_0)))));
}));
}), run_clo((_x_4) => {
  return $kt$(($tg$(_t_0)), ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), ($nc_erase_list$(_book_0, ($ks$(_t_0)))));
}));
}

function $nc_erase_list$(_book_0, _ts_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": run_loop($nc_erase$(_book_0, _h_0)), "tail": ($nc_erase_list$(_book_0, _rest_0))};
  }
}

function $Char$is_alpha$(_c_0) {
  const _x_0 = ($Char$is_upper$(_c_0));
  const _x_1 = ($Char$is_lower$(_c_0));
  return (_x_0 || _x_1);
}

function $Char$is_digit$(_c_0) {
  const _x_0 = _c_0.codePointAt(0);
  const _x_1 = _c_0.codePointAt(0);
  return $Bool$and$((_x_0 >= 48), (_x_1 <= 57));
}

function $Char$to_upper$(_c_0) {
  const _x_0 = ($Bool$to_u32$(($Char$is_lower$(_c_0))));
  const _x_1 = _c_0.codePointAt(0);
  const _x_2 = (Math.imul(_x_0, 32) >>> 0);
  return char_new(((_x_1 - _x_2) >>> 0));
}

function $nc_ctor_codes$(_name_0) {
  if (_name_0 === "") {
    return "";
  } else {
    const _h_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(0, 2) : _name_0[0]);
    const _rest_0 = (_name_0.codePointAt(0) > 0xFFFF ? _name_0.slice(2) : _name_0.slice(1));
    const _x_0 = ($nc_ctor_codes$(_rest_0));
    const _x_1 = ($U32$show$(($Char$to_u32$(_h_0))));
    const _x_2 = ("_" + _x_0);
    return (_x_1 + _x_2);
  }
}

function $nc_ctor_decode$(_rest_0, _acc_0, _digits_0, _out_0, _original_0) {
  if (_rest_0 === "") {
    return $kc$(($Bool$and$((_digits_0 === 0), ($String$eq$(($nc_ctor_encode$(_out_0)), _original_0)))), run_clo((_x_0) => {
  return _out_0;
}), run_clo((_x_1) => {
  return _original_0;
}));
  } else {
    const _h_0 = (_rest_0.codePointAt(0) > 0xFFFF ? _rest_0.slice(0, 2) : _rest_0[0]);
    const _tail_0 = (_rest_0.codePointAt(0) > 0xFFFF ? _rest_0.slice(2) : _rest_0.slice(1));
    return $nc_ctor_decode_step$(_h_0, _tail_0, _acc_0, _digits_0, _out_0, _original_0);
  }
}

function $nc_live_count_head$(_book_0, _head_0, _left_0) {
  const _x_0 = ($qt$(_head_0));
  const _x_1 = ($nt_bool$(($Bool$not$((_x_0 === 0)))));
  const _x_2 = run_loop($nc_live_count$(_book_0, run_loop($kid$(_head_0, 1)), ((_left_0 - 1) >>> 0)));
  return ((_x_1 + _x_2) >>> 0);
}

function $nt_join_go$($0, $1, $2, $3) {
  for (;;) {
    {
      const _xs_0 = $0;
      const _sep_0 = $1;
      const _acc_0 = $2;
      const _first_0 = $3;
      if (_xs_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        const _x_2 = run_loop($nt_choose$(_first_0, run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  return _sep_0;
})));
        const _x_3 = (_x_2 + _h_0);
        $0 = _t_0;
        $1 = _sep_0;
        $2 = (_acc_0 + _x_3);
        $3 = false;
        continue;
      }
    }
  }
}

function $String$split$push$(_c_0, _ps_0) {
  if (_ps_0.$ === "Nil") {
    return {$: "Con", "head": (_c_0 + ""), "tail": {$: "Nil"}};
  } else {
    const _h_0 = _ps_0["head"];
    const _t_0 = _ps_0["tail"];
    return {$: "Con", "head": (_c_0 + _h_0), "tail": _t_0};
  }
}

function $exact_terms$(_a_0, _b_0) {
  if (_a_0.$ === "Nil") {
    const _x_0 = ($terms_len$(_b_0));
    return (_x_0 === 0);
  } else {
    const _h_0 = _a_0["head"];
    const _rest_0 = _a_0["tail"];
    return $exact_terms_head$(_h_0, _rest_0, _b_0);
  }
}

function $exact_names$(_a_0, _b_0) {
  if (_a_0.$ === "Nil") {
    return $exact_names_empty$(_b_0);
  } else {
    const _h_0 = _a_0["head"];
    const _rest_0 = _a_0["tail"];
    return $exact_names_head$(_h_0, _rest_0, _b_0);
  }
}

function $defs_empty$(_ds_0) {
  if (_ds_0.$ === "Nil") {
    return true;
  } else {
    return false;
  }
}

function $exact_defs_head$(_h_0, _rest_0, _b_0) {
  if (_b_0.$ === "Nil") {
    return false;
  } else {
    const _x_0 = _b_0["head"];
    const _xs_0 = _b_0["tail"];
    return $Bool$and$(($exact_def$(_h_0, _x_0)), ($exact_defs$(_rest_0, _xs_0)));
  }
}

function $fpe_selected$(_legacy_0, _owner_0, _done_0, _sources_0) {
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_owner_0)), "ParseOwner")), ($String$eq$(($nm$(run_loop($kid$(_owner_0, 0)))), _legacy_0)))), run_clo((_x_0) => {
  return $fpe_source_render$(_legacy_0, run_loop($kid$(_owner_0, 0)), run_loop($fpe_unique_source$(run_loop($fpe_owner_path$(($List$reverse$(_done_0)), ($ix$(_owner_0)))), _sources_0, ($atom$("Absent")))));
}), run_clo((_x_1) => {
  return _legacy_0;
}));
}

function $fpe_find$(_ds_0, _index_0) {
  if (_ds_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _head_0 = _ds_0["head"];
    const _tail_0 = _ds_0["tail"];
    return $fpe_find_next$(run_loop($fpe_def$(_head_0)), _tail_0, _index_0);
  }
}

function $f_graph_fresh_names$(_todo_0, _done_0) {
  if (_todo_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $f_graph_fresh_hashed$(_rest_0, _done_0, _d_0, ($index_hash$(($dn$(_d_0)), 2166136261)));
  }
}

function $f_error_defs$(_ds_0) {
  return $nm$(run_loop($fpe_defs$(_ds_0)));
}

function $index_join$(_tree_0, _d_0, _hash_0, _mask_0) {
  const _x_0 = ((_hash_0 & _mask_0) >>> 0);
  return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return $index_node$(($da$(_tree_0)), _mask_0, ($index_leaf$(_d_0, _hash_0, {$: "Nil"})), _tree_0);
}), run_clo((_x_2) => {
  return $index_node$(($da$(_tree_0)), _mask_0, _tree_0, ($index_leaf$(_d_0, _hash_0, {$: "Nil"})));
}));
}

function $index_node$(_hash_0, _mask_0, _left_0, _right_0) {
  return {$: "KDef", "name": "", "kind": "IndexNode", "arity": _hash_0, "templates": _mask_0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Con", "head": _left_0, "tail": {$: "Con", "head": _right_0, "tail": {$: "Nil"}}}, "native": true, "unsafe": false};
}

function $fs_path$(_seed_0) {
  const _path_0 = _seed_0["path"];
  return _path_0;
}

function $fs_inject$(_g_0, _seed_0) {
  const _book_0 = _g_0["book"];
  const _err_0 = _g_0["error"];
  const _done_0 = _g_0["done"];
  return {$: "FGraph", "book": ($norm_defs_join$(_book_0, ($fs_book$(_seed_0)))), "error": _err_0, "done": {$: "Con", "head": ($kt$("Loaded", ($fs_path$(_seed_0)), ($f_graph_count_defs$(($fs_book$(_seed_0)), 0)), 0, {$: "Con", "head": ($ref$("")), "tail": {$: "Nil"}})), "tail": _done_0}};
}

function $fs_parsed$(_s_0, _ns_0, _sources_0, _g_0, _stack_0, _r_0, _seed_0) {
  const _book_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _imports_0 = _r_0["imports"];
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $fs_imports$(_s_0, _ns_0, _book_0, _imports_0, _imports_0, _sources_0, _g_0, _stack_0, _seed_0);
}), run_clo((_x_1) => {
  return $f_graph_error$(_g_0, _err_0);
}));
}

function $dg_suffix_finish$(_done_0, _seen_0, _original_0, _origins_0, _error_0) {
  return $kc$(($String$eq$(_error_0, "")), run_clo((_x_0) => {
  return {$: "DResult", "error": "", "book": _original_0, "diagnostic": ($dg_no_report$("", ""))};
}), run_clo((_x_1) => {
  return $dg_finish$(_error_0, _done_0, ($dg_no_report$("", _error_0)), _origins_0);
}));
}

function $check_open$(_book_0) {
  return $check_open_message$(($count_open$(_book_0)));
}

function $dg_suffix_guard$(_rest_0, _done_0, _d_0, _seen_0, _original_0, _origins_0, _guard_0) {
  return $kc$(($String$eq$(_guard_0, "")), run_clo((_x_0) => {
  return $dg_suffix_check$(_rest_0, _done_0, _d_0, _seen_0, _original_0, _origins_0, run_loop($check_definition_result$(_done_0, run_loop($signature_mode$(_d_0, _rest_0)))));
}), run_clo((_x_1) => {
  const _x_2 = ($dn$(_d_0));
  const _x_3 = (": " + _guard_0);
  return $dg_finish$((_x_2 + _x_3), _done_0, ($dg_no_report$(($dn$(_d_0)), _guard_0)), _origins_0);
}));
}

function $event_error$(_done_0, _d_0, _old_0) {
  return $kc$(($String$eq$(($dk$(_old_0)), "Absent")), run_clo((_x_0) => {
  return $kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_1) => {
  return $constructor_names$(_done_0, ($dc$(_d_0)), {$: "Nil"});
}), run_clo((_x_2) => {
  return "";
}));
}), run_clo((_x_3) => {
  return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_old_0)), "Def")), ($String$eq$(($dk$(_d_0)), "Def")))), ($String$eq$(($tg$(($dv$(_old_0)))), "Absent")))), ($Bool$not$(($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))))), run_clo((_x_4) => {
  const _x_5 = ($dx$(_old_0));
  const _x_6 = ($dx$(_d_0));
  return $kc$(($Bool$and$(run_loop($compare$(_done_0, ($dt$(_old_0)), ($dt$(_d_0)), false)), (_x_5 === _x_6))), run_clo((_x_7) => {
  return "";
}), run_clo((_x_8) => {
  return "definition does not match prior law signature";
}));
}), run_clo((_x_9) => {
  return "duplicate declaration";
}));
}));
}

function $dg_expr$(_book_0, _expr_0, _env_0) {
  if (_expr_0.$ === "DText") {
    const _text_0 = _expr_0["text"];
    return _text_0;
  } else {
    const _term_0 = _expr_0["term"];
    return $kp_go$(run_loop($strong$(_book_0, _term_0)), 0, _env_0);
  }
}

function $dg_scope$($0, $1) {
  for (;;) {
    {
      const _ctx_0 = $0;
      const _env_0 = $1;
      if (_ctx_0.$ === "Nil") {
        return _env_0;
      } else {
        const _h_0 = _ctx_0["head"];
        const _rest_0 = _ctx_0["tail"];
        $0 = _rest_0;
        $1 = ($kp_bind$(_env_0, _h_0));
        continue;
      }
    }
  }
}

function $dg_context$(_book_0, _ctx_0, _env_0, _width_0) {
  if (_ctx_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ctx_0["head"];
    const _rest_0 = _ctx_0["tail"];
    const _x_0 = run_loop($dg_expr$(_book_0, {$: "DTerm", "term": run_loop($kid$(_h_0, 0))}, _env_0));
    const _x_1 = ($dg_context$(_book_0, _rest_0, ($kp_bind$(_env_0, _h_0)), _width_0));
    const _x_2 = (_x_0 + _x_1);
    const _x_3 = ($dg_rpad$(($nm$(_h_0)), _width_0));
    const _x_4 = (" : " + _x_2);
    const _x_5 = (_x_3 + _x_4);
    return ("\n- " + _x_5);
  }
}

function $dg_context_width$(_ctx_0) {
  if (_ctx_0.$ === "Nil") {
    return 0;
  } else {
    const _h_0 = _ctx_0["head"];
    const _rest_0 = _ctx_0["tail"];
    return $norm_max$(($dg_width$(($nm$(_h_0)))), run_loop($dg_context_width$(_rest_0)));
  }
}

function $dg_location$(_name_0, _span_0) {
  return $dg_location_text$(_name_0, run_loop($dg_snippet$(_span_0)));
}

function $norm_exact$(_a_0, _b_0) {
  return $norm_exact_lists$({$: "Con", "head": _a_0, "tail": {$: "Nil"}}, {$: "Con", "head": _b_0, "tail": {$: "Nil"}});
}

function $dg_span_same$(_a_0, _b_0) {
  if (_a_0.$ === "DNoSpan") {
    return false;
  } else {
    const _s_0 = _a_0["source"];
    const _b0_0 = _a_0["begin"];
    const _e0_0 = _a_0["end"];
    return $dg_span_fields$(_s_0, _b0_0, _e0_0, _b_0);
  }
}

function $fp_loaded_module$(_book_0, _source_0, _all_0, _definition_0) {
  return $f_choose$(run_loop($f_choose$(_all_0, run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $fp_loaded_has$(_book_0, _definition_0);
}))), run_clo((_x_2) => {
  return $fp_loaded_defs$(_book_0, {$: "FPSource", "source": ($f_source_text$(_source_0)), "tokens": run_loop($f_lex$(($f_source_text$(_source_0)), 1, 0, 0, {$: "Nil"}))}, _all_0, _definition_0);
}), run_clo((_x_3) => {
  return {$: "Nil"};
}));
}

function $fp_loaded_take$(_book_0, _count_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _head_0 = _book_0["head"];
    const _tail_0 = _book_0["tail"];
    return $f_choose$((_count_0 === 0), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return {$: "Con", "head": _head_0, "tail": run_loop($fp_loaded_take$(_tail_0, ((_count_0 - 1) >>> 0)))};
}));
  }
}

function $fp_loaded_drop$(_book_0, _count_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _head_0 = _book_0["head"];
    const _tail_0 = _book_0["tail"];
    return $f_choose$((_count_0 === 0), run_clo((_x_0) => {
  return {$: "Con", "head": _head_0, "tail": _tail_0};
}), run_clo((_x_1) => {
  return $fp_loaded_drop$(_tail_0, ((_count_0 - 1) >>> 0));
}));
  }
}

function $j_printable_adt$(_book_0, _ty_0, _seen_0, _fuel_0) {
  const _x_0 = ($nm$(_ty_0));
  const _x_1 = (_x_0 + "|");
  const _x_2 = ($String$contains$("|U32|F32|Nat|Char|String|", ("|" + _x_1)));
  const _x_3 = run_loop($has_name$(_seen_0, run_loop($kp_show$(_ty_0))));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return true;
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($nm$(_ty_0)), "Array")), run_clo((_x_6) => {
  return $j_printable$(_book_0, run_loop($kid$(_ty_0, 0)), _seen_0, _fuel_0);
}), run_clo((_x_7) => {
  return $j_printable_ctors$(_book_0, ($dc$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), ($ks$(_ty_0)), {$: "Con", "head": run_loop($kp_show$(_ty_0)), "tail": _seen_0}, _fuel_0);
}));
}));
}

function $j_layout_kind$(_book_0, _env_0, _t_0, _ty_0, _todo_0, _key_0) {
  return $kc$(($String$eq$(_key_0, "Ann")), run_clo((_x_0) => {
  return $j_layout_term$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)), _todo_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(_key_0, "Ref")), run_clo((_x_2) => {
  return $j_layout_mark$(($j_layout_array_intrinsic$(_book_0, _t_0)), {$: "Con", "head": ($nm$(_t_0)), "tail": _todo_0});
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(_key_0, "App")), run_clo((_x_4) => {
  return $j_layout_app$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_t_0, 0)))))), _todo_0);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(_key_0, "Lam")), run_clo((_x_6) => {
  return $j_layout_lam$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)), _todo_0);
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(_key_0, "Mat")), run_clo((_x_8) => {
  return $j_layout_match$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)), _todo_0);
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(_key_0, "Ctr")), run_clo((_x_10) => {
  return $kc$(($Bool$not$(($String$eq$(run_loop($j_literal_typed$(_book_0, _t_0, _ty_0)), "")))), run_clo((_x_11) => {
  return _todo_0;
}), run_clo((_x_12) => {
  return $j_layout_mark$(run_loop($j_layout_open$(_book_0, _ty_0)), ($j_layout_fields$(_book_0, _env_0, ($ks$(_t_0)), ($j_specialize$(_book_0, ($dt$(run_loop($j_find_ctor$(_book_0, ($nm$(_t_0)))))), ($ks$(run_loop($wnf$(_book_0, _ty_0)))))), _todo_0)));
}));
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(_key_0, "Let")), run_clo((_x_14) => {
  return $j_layout_let$(_book_0, _env_0, ($ks$(_t_0)), _ty_0, _todo_0);
}), run_clo((_x_15) => {
  return $kc$(($String$eq$(_key_0, "Rwt")), run_clo((_x_16) => {
  return $j_layout_term$(_book_0, _env_0, run_loop($kid$(_t_0, 2)), _ty_0, _todo_0);
}), run_clo((_x_17) => {
  return _todo_0;
}));
}));
}));
}));
}));
}));
}));
}));
}

function $kr_refs$($0, $1) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _t_0 = $0;
      const _todo_0 = $1;
      const _x_0 = ($String$eq$(($tg$(_t_0)), "Ref"));
      const _x_1 = ($String$eq$(($tg$(_t_0)), "ADT"));
      const _x_2 = (_x_0 || _x_1);
      const _x_3 = ($String$eq$(($tg$(_t_0)), "Ctr"));
      const _x_4 = (_x_2 || _x_3);
      const _x_5 = ($String$eq$(($tg$(_t_0)), "Mat"));
      $0 = ($ks$(_t_0));
      $1 = run_loop($kc$((_x_4 || _x_5), run_clo((_x_6) => {
  return $kr_push$(($nm$(_t_0)), _todo_0);
}), run_clo((_x_7) => {
  return _todo_0;
})));
      $pc = 1; continue;
    }
    case 1: {
      const _terms_0 = $0;
      const _todo_0 = $1;
      if (_terms_0.$ === "Nil") {
        return _todo_0;
      } else {
        const _h_0 = _terms_0["head"];
        const _rest_0 = _terms_0["tail"];
        $0 = _h_0;
        $1 = ($kr_refs_list$(_rest_0, _todo_0));
        $pc = 0; continue;
      }
    }
  }
}

function $kr_ctor_refs$(_ctors_0, _todo_0) {
  if (_ctors_0.$ === "Nil") {
    return _todo_0;
  } else {
    const _d_0 = _ctors_0["head"];
    const _rest_0 = _ctors_0["tail"];
    return $kr_refs$(($dt$(_d_0)), ($kr_ctor_refs$(_rest_0, _todo_0)));
  }
}

function $kr_parent$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return $missing$();
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($Bool$and$(($String$eq$(($dk$(_d_0)), "ADT")), ($Bool$not$(($String$eq$(($dk$(run_loop($lookup$(($dc$(_d_0)), _name_0)))), "Absent")))))), run_clo((_x_0) => {
  return _d_0;
}), run_clo((_x_1) => {
  return $kr_parent$(_rest_0, _name_0);
}));
  }
}

function $kf_known$(_book_0, _prefix_0, _name_0) {
  const _x_0 = ($String$eq$(_name_0, "EXIT"));
  const _x_1 = ($String$eq$(_name_0, "ENTER"));
  const _x_2 = ($Bool$not$(($String$eq$(($dk$(run_loop($kr_resolve$(_book_0, _name_0)))), "Absent"))));
  const _x_3 = ($Bool$and$(($String$eq$(_prefix_0, "FID")), (_x_0 || _x_1)));
  return (_x_2 || _x_3);
}

function $j_field_keys$(_ty_0, _skip_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  return $kc$((_skip_0 === 0), run_clo((_x_1) => {
  const _x_2 = run_loop($j_field_keys$(run_loop($kid$(_ty_0, 1)), 0));
  const _x_3 = ($j_quote$(($nm$(_ty_0))));
  const _x_4 = ("," + _x_2);
  return (_x_3 + _x_4);
}), run_clo((_x_5) => {
  return $j_field_keys$(run_loop($kid$(_ty_0, 1)), ((_skip_0 - 1) >>> 0));
}));
}), run_clo((_x_6) => {
  return "";
}));
}

function $j_schema_params$(_book_0, _ty_0, _left_0, _index_0) {
  return $kc$((_left_0 === 0), run_clo((_x_0) => {
  const _x_1 = run_loop($j_schema_fields$(_book_0, _ty_0));
  const _x_2 = (_x_1 + "];");
  return ("return [" + _x_2);
}), run_clo((_x_3) => {
  const _x_4 = run_loop($j_schema_params$(_book_0, run_loop($kid$(_ty_0, 1)), ((_left_0 - 1) >>> 0), ((_index_0 + 1) >>> 0)));
  const _x_5 = ($U32$show$(_index_0));
  const _x_6 = ("];" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  const _x_8 = ($j_local$(($ix$(_ty_0))));
  const _x_9 = ("=p[" + _x_7);
  const _x_10 = (_x_8 + _x_9);
  return ("const " + _x_10);
}));
}

function $j_foreign_def$(_book_0, _d_0) {
  const _x_4 = run_loop($j_descriptor$(_book_0, run_loop($j_io_result$(_book_0, run_loop($j_foreign_return$(_book_0, ($dt$(_d_0)), ($da$(_d_0)))))), 64));
  const _x_5 = (_x_4 + ")};});\n");
  const _x_6 = run_loop($j_foreign_args$(_book_0, ($dt$(_d_0)), ($da$(_d_0))));
  const _x_7 = ("]," + _x_5);
  const _x_8 = (_x_6 + _x_7);
  const _x_9 = ($j_quote$(($dn$(_d_0))));
  const _x_10 = (",a,[" + _x_8);
  const _x_11 = (_x_9 + _x_10);
  const _x_12 = ($j_quote$(run_loop($j_foreign_path$(($ks$(($dv$(_d_0))))))));
  const _x_13 = ("," + _x_11);
  const _x_14 = (_x_12 + _x_13);
  const _x_15 = ($U32$show$(($da$(_d_0))));
  const _x_16 = (",function(a){const v=scope(null);return {io:()=>foreignCall(" + _x_14);
  const _x_17 = (_x_15 + _x_16);
  const _x_18 = ($j_quote$(($dn$(_d_0))));
  const _x_19 = ("]=fn(" + _x_17);
  const _x_20 = (_x_18 + _x_19);
  const _x_21 = run_loop($kc$(($j_builtin_effect$(($dn$(_d_0)))), run_clo((_x_0) => {
  const _x_1 = ($j_quote$(($dn$(_d_0))));
  const _x_2 = (_x_1 + "))");
  return ("if(!Object.hasOwn(G," + _x_2);
}), run_clo((_x_3) => {
  return "";
})));
  const _x_22 = ("G[" + _x_20);
  return (_x_21 + _x_22);
}

function $j_l_def$(_book_0, _d_0) {
  return $kc$(run_loop($j_l_deep$(($dv$(_d_0)), 0)), run_clo((_x_0) => {
  return $j_l_definition$(_book_0, _d_0, run_loop($j_l_mark$(($dv$(_d_0)), "r", 0)));
}), run_clo((_x_1) => {
  return $j_l_global$(_book_0, _d_0, ($dv$(_d_0)));
}));
}

function $fpe_message$(_source_0, _error_0, _observed_0) {
  const _x_0 = run_loop($fpe_snippet$(($String$lines$(_source_0)), ($ix$(_error_0))));
  const _x_1 = ("\nLocation:" + _x_0);
  const _x_2 = (_observed_0 + _x_1);
  const _x_3 = ($nm$(run_loop($kid$(_error_0, 0))));
  const _x_4 = ("\n- observed : " + _x_2);
  const _x_5 = (_x_3 + _x_4);
  return ("Error:\n- expected : " + _x_5);
}

function $f_import$(_ts_0, _book_0, _imports_0) {
  return $f_import_path$(_ts_0, "", _book_0, _imports_0);
}

function $f_valid_name$(_s_0) {
  const _x_0 = ($f_ascii_alpha$(($f_head$(_s_0))));
  const _x_1 = ($Char$is_eq$(($f_head$(_s_0)), "_"));
  return $Bool$and$(($Bool$and$((_x_0 || _x_1), run_loop($f_name_chars$(_s_0)))), ($Bool$not$(($f_reserved$(_s_0)))));
}

function $f_find$(_name_0, _book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "KDef", "name": _name_0, "kind": "Missing", "arity": 0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": false, "unsafe": false};
  } else {
    const _d_0 = _book_0["head"];
    const _ds_0 = _book_0["tail"];
    return $f_choose$(($f_eq$(_name_0, ($dn$(_d_0)))), run_clo((_x_0) => {
  return _d_0;
}), run_clo((_x_1) => {
  return $f_find$(_name_0, _ds_0);
}));
  }
}

function $f_law_base$(_name_0, _ts_0, _book_0, _imports_0, _clauses_0) {
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), "for"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), "exs"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_law_clause$(_name_0, ($f_eq$(($f_tx$(_ts_0)), "exs")), ($f_tl$(_ts_0)), _book_0, _imports_0, _clauses_0);
}), run_clo((_x_3) => {
  return $f_law_end$(_name_0, run_loop($f_expr$(_ts_0, 0)), _book_0, _imports_0, ($List$reverse$(_clauses_0)));
}));
}

function $f_def$(_name_0, _p_0, _book_0, _imports_0, _unsafe_0) {
  return $f_choose$(($Bool$not$(($f_valid_name$(_name_0)))), run_clo((_x_0) => {
  return $f_result$(_book_0, ($kt$("Error", ("reserved definition name: " + _name_0), 0, 0, {$: "Nil"})), _imports_0);
}), run_clo((_x_1) => {
  return $f_def_prior$(_name_0, _p_0, _book_0, _imports_0, _unsafe_0, run_loop($f_find$(_name_0, _book_0)));
}));
}

function $f_tele$(_ts0_0, _end_0, _acc_0) {
  return $f_tele_at$(run_loop($f_skip$(_ts0_0)), _end_0, _acc_0);
}

function $f_type_named$(_name_0, _ts_0, _book_0, _imports_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "<>")), run_clo((_x_0) => {
  return $f_type_params$(_name_0, {$: "FParsed", "term": ($kt$("Tele", "", 0, 0, {$: "Nil"})), "rest": ($f_tl$(_ts_0))}, _book_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_type_base$(_name_0, _ts_0, _book_0, _imports_0);
}));
}

function $fpe_legacy$(_ts_0, _legacy_0, _expected_0) {
  return {$: "FParsed", "term": ($kt$("Error", _legacy_0, ($f_line$(_ts_0)), ($f_col$(_ts_0)), {$: "Con", "head": ($kt$("ParseExpected", _expected_0, 0, 0, {$: "Nil"})), "tail": {$: "Con", "head": ($kt$("ParseToken", ($f_tx$(_ts_0)), 0, 0, {$: "Nil"})), "tail": {$: "Nil"}}})), "rest": {$: "Nil"}};
}

function $ffd_walk$($0, $1, $2, $3, $4, $5) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      if (_book_0.$ === "Nil") {
        $0 = ($List$reverse$(_built_0));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 1; continue;
      } else {
        const _definition_0 = _book_0["head"];
        const _pending_0 = _book_0["tail"];
        $0 = _definition_0;
        $1 = _pending_0;
        $2 = _built_0;
        $3 = _stack_0;
        $4 = run_loop($f_fresh_term$(($dt$(_definition_0)), {$: "Nil"}, _next_0));
        $pc = 3; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFreshDefs", "defs": _book_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _book_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 2; continue;
      }
    }
    case 2: {
      const _frame_0 = $0;
      const _ctors_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      const _definition_0 = _frame_0["definition"];
      const _pending_0 = _frame_0["pending"];
      const _built_0 = _frame_0["built"];
      const _typ_0 = _frame_0["typ"];
      const _value_0 = _frame_0["value"];
      $0 = _pending_0;
      $1 = _next_0;
      $2 = {$: "Con", "head": {$: "KDef", "name": ($dn$(_definition_0)), "kind": ($dk$(_definition_0)), "arity": ($da$(_definition_0)), "templates": ($dx$(_definition_0)), "typ": _typ_0, "value": _value_0, "ctors": _ctors_0, "native": ($db$(_definition_0)), "unsafe": ($du$(_definition_0))}, "tail": _built_0};
      $3 = _stack_0;
      $pc = 0; continue;
    }
    case 3: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _result_0 = $4;
      const _typ_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = _definition_0;
      $1 = _pending_0;
      $2 = _built_0;
      $3 = _stack_0;
      $4 = _typ_0;
      $5 = run_loop($f_fresh_term$(($dv$(_definition_0)), {$: "Nil"}, _next_0));
      $pc = 4; continue;
    }
    case 4: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _typ_0 = $4;
      const _result_0 = $5;
      const _value_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = ($dc$(_definition_0));
      $1 = _next_0;
      $2 = {$: "Nil"};
      $3 = {$: "Con", "head": {$: "FFDefFrame", "definition": _definition_0, "pending": _pending_0, "built": _built_0, "typ": _typ_0, "value": _value_0}, "tail": _stack_0};
      $pc = 0; continue;
    }
  }
}

function $f_load_import_next$(_imports_0, _sources_0, _stack_0, _book_0, _r_0) {
  const _defs_0 = _r_0["book"];
  const _err_0 = _r_0["error"];
  const _seen_0 = _r_0["seen"];
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $f_load_imports$(_imports_0, _sources_0, _seen_0, _stack_0, ($norm_defs_join$(_defs_0, _book_0)));
}), run_clo((_x_1) => {
  return {$: "FLoaded", "book": _book_0, "error": _err_0, "seen": _seen_0};
}));
}

function $f_path_term$(_t_0, _dir_0) {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": run_loop($f_choose$(($f_eq$(($tg$(_t_0)), "Path")), run_clo((_x_0) => {
  return $f_path_join$(_dir_0, ($nm$(_t_0)));
}), run_clo((_x_1) => {
  return $nm$(_t_0);
}))), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($f_path_terms$(($ks$(_t_0)), _dir_0)), "removed": ($rm$(_t_0))};
}

function $f_qual_optional$(_defs_0, _book_0, _ns_0, _imports_0) {
  return $f_choose$(($String$is_empty$(_ns_0)), run_clo((_x_0) => {
  return _defs_0;
}), run_clo((_x_1) => {
  return $f_qual_defs$(_defs_0, _book_0, _ns_0, _imports_0);
}));
}

function $f_elab_defs$(_ds_0, _book_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return {$: "Con", "head": ($f_elab_def$(_d_0, _book_0)), "tail": ($f_elab_defs$(_rest_0, _book_0))};
  }
}

function $f_family_book$(_book_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_0 = ($dx$(_d_0));
    const _x_1 = ($f_eq$(($dk$(_d_0)), "ADT"));
    const _x_2 = (_x_0 > 0);
    return $f_choose$((_x_1 || _x_2), run_clo((_x_3) => {
  return {$: "Con", "head": _d_0, "tail": run_loop($f_family_book$(_rest_0))};
}), run_clo((_x_4) => {
  return $f_family_book$(_rest_0);
}));
  }
}

function $core_nat_type$(_book_0, _ty_0) {
  return $Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "ADT")), ($String$eq$(($nm$(_ty_0)), "Nat")))), ($List$is_empty$(($rm$(_ty_0)))))), ($db$(run_loop($lookup$(_book_0, "Nat")))));
}

function $core_nat_step$(_t_0) {
  const _x_0 = ($qt$(_t_0));
  return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return $kt$("Ctr", "Zero", 0, 1, {$: "Nil"});
}), run_clo((_x_2) => {
  const _x_3 = ($qt$(_t_0));
  return $kt$("Ctr", "Succ", 0, 1, {$: "Con", "head": ($core_nat_make$(((_x_3 - 1) >>> 0))), "tail": {$: "Nil"}});
}));
}

function $ka_lam$(_e_0, _ctx_0, _t_0, _ty_0) {
  const _x_0 = ($qt$(_t_0));
  const _x_1 = ($qt$(_ty_0));
  return $kt$("Lam", ($nm$(_t_0)), ($ix$(_t_0)), run_loop($kc$(($Bool$and$((_x_0 === 2), (_x_1 === 1))), run_clo((_x_2) => {
  return 2;
}), run_clo((_x_3) => {
  return $qt$(_ty_0);
}))), {$: "Con", "head": ($annotate$(_e_0, ($ctx_bind$(_ctx_0, ($ix$(_t_0)), ($qt$(_ty_0)), ($nm$(_t_0)), run_loop($kid$(_ty_0, 0)))), run_loop($kid$(_t_0, 0)), run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))))), "tail": {$: "Nil"}});
}

function $ka_spine_eligible$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $ka_spine_eligible$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  const _x_2 = ($String$eq$(($tg$(_t_0)), "Ref"));
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Var"));
  return (_x_2 || _x_3);
}));
}

function $ka_app_spine$(_e_0, _ctx_0, _t_0) {
  return $ka_app_spine_finish$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), run_loop($ka_spine$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)))));
}

function $ka_app$(_e_0, _ctx_0, _t_0, _fty_0) {
  return $app$(($annotate$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), _fty_0)), ($annotate$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), run_loop($kid$(_fty_0, 0)))));
}

function $ka_type$(_e_0, _ctx_0, _t_0) {
  return $ka_type_node$(_e_0, _ctx_0, run_loop($core_beta$(_t_0)));
}

function $ka_args_cached$(_e_0, _ctx_0, _tel_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $ka_args_cached_head$(_e_0, _ctx_0, run_loop($wnf$(($cb$(_e_0)), _tel_0)), _h_0, _rest_0);
  }
}

function $tele_fill$(_book_0, _tel_0, _args_0) {
  if (_args_0.$ === "Nil") {
    return _tel_0;
  } else {
    const _h_0 = _args_0["head"];
    const _t_0 = _args_0["tail"];
    return $tele_fill_head$(_book_0, run_loop($wnf$(_book_0, _tel_0)), _h_0, _t_0);
  }
}

function $ka_mat$(_e_0, _ctx_0, _t_0, _ty_0, _a_0) {
  return $ka_mat_ctr$(_e_0, _ctx_0, _t_0, _ty_0, _a_0, run_loop($lookup$(($dc$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_a_0)))))), ($nm$(_t_0)))));
}

function $ka_let$(_e_0, _outer_0, _ctx_0, _xs_0, _ty_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $kc$(($String$eq$(($tg$(_h_0)), "Bind")), run_clo((_x_0) => {
  return $ka_let_head$(_e_0, _outer_0, _ctx_0, _h_0, _rest_0, _ty_0, run_loop($ka_type$(_e_0, _outer_0, run_loop($kid$(_h_0, 0)))));
}), run_clo((_x_1) => {
  return {$: "Con", "head": ($annotate$(_e_0, _ctx_0, _h_0, _ty_0)), "tail": {$: "Nil"}};
}));
  }
}

function $ka_rwt$(_e_0, _ctx_0, _t_0, _eq_0) {
  return $kt$("Rwt", ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), {$: "Con", "head": ($annotate$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), _eq_0)), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Con", "head": ($annotate$(_e_0, _ctx_0, run_loop($kid$(_t_0, 2)), run_loop($kapply$(run_loop($kapply$(run_loop($kid$(_t_0, 1)), run_loop($kid$(_eq_0, 0)))), ($atom$("Rfl")))))), "tail": {$: "Nil"}}}});
}

function $core_apply$(_f_0, _x_0) {
  return $kc$(($String$eq$(($tg$(_f_0)), "Lam")), run_clo((_x_1) => {
  return $subst$(run_loop($kid$(_f_0, 0)), ($ix$(_f_0)), _x_0);
}), run_clo((_x_2) => {
  return $app$(_f_0, _x_0);
}));
}

function $Char$from_u32$(_x_0) {
  return char_new(_x_0);
}

function $j_choice_definition$(_book_0, _d_0) {
  const _x_0 = ($qt$(($dt$(_d_0))));
  return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($db$(run_loop($lookup$(_book_0, "Bool")))), ($db$(run_loop($lookup$(_book_0, "Unit")))))), ($String$eq$(($tg$(($dt$(_d_0)))), "All")))), (_x_0 === 0))), ($String$eq$(($tg$(run_loop($j_strip$(($dv$(_d_0)))))), "Lam")))), run_clo((_x_1) => {
  return $j_choice_match$(run_loop($j_strip$(run_loop($kid$(run_loop($j_strip$(($dv$(_d_0)))), 0)))));
}), run_clo((_x_2) => {
  return false;
}));
}

function $j_choice_after_type$(_book_0, _env_0, _args_0, _tail_0, _ty_0) {
  return $j_choice_after_bool$(_book_0, _env_0, _args_0, _tail_0, run_loop($j_expr$(_book_0, _env_0, run_loop($terms_at$(_args_0, 1)), run_loop($kid$(_ty_0, 0)), false)), run_loop($wnf$(_book_0, run_loop($j_app_type$(_ty_0, run_loop($terms_at$(_args_0, 1)))))));
}

function $j_call_arity$(_d_0) {
  return $kc$(($Bool$and$(($db$(_d_0)), ($j_intrinsic$(($dn$(_d_0)))))), run_clo((_x_0) => {
  return $da$(_d_0);
}), run_clo((_x_1) => {
  return $j_lambda_count$(($dv$(_d_0)));
}));
}

function $j_apply_args$(_book_0, _env_0, _args_0, _ty_0) {
  return $j_apply_args_head$(_book_0, _env_0, _args_0, run_loop($wnf$(_book_0, _ty_0)));
}

function $j_apply_one$(_book_0, _env_0, _t_0, _tail_0, _fty_0) {
  const _x_2 = ($qt$(_fty_0));
  const _x_5 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_fty_0)), "All")), (_x_2 === 0))), run_clo((_x_3) => {
  return "null";
}), run_clo((_x_4) => {
  return $j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 1)), run_loop($kid$(_fty_0, 0)), false);
})));
  const _x_6 = (_x_5 + "])");
  const _x_7 = run_loop($j_expr$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), _fty_0, false));
  const _x_8 = (",[" + _x_6);
  const _x_9 = run_loop($kc$(_tail_0, run_clo((_x_0) => {
  return "jump(";
}), run_clo((_x_1) => {
  return "call(";
})));
  const _x_10 = (_x_7 + _x_8);
  return (_x_9 + _x_10);
}

function $j_literal_node$(_t_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  const _x_1 = ($U32$show$(($qt$(_t_0))));
  return (_x_1 + "n");
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_3) => {
  return $j_literal_ctor$(_t_0);
}), run_clo((_x_4) => {
  return "";
}));
}));
}

function $j_ctor_args$(_book_0, _env_0, _args_0, _tel_0) {
  if (_args_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    const _x_0 = ($qt$(_tel_0));
    const _x_3 = ($j_ctor_args$(_book_0, _env_0, _rest_0, run_loop($j_app_type$(_tel_0, _h_0))));
    const _x_4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_tel_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return "null";
}), run_clo((_x_2) => {
  return $j_expr$(_book_0, _env_0, _h_0, run_loop($kid$(_tel_0, 0)), false);
})));
    const _x_5 = ("," + _x_3);
    return (_x_4 + _x_5);
  }
}

function $all$(_q_0, _name_0, _id_0, _a_0, _b_0) {
  return $kt$("All", _name_0, _id_0, _q_0, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}

function $U32$show$fin$($0, $1, $2, $3) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _f_0 = $0;
      const _n_0 = $1;
      const _acc_0 = $2;
      if (_f_0 === 0) {
        return _acc_0;
      } else {
        const _g_0 = (_f_0 - 1);
        $0 = _g_0;
        $1 = _acc_0;
        $2 = _n_0;
        $3 = (_n_0 === 0);
        $pc = 1; continue;
      }
    }
    case 1: {
      const _g_0 = $0;
      const _acc_0 = $1;
      const _n_0 = $2;
      const _z_0 = $3;
      if (_z_0) {
        return _acc_0;
      } else {
        const _x_0 = (10 === 0 ? _n_0 : _n_0 % 10);
        $0 = _g_0;
        $1 = (10 === 0 ? 0 : (_n_0 / 10) >>> 0);
        $2 = (char_new(((48 + _x_0) >>> 0)) + _acc_0);
        $pc = 0; continue;
      }
    }
  }
}

function $app$(_f_0, _x_0) {
  return $kt$("App", "", 0, 0, {$: "Con", "head": _f_0, "tail": {$: "Con", "head": _x_0, "tail": {$: "Nil"}}});
}

function $norm_let_tail$(_h_0, _rest_0) {
  if (_rest_0.$ === "Nil") {
    return _h_0;
  } else {
    const _x_0 = _rest_0["head"];
    const _xs_0 = _rest_0["tail"];
    return $subst$(run_loop($norm_let$({$: "Con", "head": _x_0, "tail": _xs_0})), ($ix$(_h_0)), run_loop($kid$(_h_0, 0)));
  }
}

function $norm_min_left$(_book_0, _a_0, _b_0) {
  const _x_0 = ($qt$(_a_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_a_0)), "Qua")), (_x_0 === 2))), run_clo((_x_1) => {
  return $wnf$(_book_0, _b_0);
}), run_clo((_x_2) => {
  const _x_3 = ($qt$(_a_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_a_0)), "Qua")), (_x_3 === 0))), run_clo((_x_4) => {
  return _a_0;
}), run_clo((_x_5) => {
  return $norm_min_right$(_a_0, run_loop($wnf$(_book_0, _b_0)));
}));
}));
}

function $norm_dec$(_n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return 0;
}), run_clo((_x_1) => {
  return ((_n_0 - 1) >>> 0);
}));
}

function $norm_match$(_book_0, _arm_0, _original_0, _raw_0, _x_0, _args_0, _left_0, _fallback_0) {
  return $kc$(run_loop($core_nat$(_x_0)), run_clo((_x_1) => {
  return $norm_match$(_book_0, _arm_0, _original_0, _raw_0, run_loop($core_nat_step$(_x_0)), _args_0, _left_0, _fallback_0);
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($tg$(_x_0)), "Ctr")), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_arm_0)), "Ann")), run_clo((_x_4) => {
  return $norm_match$(_book_0, run_loop($kid$(_arm_0, 0)), _original_0, _raw_0, _x_0, _args_0, _left_0, _fallback_0);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_arm_0)), "Mat")), run_clo((_x_6) => {
  return $kc$(($String$eq$(($nm$(_arm_0)), ($nm$(_x_0)))), run_clo((_x_7) => {
  return $kc$((_left_0 === 0), run_clo((_x_8) => {
  return $norm_eval$(_book_0, run_loop($kid$(_arm_0, 0)), ($norm_join$(($ks$(_x_0)), _args_0)), 0, _fallback_0);
}), run_clo((_x_9) => {
  const _x_10 = run_loop($norm_dec$(_left_0));
  const _x_11 = ($terms_len$(($ks$(_x_0))));
  return $norm_eval$(_book_0, run_loop($kid$(_arm_0, 0)), ($norm_join$(($ks$(_x_0)), _args_0)), ((_x_10 + _x_11) >>> 0), _fallback_0);
}));
}), run_clo((_x_12) => {
  return $norm_match$(_book_0, run_loop($kid$(_arm_0, 1)), _original_0, _raw_0, _x_0, _args_0, _left_0, _fallback_0);
}));
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_arm_0)), "Efq")), run_clo((_x_14) => {
  return $norm_stuck$(_original_0, _raw_0, _args_0, _left_0, _fallback_0);
}), run_clo((_x_15) => {
  return $norm_eval$(_book_0, _arm_0, {$: "Con", "head": _x_0, "tail": _args_0}, _left_0, _fallback_0);
}));
}));
}));
}), run_clo((_x_16) => {
  return $norm_stuck$(_original_0, _raw_0, _args_0, _left_0, _fallback_0);
}));
}));
}

function $index_child_list$(_ds_0, _right_0) {
  if (_ds_0.$ === "Nil") {
    return $missing$();
  } else {
    const _h_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return $kc$(_right_0, run_clo((_x_0) => {
  return $index_first$(_rest_0);
}), run_clo((_x_1) => {
  return _h_0;
}));
  }
}

function $Bool$to_u32$(_b_0) {
  if (!_b_0) {
    return 0;
  } else {
    return 1;
  }
}

function $Char$is_upper$(_c_0) {
  const _x_0 = _c_0.codePointAt(0);
  const _x_1 = _c_0.codePointAt(0);
  return $Bool$and$((_x_0 >= 65), (_x_1 <= 90));
}

function $book_final_seen$(_seen_0, _name_0, _hash_0) {
  return $String$eq$(($dk$(run_loop($index_find$(_seen_0, _name_0, _hash_0, 32)))), "$final.seen");
}

function $kp_is$(_t_0, _tag_0, _name_0) {
  return $Bool$and$(($kp_eq$(($tg$(_t_0)), _tag_0)), ($kp_eq$(($nm$(_t_0)), _name_0)));
}

function $kp_exists$(_A_0, _b_0, _p_0, _env_0) {
  const _x_0 = run_loop($kp_go$(run_loop($kid$(_b_0, 0)), 2, ($kp_bind$(_env_0, _b_0))));
  const _x_1 = run_loop($kp_go$(_A_0, 3, _env_0));
  const _x_2 = (" -> " + _x_0);
  const _x_3 = (_x_1 + _x_2);
  const _x_4 = ($nm$(_b_0));
  const _x_5 = (":" + _x_3);
  const _x_6 = (_x_4 + _x_5);
  return $kp_par$(("&" + _x_6), (_p_0 > 2));
}

function $kp_join$(_xs_0, _sep_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return _h_0;
    } else {
      const _x_0 = ($kp_join$(_t_0, _sep_0));
      const _x_1 = (_sep_0 + _x_0);
      return (_h_0 + _x_1);
    }
  }
}

function $kp_each$(_ts_0, _p_0, _env_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _t_0 = _ts_0["tail"];
    return {$: "Con", "head": run_loop($kp_go$(_h_0, _p_0, _env_0)), "tail": ($kp_each$(_t_0, _p_0, _env_0))};
  }
}

function $kp_has_removed$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return false;
  } else {
    return true;
  }
}

function $kp_removed$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    const _x_0 = ($kp_removed$(_t_0));
    const _x_1 = ("{}" + _x_0);
    const _x_2 = (_h_0 + _x_1);
    return (" - " + _x_2);
  }
}

function $kp_ctor_number$(_n_0, _t_0, _p_0, _env_0) {
  if (_n_0.$ === "Some") {
    const _x_0 = _n_0["value"];
    return $kc$(($kp_eq$(($nm$(_t_0)), "F32")), run_clo((_x_1) => {
  return $kp_float_show$(_x_0);
}), run_clo((_x_2) => {
  return $U32$show$(_x_0);
}));
  } else {
    return $kp_ctor_other$(_t_0, _p_0, _env_0);
  }
}

function $kp_number$(_t_0) {
  const _x_0 = ($kp_is$(_t_0, "Ctr", "U32"));
  const _x_1 = ($kp_is$(_t_0, "Ctr", "F32"));
  const _x_2 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$((_x_0 || _x_1), (_x_2 === 1))), run_clo((_x_3) => {
  return $kp_word$(run_loop($kid$(_t_0, 0)), 1, 32, 0);
}), run_clo((_x_4) => {
  return {$: "None"};
}));
}

function $kp_rewrite$(_t_0, _p_0, _env_0) {
  const _x_0 = run_loop($kp_go$(run_loop($kid$(_t_0, 2)), 0, _env_0));
  const _x_1 = run_loop($kp_rewrite_motive$(run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)), _env_0));
  const _x_2 = ("; " + _x_0);
  const _x_3 = (_x_1 + _x_2);
  return $kp_par$(("%" + _x_3), (_p_0 > 1));
}

function $kp_let$(_t_0, _p_0, _env_0) {
  const _x_0 = run_loop($kp_let_body$(($ks$(_t_0)), _env_0));
  const _x_1 = run_loop($kp_let_vals$(($ks$(_t_0)), _env_0));
  const _x_2 = ("; " + _x_0);
  const _x_3 = (_x_1 + _x_2);
  const _x_4 = run_loop($kp_let_names$(($ks$(_t_0))));
  const _x_5 = (" = " + _x_3);
  return $kp_par$((_x_4 + _x_5), (_p_0 > 0));
}

function $g_snf_head$(_book_0, _stack_0, _fresh_0, _r_0) {
  const _x_0 = ($String$eq$(($tg$(($g_term$(_r_0)))), "Lam"));
  const _x_1 = ($String$eq$(($tg$(($g_term$(_r_0)))), "All"));
  return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return $g_snf_open$(_book_0, ($g_state$(_r_0)), ($norm_rebind$(($g_term$(_r_0)), _fresh_0)), _stack_0, ((_fresh_0 + 1) >>> 0));
}), run_clo((_x_3) => {
  return $g_snf_open$(_book_0, ($g_state$(_r_0)), ($g_term$(_r_0)), _stack_0, _fresh_0);
}));
}

function $g_wnf$(_book_0, _st_0, _t_0) {
  return $g_eval$(_book_0, _st_0, _t_0, {$: "Nil"}, 0, ($atom$("Absent")), {$: "Nil"});
}

function $norm_join$(_a_0, _b_0) {
  if (_a_0.$ === "Nil") {
    return _b_0;
  } else {
    const _h_0 = _a_0["head"];
    const _t_0 = _a_0["tail"];
    return {$: "Con", "head": _h_0, "tail": ($norm_join$(_t_0, _b_0))};
  }
}

function $sp_head$(_st_0, _head_0, _xs_0, _ctx_0, _owner_0, _depth_0, _d_0) {
  const _x_0 = ($dx$(_d_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(run_loop($strip$(_head_0)))), "Ref")), (_x_0 > 0))), run_clo((_x_1) => {
  return $sp_template$(_st_0, _d_0, _xs_0, _ctx_0, _owner_0, _depth_0);
}), run_clo((_x_2) => {
  return $sp_regular_head$(_st_0, _head_0, _xs_0, _ctx_0, _owner_0, _depth_0);
}));
}

function $strip$(_t_0) {
  return $core_force$(_t_0);
}

function $sp_single$(_t_0, _r_0) {
  return {$: "KSpecTerm", "state": ($sp_state$(_r_0)), "term": {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": {$: "Con", "head": ($sp_value$(_r_0)), "tail": {$: "Nil"}}, "removed": ($rm$(_t_0))}};
}

function $ctx_bind$(_ctx_0, _id_0, _q_0, _name_0, _ty_0) {
  return {$: "Con", "head": ($kt$("Bind", _name_0, _id_0, _q_0, {$: "Con", "head": _ty_0, "tail": {$: "Nil"}})), "tail": _ctx_0};
}

function $sp_match_type$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0, _a_0) {
  return $sp_match_ctor$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0, _a_0, run_loop($lookup$(($dc$(run_loop($lookup$(($sp_book$(_st_0)), ($nm$(_a_0)))))), ($nm$(_t_0)))));
}

function $sp_ctor_done$(_t_0, _r_0) {
  return {$: "KSpecTerm", "state": ($sp_states$(_r_0)), "term": {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($sp_values$(_r_0)), "removed": ($rm$(_t_0))}};
}

function $sp_args$(_st_0, _xs_0, _ctx_0, _ty_0, _owner_0, _depth_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "KSpecTerms", "state": _st_0, "terms": {$: "Nil"}};
  } else {
    const _x_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $sp_arg_head$(_st_0, _x_0, _rest_0, _ctx_0, run_loop($wnf$(($sp_book$(_st_0)), _ty_0)), _owner_0, _depth_0);
  }
}

function $sp_fail$(_st_0, _err_0) {
  return {$: "KSpecState", "book": ($sp_book$(_st_0)), "memo": ($sp_memo$(_st_0)), "serial": ($sp_serial$(_st_0)), "fresh": ($sp_fresh$(_st_0)), "error": run_loop($kc$(($String$eq$(($sp_error$(_st_0)), "")), run_clo((_x_0) => {
  return _err_0;
}), run_clo((_x_1) => {
  return $sp_error$(_st_0);
}))), "templates": ($sp_templates$(_st_0))};
}

function $sp_let_binding$(_st_0, _h_0, _rest_0, _outer_0, _ctx_0, _goal_0, _owner_0, _depth_0, _ty_0) {
  const _x_0 = ($qt$(_h_0));
  return $sp_let_bound$(_h_0, _rest_0, _outer_0, _ctx_0, _goal_0, _owner_0, _depth_0, _ty_0, run_loop($kc$((_x_0 === 0), run_clo((_x_1) => {
  return {$: "KSpecTerm", "state": _st_0, "term": run_loop($kid$(_h_0, 0))};
}), run_clo((_x_2) => {
  return $sp_term$(_st_0, run_loop($kid$(_h_0, 0)), _outer_0, _ty_0, _owner_0, _depth_0);
}))));
}

function $sp_type$(_st_0, _t_0, _ctx_0, _owner_0) {
  return $cy$(run_loop($infer$({$: "KEnv", "book": ($sp_book$(_st_0)), "name": _owner_0, "lhs": ($ref$(_owner_0)), "pending": 0, "quantities": {$: "Nil"}, "unsafe": true}, _ctx_0, _t_0, 0, {$: "Nil"})));
}

function $sp_let_body$(_r_0) {
  return {$: "KSpecTerms", "state": ($sp_state$(_r_0)), "terms": {$: "Con", "head": ($sp_value$(_r_0)), "tail": {$: "Nil"}}};
}

function $sp_rewrite_type$(_st_0, _t_0, _ctx_0, _owner_0, _depth_0, _eq_0) {
  return $sp_rewrite_done$(_t_0, run_loop($sp_term$(_st_0, run_loop($kid$(_t_0, 2)), _ctx_0, ($app$(($app$(run_loop($kid$(_t_0, 1)), run_loop($kid$(_eq_0, 0)))), ($atom$("Rfl")))), _owner_0, _depth_0)));
}

function $nt_count_go$($0, $1) {
  for (;;) {
    {
      const _xs_0 = $0;
      const _n_0 = $1;
      if (_xs_0.$ === "Nil") {
        return _n_0;
      } else {
        const _t_0 = _xs_0["tail"];
        $0 = _t_0;
        $1 = ((_n_0 + 1) >>> 0);
        continue;
      }
    }
  }
}

function $nv_unique_index$(_xs_0, _seen_0) {
  if (_xs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    const _hash_0 = ($index_hash$(_h_0, 2166136261));
    return $nt_choose$(($String$eq$(($dk$(run_loop($index_find$(_seen_0, _h_0, _hash_0, 32)))), "Absent")), run_clo((_x_0) => {
  return $nv_unique_index$(_rest_0, run_loop($index_set$(_seen_0, ($nv_id$(_h_0)), _hash_0, 32)));
}), run_clo((_x_1) => {
  return ("native identifier collision: " + _h_0);
}));
  }
}

function $nv_seg_names_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return $nt_reverse$(_acc_0, {$: "Con", "head": "FID_IO_EMIT", "tail": {$: "Con", "head": "BEND_CLO_APPLY", "tail": {$: "Con", "head": "FID_EXIT", "tail": {$: "Con", "head": "FID_ENTER", "tail": {$: "Nil"}}}}});
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _rest_0 = _ss_0["tail"];
        $0 = _rest_0;
        $1 = {$: "Con", "head": ($nt_fid$(_k_0)), "tail": _acc_0};
        continue;
      }
    }
  }
}

function $nt_replace$(_s_0, _key_0, _value_0) {
  return $nt_replace_go$(_s_0, _key_0, _value_0, "");
}

function $nb_seg_ids$(_ss_0, _i_0) {
  return $nb_seg_ids_go$(_ss_0, _i_0, "");
}

function $nb_ctr_ids$(_cs_0, _i_0) {
  if (_cs_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _cs_0["head"];
    const _k_0 = _t_0["name"];
    const _t_1 = _cs_0["tail"];
    const _x_0 = ($nb_ctr_ids$(_t_1, ((_i_0 + 1) >>> 0)));
    const _x_1 = ($U32$show$(_i_0));
    const _x_2 = ("\n" + _x_0);
    const _x_3 = (_x_1 + _x_2);
    const _x_4 = ($nt_cid$(_k_0));
    const _x_5 = (" " + _x_3);
    const _x_6 = (_x_4 + _x_5);
    return ("#define " + _x_6);
  }
}

function $nb_bank$(_ss_0) {
  const _n_0 = ($nb_width$(_ss_0));
  const _r_0 = ($nb_returns$(_ss_0));
  const _rs_0 = ($nb_regs$(_n_0, 0));
  const _ws_0 = run_loop($nb_pad$(_rs_0, 0));
  const _x_0 = ($nt_join$(_ws_0, ", "));
  const _x_1 = (_x_0 + "\n");
  const _x_2 = ("#define WL_ALL e, sp, seq, rn, " + _x_1);
  const _x_3 = ($nt_join$(($nb_typed$(_ws_0)), ", "));
  const _x_4 = ("\n" + _x_2);
  const _x_5 = (_x_3 + _x_4);
  const _x_6 = ("#define WL_SIG Env e, Stk sp, u32 seq, u32 rn, " + _x_5);
  const _x_7 = ($nb_take$(($nb_regs$(_r_0, 0)), 0));
  const _x_8 = ("\n" + _x_6);
  const _x_9 = (_x_7 + _x_8);
  const _x_10 = ("#define WL_TAKE(V) " + _x_9);
  const _x_11 = ($nb_save$(($nb_regs$(_r_0, 0)), 0));
  const _x_12 = ("\n" + _x_10);
  const _x_13 = (_x_11 + _x_12);
  const _x_14 = ("#define WL_SAVE(V) " + _x_13);
  const _x_15 = ($nb_last$(_rs_0, 0));
  const _x_16 = ("  }\n" + _x_14);
  const _x_17 = (_x_15 + _x_16);
  const _x_18 = ("#define WL_LAST(X) \\\n  switch (war) { \\\n" + _x_17);
  const _x_19 = ($nb_load$(_rs_0, 0));
  const _x_20 = ("  } while (0);\n" + _x_18);
  const _x_21 = (_x_19 + _x_20);
  const _x_22 = ("#define WL_LOAD(A, N) \\\n  do { \\\n" + _x_21);
  const _x_23 = ($nt_join$(_ws_0, ", "));
  const _x_24 = (";\n" + _x_22);
  const _x_25 = (_x_23 + _x_24);
  const _x_26 = ($U32$show$(($nb_bangs$(_ss_0))));
  const _x_27 = ("\n#define WL_BANK Term " + _x_25);
  const _x_28 = (_x_26 + _x_27);
  const _x_29 = ($U32$show$(_r_0));
  const _x_30 = ("\n#define BANGS " + _x_28);
  const _x_31 = (_x_29 + _x_30);
  return ("#define WL_RESW " + _x_31);
}

function $nb_arities$(_ss_0) {
  return $nb_arities_go$(_ss_0, "");
}

function $nb_flags$(_ss_0, _forks_0) {
  return $nb_flags_go$(_ss_0, _forks_0, "");
}

function $nb_fork_close$(_ss_0, _roots_0, _fuel_0) {
  if (_fuel_0 == 0) {
    return _roots_0;
  } else {
    const _15_0 = u32_to_word(_fuel_0)["head"];
    const _16_0 = u32_to_word(_fuel_0)["tail"];
    const _x_0 = word_to_u32({$: "WCon", "head": _15_0, "tail": _16_0});
    return $nb_fork_next$(_ss_0, _roots_0, ($nb_fork_step$(_ss_0, _roots_0)), ((_x_0 - 1) >>> 0));
  }
}

function $nb_fork_roots$(_ss_0) {
  return $nb_fork_roots_go$(_ss_0, {$: "Nil"});
}

function $nb_result_words$(_ss_0) {
  return $nb_result_words_go$(_ss_0, "");
}

function $nb_ctr_arity$(_cs_0) {
  if (_cs_0.$ === "Nil") {
    return "0";
  } else {
    const _t_0 = _cs_0["head"];
    const _a_0 = _t_0["arity"];
    const _t_1 = _cs_0["tail"];
    const _x_0 = ($nb_ctr_arity$(_t_1));
    const _x_1 = ($U32$show$(_a_0));
    const _x_2 = (", " + _x_0);
    return (_x_1 + _x_2);
  }
}

function $nb_ctr_hot$(_cs_0) {
  if (_cs_0.$ === "Nil") {
    return "0";
  } else {
    const _t_0 = _cs_0["head"];
    const _h_0 = _t_0["hot"];
    const _t_1 = _cs_0["tail"];
    const _x_0 = ($nb_ctr_hot$(_t_1));
    const _x_1 = ($U32$show$(($nt_bool$(_h_0))));
    const _x_2 = (", " + _x_0);
    return (_x_1 + _x_2);
  }
}

function $nb_dispatch$(_ss_0) {
  return $nb_dispatch_go$(_ss_0, "");
}

function $ne_segments_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _h_0 = _ss_0["head"];
        const _t_0 = _ss_0["tail"];
        const _x_0 = ($ne_segment$(_h_0));
        const _x_1 = (_x_0 + "\n");
        $0 = _t_0;
        $1 = (_acc_0 + _x_1);
        continue;
      }
    }
  }
}

function $nc_quote_chars$(_s_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_4 = run_loop($nt_choose$(($Char$is_eq$(_h_0, "\"")), run_clo((_x_0) => {
  return "\\\"";
}), run_clo((_x_1) => {
  return $nt_choose$(($Char$is_eq$(_h_0, "\\")), run_clo((_x_2) => {
  return "\\\\";
}), run_clo((_x_3) => {
  return (_h_0 + "");
}));
})));
    const _x_5 = ($nc_quote_chars$(_t_0));
    return (_x_4 + _x_5);
  }
}

function $nc_desc_error$(_d_0) {
  const _err_0 = _d_0["error"];
  return _err_0;
}

function $nc_desc_types$(_d_0) {
  const _types_0 = _d_0["types"];
  return _types_0;
}

function $nc_desc_cells$(_d_0) {
  const _cells_0 = _d_0["cells"];
  return _cells_0;
}

function $nc_show_array$(_d_0) {
  return {$: "NC_Desc", "cells": {$: "Con", "head": "6", "tail": ($List$append$(($nc_desc_cells$(_d_0)), {$: "Con", "head": "0", "tail": {$: "Nil"}}))}, "types": ($nc_desc_types$(_d_0)), "error": ($nc_desc_error$(_d_0))};
}

function $nc_show_ref$(_book_0, _ty_0, _types_0) {
  const _id_0 = run_loop($nc_show_find$(_book_0, _ty_0, _types_0, 0));
  return $nt_choose$((_id_0 === 4294967295), run_clo((_x_0) => {
  const _x_1 = ($U32$show$(($terms_len$(_types_0))));
  return {$: "NC_Desc", "cells": {$: "Con", "head": ("SD_" + _x_1), "tail": {$: "Nil"}}, "types": ($List$append$(_types_0, {$: "Con", "head": _ty_0, "tail": {$: "Nil"}})), "error": ""};
}), run_clo((_x_2) => {
  const _x_3 = ($U32$show$(_id_0));
  return {$: "NC_Desc", "cells": {$: "Con", "head": ("SD_" + _x_3), "tail": {$: "Nil"}}, "types": _types_0, "error": ""};
}));
}

function $nc_show_data$(_book_0, _ty_0, _types_0) {
  const _cs_0 = ($dc$(run_loop($lookup$(_book_0, ($nm$(_ty_0))))));
  const _d_0 = ($nc_show_arms$(_book_0, _cs_0, ($ks$(_ty_0)), _types_0));
  return {$: "NC_Desc", "cells": {$: "Con", "head": "7", "tail": {$: "Con", "head": "1", "tail": {$: "Con", "head": ($U32$show$(($nt_count$(_cs_0)))), "tail": ($nc_desc_cells$(_d_0))}}}, "types": ($nc_desc_types$(_d_0)), "error": ($nc_desc_error$(_d_0))};
}

function $nc_word_literal$(_t_0, _bit_0, _value_0) {
  return $nt_choose$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(($nm$(_t_0)), "WNil")))), run_clo((_x_0) => {
  return {$: "NC_Literal", "valid": true, "value": _value_0};
}), run_clo((_x_1) => {
  const _x_2 = ($String$eq$(($nm$(run_loop($kid$(_t_0, 0)))), "True"));
  const _x_3 = ($String$eq$(($nm$(run_loop($kid$(_t_0, 0)))), "False"));
  return $nt_choose$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(($nm$(_t_0)), "WCon")))), (_bit_0 < 32))), ($String$eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Ctr")))), (_x_2 || _x_3))), run_clo((_x_4) => {
  const _x_7 = run_loop($nt_choose$(($String$eq$(($nm$(run_loop($kid$(_t_0, 0)))), "True")), run_clo((_x_5) => {
  return (_bit_0 >= 32 ? 0 : (1 << _bit_0) >>> 0);
}), run_clo((_x_6) => {
  return 0;
})));
  return $nc_word_literal$(run_loop($kid$(_t_0, 1)), ((_bit_0 + 1) >>> 0), ((_value_0 | _x_7) >>> 0));
}), run_clo((_x_8) => {
  return {$: "NC_Literal", "valid": false, "value": 0};
}));
}));
}

function $nc_nat_literal$(_t_0, _value_0) {
  return $nt_choose$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  const _x_1 = ($qt$(_t_0));
  const _x_2 = ((4294967295 - _value_0) >>> 0);
  return $nt_choose$((_x_1 <= _x_2), run_clo((_x_3) => {
  const _x_4 = ($qt$(_t_0));
  return {$: "NC_Literal", "valid": true, "value": ((_value_0 + _x_4) >>> 0)};
}), run_clo((_x_5) => {
  return {$: "NC_Literal", "valid": false, "value": 0};
}));
}), run_clo((_x_6) => {
  return $nt_choose$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(($nm$(_t_0)), "Zero")))), run_clo((_x_7) => {
  return {$: "NC_Literal", "valid": true, "value": _value_0};
}), run_clo((_x_8) => {
  return $nt_choose$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(($nm$(_t_0)), "Succ")))), run_clo((_x_9) => {
  return $nc_nat_literal$(run_loop($kid$(_t_0, 0)), ((_value_0 + 1) >>> 0));
}), run_clo((_x_10) => {
  return {$: "NC_Literal", "valid": false, "value": 0};
}));
}));
}));
}

function $nc_call_head$(_t_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $nc_call_head$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $nc_mark_segments_go$($0, $1, $2, $3, $4) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _bang_0 = $1;
      const _forked_0 = $2;
      const _calls_0 = $3;
      const _acc_0 = $4;
      if (_ss_0.$ === "Nil") {
        return $nt_reverse$(_acc_0, {$: "Nil"});
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _ps_0 = _t_0["params"];
        const _r_0 = _t_0["result"];
        const _f_0 = _t_0["frame"];
        const _b_0 = _t_0["body"];
        const _refs_0 = _t_0["refs"];
        const _host_0 = _t_0["host"];
        const _spin_0 = _t_0["spin"];
        const _fork_0 = _t_0["fork"];
        const _rest_0 = _ss_0["tail"];
        $0 = _rest_0;
        $1 = _bang_0;
        $2 = _forked_0;
        $3 = _calls_0;
        $4 = {$: "Con", "head": {$: "N_Segment", "name": _k_0, "params": _ps_0, "result": _r_0, "frame": _f_0, "body": _b_0, "refs": run_loop($nt_choose$(($nb_contains$(_refs_0, "$local")), run_clo((_x_0) => {
  return _refs_0;
}), run_clo((_x_1) => {
  return _calls_0;
}))), "host": _host_0, "spin": _spin_0, "fork": run_loop($nt_choose$(($nb_contains$(_refs_0, "$local")), run_clo((_x_2) => {
  return _fork_0;
}), run_clo((_x_3) => {
  return _forked_0;
}))), "bang": _bang_0}, "tail": _acc_0};
        continue;
      }
    }
  }
}

function $nc_binding$(_id_0) {
  const _x_0 = ($U32$show$(_id_0));
  return {$: "NC_Binding", "id": _id_0, "word": ("v_" + _x_0)};
}

function $nd_name$(_name_0) {
  return ("$direct." + _name_0);
}

function $nc_params$(_env_0) {
  if (_env_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _env_0["head"];
    const _word_0 = _t_0["word"];
    const _rest_0 = _env_0["tail"];
    return {$: "Con", "head": {$: "N_Param", "name": _word_0, "kind": {$: "N_W64"}}, "tail": ($nc_params$(_rest_0))};
  }
}

function $nc_first_error$(_a_0, _b_0) {
  return $nt_choose$(($String$eq$(($nc_error$(_a_0)), "")), run_clo((_x_0) => {
  return $nc_error$(_b_0);
}), run_clo((_x_1) => {
  return $nc_error$(_a_0);
}));
}

function $nc_occurs$(_t_0, _id_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  const _x_1 = ($ix$(_t_0));
  return (_x_1 === _id_0);
}), run_clo((_x_2) => {
  return $nc_occurs_list$(($ks$(_t_0)), _id_0);
}));
}

function $nc_return$(_w_0, _n_0) {
  return {$: "NC_Code", "body": ($ne_ret$({$: "Con", "head": _w_0, "tail": {$: "Nil"}})), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}

function $nc_word$(_id_0, _env_0) {
  if (_env_0.$ === "Nil") {
    return "NATIVE_UNBOUND_VARIABLE";
  } else {
    const _t_0 = _env_0["head"];
    const _at_0 = _t_0["id"];
    const _word_0 = _t_0["word"];
    const _rest_0 = _env_0["tail"];
    return $nt_choose$((_id_0 === _at_0), run_clo((_x_0) => {
  return _word_0;
}), run_clo((_x_1) => {
  return $nc_word$(_id_0, _rest_0);
}));
  }
}

function $nc_fail$(_msg_0, _n_0) {
  return {$: "NC_Code", "body": "", "segments": {$: "Nil"}, "fresh": _n_0, "error": _msg_0};
}

function $ne_jump$(_ws_0, _k_0) {
  const _x_0 = ($nt_fid$(_k_0));
  const _x_1 = (_x_0 + ");\n");
  const _x_2 = ($ne_registers$(_ws_0, 0));
  const _x_3 = ("WL_JMP(" + _x_1);
  return (_x_2 + _x_3);
}

function $nc_lambda$(_book_0, _t_0, _env_0, _n_0) {
  const _name_0 = ($nc_name$(_n_0));
  const _params_0 = ($List$append$(_env_0, {$: "Con", "head": ($nc_binding$(($ix$(_t_0)))), "tail": {$: "Nil"}}));
  const _body_0 = ($nc_lower$(_book_0, run_loop($kid$(_t_0, 0)), _params_0, ((_n_0 + 1) >>> 0)));
  const _s_0 = {$: "N_Segment", "name": _name_0, "params": ($nc_params$(_params_0)), "result": 1, "frame": {$: "N_Direct"}, "body": ($nc_body$(_body_0)), "refs": {$: "Nil"}, "host": false, "spin": false, "fork": false, "bang": false};
  return $nc_closure_result$(_s_0, _body_0, ($ne_closure$(_name_0, ($nc_words$(_env_0)), ($nc_fresh$(_body_0)))));
}

function $nd_app$(_book_0, _t_0, _env_0, _n_0) {
  const _head_0 = run_loop($nd_head$(_t_0));
  const _args_0 = run_loop($nd_args$(_t_0, {$: "Nil"}));
  return $nt_choose$(($String$eq$(($tg$(_head_0)), "Lam")), run_clo((_x_0) => {
  return $nc_lower$(_book_0, run_loop($nd_beta$(_head_0, _args_0)), _env_0, _n_0);
}), run_clo((_x_1) => {
  const _x_2 = ($terms_len$(_args_0));
  return $nt_choose$(($Bool$and$(($String$eq$(($tg$(_head_0)), "Mat")), (_x_2 === 1))), run_clo((_x_3) => {
  return $nd_match$(_book_0, _head_0, run_loop($kid$(_t_0, 1)), _env_0, _n_0);
}), run_clo((_x_4) => {
  return $nt_choose$(($String$eq$(($tg$(_head_0)), "Ref")), run_clo((_x_5) => {
  const _x_6 = ($qt$(_head_0));
  const _x_7 = ($terms_len$(_args_0));
  const _x_8 = run_loop($nd_arity$(_book_0, ($nm$(_head_0))));
  const _x_9 = ($terms_len$(_args_0));
  return $nt_choose$(($Bool$and$(($Bool$and$(($Bool$not$((_x_6 === 3))), (_x_7 > 0))), (_x_8 === _x_9))), run_clo((_x_10) => {
  const _x_11 = ($terms_len$(_args_0));
  return $nc_lower$(_book_0, ($nc_sequence$("NCall", ($nd_name$(run_loop($nc_ref_name$(_book_0, ($nm$(_head_0)))))), _args_0, {$: "Nil"}, _n_0)), _env_0, ((_n_0 + _x_11) >>> 0));
}), run_clo((_x_12) => {
  return $nc_app_slow$(_book_0, _t_0, _env_0, _n_0);
}));
}), run_clo((_x_13) => {
  return $nc_app_slow$(_book_0, _t_0, _env_0, _n_0);
}));
}));
}));
}

function $nc_parallel$(_book_0, _xs_0, _env_0, _n_0) {
  const _seq_0 = ($nc_lets$(_book_0, _xs_0, _env_0, _n_0));
  const _name_0 = ($nc_name$(($nc_fresh$(_seq_0))));
  const _body_0 = ($nc_last_term$(_xs_0));
  const _held_0 = run_loop($nc_live_env$(_env_0, _body_0));
  const _params_0 = ($List$append$(_held_0, ($nc_parallel_binds$(_xs_0))));
  const _x_0 = ($nc_fresh$(_seq_0));
  const _join_0 = ($nc_lower$(_book_0, _body_0, _params_0, ((_x_0 + 1) >>> 0)));
  const _x_1 = ($terms_len$(_xs_0));
  const _task_0 = ($ne_task$(_name_0, ((_x_1 - 1) >>> 0), ($nc_words$(_held_0)), "WL_CONT", "WL_IDX", ($nc_fresh$(_join_0))));
  return $nc_parallel_task$(_book_0, _xs_0, _env_0, _name_0, _join_0, _seq_0, _task_0, _params_0, ($nt_count$(_held_0)));
}

function $nc_lets$(_book_0, _xs_0, _env_0, _n_0) {
  if (_xs_0.$ === "Nil") {
    return $nc_fail$("empty native let", _n_0);
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return $nc_lower$(_book_0, _h_0, _env_0, _n_0);
    } else {
      return $nc_let$(_book_0, run_loop($kid$(_h_0, 0)), ($kt$("NSeqLet", "", 0, 0, _t_0)), _env_0, ($ix$(_h_0)), _n_0);
    }
  }
}

function $nc_lower_ctor$(_book_0, _t_0, _env_0, _n_0, _lit_0) {
  const _valid_0 = _lit_0["valid"];
  const _value_0 = _lit_0["value"];
  return $nt_choose$(_valid_0, run_clo((_x_0) => {
  const _x_1 = ($U32$show$(_value_0));
  return $nc_return$((_x_1 + "ull"), _n_0);
}), run_clo((_x_2) => {
  const _x_3 = ($terms_len$(($ks$(_t_0))));
  return $nc_lower$(_book_0, ($nc_sequence$("NCtr", ($nm$(_t_0)), ($ks$(_t_0)), {$: "Nil"}, _n_0)), _env_0, ((_n_0 + _x_3) >>> 0));
}));
}

function $nc_constructor$(_name_0, _ws_0, _n_0) {
  const _x_0 = ($String$eq$(_name_0, "Zero"));
  const _x_1 = ($String$eq$(_name_0, "False"));
  return $nt_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $nc_return$("0", _n_0);
}), run_clo((_x_3) => {
  return $nt_choose$(($String$eq$(_name_0, "True")), run_clo((_x_4) => {
  return $nc_return$("1", _n_0);
}), run_clo((_x_5) => {
  return $nt_choose$(($String$eq$(_name_0, "Succ")), run_clo((_x_6) => {
  const _x_7 = ($nc_head$(_ws_0));
  const _x_8 = (_x_7 + " + 1)");
  return $nc_return$(("nat_chk(e, " + _x_8), _n_0);
}), run_clo((_x_9) => {
  const _x_10 = ($String$eq$(_name_0, "U32"));
  const _x_11 = ($String$eq$(_name_0, "F32"));
  return $nt_choose$((_x_10 || _x_11), run_clo((_x_12) => {
  const _x_13 = ($nc_head$(_ws_0));
  const _x_14 = (_x_13 + ")");
  return $nc_return$(("term_word(e, " + _x_14), _n_0);
}), run_clo((_x_15) => {
  return $nt_choose$(($String$eq$(_name_0, "Chr")), run_clo((_x_16) => {
  return $nc_return$(($nc_head$(_ws_0)), _n_0);
}), run_clo((_x_17) => {
  return $nt_choose$(($String$eq$(_name_0, "ALeaf")), run_clo((_x_18) => {
  const _x_19 = ($ne_ret$({$: "Con", "head": "blk_new(e, 1, 0, 0, 1, init)", "tail": {$: "Nil"}}));
  const _x_20 = ($nc_head$(_ws_0));
  const _x_21 = (" };\n" + _x_19);
  const _x_22 = (_x_20 + _x_21);
  return {$: "NC_Code", "body": ("Term init[1] = { " + _x_22), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}), run_clo((_x_23) => {
  return $nt_choose$(($String$eq$(_name_0, "ANode")), run_clo((_x_24) => {
  const _x_25 = ($nc_head$(($nc_tail$(_ws_0))));
  const _x_26 = (_x_25 + ")");
  const _x_27 = ($nc_head$(_ws_0));
  const _x_28 = (", " + _x_26);
  const _x_29 = (_x_27 + _x_28);
  return $nc_return$(("blk_node(e, " + _x_29), _n_0);
}), run_clo((_x_30) => {
  return $nc_ctor_result$(run_loop($ne_constructor$(_name_0, _ws_0, false, _n_0, true)));
}));
}));
}));
}));
}));
}));
}));
}

function $nc_values$(_xs_0, _env_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    return {$: "Con", "head": run_loop($nc_word$(($ix$(_h_0)), _env_0)), "tail": ($nc_values$(_t_0, _env_0))};
  }
}

function $nc_apply_code$(_ws_0, _n_0) {
  const _x_0 = ("Fid f = (Fid)term_aux(fn);\n" + "if (!seq && fid_bangs(f)) {\n  u32 war = fid_arity(f) - 1;\n  Loc src = term_loc(fn);\n  Loc dst = task_node(e, f, WL_CONT, WL_IDX, 0);\n  for (u32 j = 0; j < war; ++j) e.mem[dst + j] = e.mem[src + j];\n  e.mem[dst + war] = arg;\n  spare_free(e, cls_fit(war), src);\n  return term_tsk(f, dst);\n}\nr0 = fn; r1 = arg; WL_JMP(BEND_CLO_APPLY);\n}\n");
  const _x_1 = ($nc_head$(($nc_tail$(_ws_0))));
  const _x_2 = (";\n" + _x_0);
  const _x_3 = (_x_1 + _x_2);
  const _x_4 = ($nc_head$(_ws_0));
  const _x_5 = ("; Term arg = " + _x_3);
  const _x_6 = (_x_4 + _x_5);
  return {$: "NC_Code", "body": ("{ Term fn = " + _x_6), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}

function $nc_match$(_book_0, _t_0, _env_0, _n_0) {
  return $nc_lambda$(_book_0, ($kt$("Lam", "", ($nc_id$(_n_0)), 1, {$: "Con", "head": ($kt$("NMatch", "", 0, 0, {$: "Con", "head": _t_0, "tail": {$: "Con", "head": ($var$("", ($nc_id$(_n_0)))), "tail": {$: "Nil"}}})), "tail": {$: "Nil"}})), _env_0, ((_n_0 + 1) >>> 0));
}

function $nc_match_apply$(_book_0, _t_0, _env_0, _n_0) {
  return $nt_choose$(($np_can_match$(run_loop($kid$(_t_0, 0)))), run_clo((_x_0) => {
  return $np_match_apply$(_book_0, _t_0, _env_0, _n_0);
}), run_clo((_x_1) => {
  return $nc_match_apply_slow$(_book_0, _t_0, _env_0, _n_0);
}));
}

function $nc_intrinsic$(_k_0, _ws_0, _n_0) {
  return $nt_choose$(($nc_array_known$(_k_0)), run_clo((_x_0) => {
  return $nc_array$(_k_0, _ws_0, _n_0);
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(_k_0, "nat_divmod")), run_clo((_x_2) => {
  const _x_3 = ($nc_head$(($nc_tail$(_ws_0))));
  const _x_4 = (_x_3 + ")");
  const _x_5 = ($nc_head$(_ws_0));
  const _x_6 = (" / " + _x_4);
  const _x_7 = (_x_5 + _x_6);
  const _x_8 = ($nc_head$(($nc_tail$(_ws_0))));
  const _x_9 = (" == 0 ? 0 : " + _x_7);
  const _x_10 = (_x_8 + _x_9);
  const _x_11 = ($nc_head$(($nc_tail$(_ws_0))));
  const _x_12 = (_x_11 + ")");
  const _x_13 = ($nc_head$(_ws_0));
  const _x_14 = (" % " + _x_12);
  const _x_15 = (_x_13 + _x_14);
  const _x_16 = ($nc_head$(_ws_0));
  const _x_17 = (" : " + _x_15);
  const _x_18 = (_x_16 + _x_17);
  const _x_19 = ($nc_head$(($nc_tail$(_ws_0))));
  const _x_20 = (" == 0 ? " + _x_18);
  const _x_21 = (_x_19 + _x_20);
  return $nc_ctor_result$(run_loop($ne_constructor$("Tuple", {$: "Con", "head": ("(" + _x_10), "tail": {$: "Con", "head": ("(" + _x_21), "tail": {$: "Nil"}}}, false, _n_0, true)));
}), run_clo((_x_22) => {
  const _x_23 = ($String$eq$(_k_0, "u32_cmp"));
  const _x_24 = ($String$eq$(_k_0, "nat_cmp"));
  return $nt_choose$((_x_23 || _x_24), run_clo((_x_25) => {
  const _x_26 = ($ne_ret$({$: "Con", "head": "term_pak(cmp == 0 ? CID_LT : cmp == 1 ? CID_EQ : CID_GT, 0)", "tail": {$: "Nil"}}));
  const _x_27 = ($ni_emit$(_k_0, _ws_0));
  const _x_28 = (";\n" + _x_26);
  const _x_29 = (_x_27 + _x_28);
  return {$: "NC_Code", "body": ("Term cmp = " + _x_29), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}), run_clo((_x_30) => {
  return $nc_return$(($ni_emit$(_k_0, _ws_0)), _n_0);
}));
}));
}));
}

function $nc_prim_args$(_n_0, _i_0) {
  return $nt_choose$((_i_0 === _n_0), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return {$: "Con", "head": ($var$("", ((4000000000 + _i_0) >>> 0))), "tail": run_loop($nc_prim_args$(_n_0, ((_i_0 + 1) >>> 0)))};
}));
}

function $subst_node$(_t_0, _id_0, _v_0) {
  const _tag_0 = _t_0["tag"];
  const _name_0 = _t_0["name"];
  const _n_0 = _t_0["id"];
  const _q_0 = _t_0["quant"];
  const _kids_0 = _t_0["kids"];
  const _removed_0 = _t_0["removed"];
  return $core_rebuild$({$: "KTerm", "tag": _tag_0, "name": _name_0, "id": _n_0, "quant": _q_0, "kids": ($subst_terms$(_kids_0, _id_0, _v_0)), "removed": _removed_0});
}

function $nc_erase_args$(_book_0, _tel_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    const _head_0 = run_loop($wnf$(_book_0, _tel_0));
    const _x_0 = ($qt$(_head_0));
    return $nt_choose$((_x_0 === 0), run_clo((_x_1) => {
  return $nc_erase_args$(_book_0, run_loop($subst$(run_loop($kid$(_head_0, 1)), ($ix$(_head_0)), _h_0)), _rest_0);
}), run_clo((_x_2) => {
  return {$: "Con", "head": run_loop($nc_erase$(_book_0, _h_0)), "tail": run_loop($nc_erase_args$(_book_0, run_loop($subst$(run_loop($kid$(_head_0, 1)), ($ix$(_head_0)), _h_0)), _rest_0))};
}));
  }
}

function $nc_tele_fill$($0, $1, $2) {
  for (;;) {
    {
      const _book_0 = $0;
      const _tel_0 = $1;
      const _args_0 = $2;
      if (_args_0.$ === "Nil") {
        return _tel_0;
      } else {
        const _h_0 = _args_0["head"];
        const _rest_0 = _args_0["tail"];
        const _head_0 = run_loop($wnf$(_book_0, _tel_0));
        $0 = _book_0;
        $1 = run_loop($subst$(run_loop($kid$(_head_0, 1)), ($ix$(_head_0)), _h_0));
        $2 = _rest_0;
        continue;
      }
    }
  }
}

function $nc_erase_mat$(_book_0, _t_0, _adt_0) {
  const _ctr_0 = run_loop($lookup$(($dc$(run_loop($lookup$(_book_0, ($nm$(_adt_0)))))), ($nm$(_t_0))));
  const _count_0 = run_loop($nc_live_count$(_book_0, ($nc_tele_fill$(_book_0, ($dt$(_ctr_0)), ($ks$(_adt_0)))), ($da$(_ctr_0))));
  return $kt$("Mat", run_loop($nt_choose$(($db$(run_loop($lookup$(_book_0, ($nm$(_adt_0)))))), run_clo((_x_0) => {
  return $nm$(_t_0);
}), run_clo((_x_1) => {
  return $nc_ctor_identity$(_book_0, ($nm$(_t_0)));
}))), ((_count_0 + 1) >>> 0), ($qt$(_t_0)), ($nc_erase_list$(_book_0, ($ks$(_t_0)))));
}

function $Char$is_lower$(_c_0) {
  const _x_0 = _c_0.codePointAt(0);
  const _x_1 = _c_0.codePointAt(0);
  return $Bool$and$((_x_0 >= 97), (_x_1 <= 122));
}

function $nc_ctor_decode_step$(_h_0, _rest_0, _acc_0, _digits_0, _out_0, _original_0) {
  return $kc$(($Char$is_eq$(_h_0, "_")), run_clo((_x_0) => {
  return $kc$(($Bool$and$(($Bool$and$((_digits_0 > 0), (_acc_0 <= 1114111))), ($Bool$not$(($Bool$and$((_acc_0 >= 55296), (_acc_0 <= 57343))))))), run_clo((_x_1) => {
  const _x_2 = ($Char$show$(($Char$from_u32$(_acc_0))));
  return $nc_ctor_decode$(_rest_0, 0, 0, (_out_0 + _x_2), _original_0);
}), run_clo((_x_3) => {
  return _original_0;
}));
}), run_clo((_x_4) => {
  const _x_5 = ($Char$to_u32$(_h_0));
  const _x_6 = ($Char$to_u32$(_h_0));
  return $kc$(($Bool$and$(($Bool$and$((_x_5 >= 48), (_x_6 <= 57))), (_digits_0 < 7))), run_clo((_x_7) => {
  const _x_8 = ($Char$to_u32$(_h_0));
  const _x_9 = (Math.imul(_acc_0, 10) >>> 0);
  const _x_10 = ((_x_8 - 48) >>> 0);
  return $nc_ctor_decode$(_rest_0, ((_x_9 + _x_10) >>> 0), ((_digits_0 + 1) >>> 0), _out_0, _original_0);
}), run_clo((_x_11) => {
  return _original_0;
}));
}));
}

function $exact_terms_head$(_h_0, _rest_0, _b_0) {
  if (_b_0.$ === "Nil") {
    return false;
  } else {
    const _x_0 = _b_0["head"];
    const _xs_0 = _b_0["tail"];
    return $Bool$and$(($exact_term$(_h_0, _x_0)), ($exact_terms$(_rest_0, _xs_0)));
  }
}

function $exact_names_empty$(_b_0) {
  if (_b_0.$ === "Nil") {
    return true;
  } else {
    return false;
  }
}

function $exact_names_head$(_h_0, _rest_0, _b_0) {
  if (_b_0.$ === "Nil") {
    return false;
  } else {
    const _x_0 = _b_0["head"];
    const _xs_0 = _b_0["tail"];
    return $Bool$and$(($String$eq$(_h_0, _x_0)), ($exact_names$(_rest_0, _xs_0)));
  }
}

function $fpe_source_render$(_legacy_0, _error_0, _source_0) {
  return $f_choose$(($f_eq$(($tg$(_source_0)), "ParseSource")), run_clo((_x_0) => {
  return $fpe_render$(($nm$(_source_0)), _error_0);
}), run_clo((_x_1) => {
  return _legacy_0;
}));
}

function $fpe_unique_source$(_path_0, _sources_0, _found_0) {
  if (_sources_0.$ === "Nil") {
    return _found_0;
  } else {
    const _head_0 = _sources_0["head"];
    const _tail_0 = _sources_0["tail"];
    return $f_choose$(($String$eq$(_path_0, ($f_source_path$(_head_0)))), run_clo((_x_0) => {
  return $f_choose$(($f_eq$(($tg$(_found_0)), "Absent")), run_clo((_x_1) => {
  return $fpe_unique_source$(_path_0, _tail_0, ($kt$("ParseSource", ($f_source_text$(_head_0)), 0, 0, {$: "Nil"})));
}), run_clo((_x_2) => {
  return $atom$("Ambiguous");
}));
}), run_clo((_x_3) => {
  return $fpe_unique_source$(_path_0, _tail_0, _found_0);
}));
  }
}

function $fpe_owner_path$(_done_0, _index_0) {
  if (_done_0.$ === "Nil") {
    return "";
  } else {
    const _head_0 = _done_0["head"];
    const _tail_0 = _done_0["tail"];
    const _x_0 = ($ix$(_head_0));
    return $f_choose$((_index_0 < _x_0), run_clo((_x_1) => {
  return $nm$(_head_0);
}), run_clo((_x_2) => {
  const _x_3 = ($ix$(_head_0));
  return $fpe_owner_path$(_tail_0, ((_index_0 - _x_3) >>> 0));
}));
  }
}

function $fpe_find_next$(_error_0, _rest_0, _index_0) {
  return $f_choose$(($f_eq$(($tg$(_error_0)), "Absent")), run_clo((_x_0) => {
  return $fpe_find$(_rest_0, ((_index_0 + 1) >>> 0));
}), run_clo((_x_1) => {
  return $kt$("ParseOwner", "", _index_0, 0, {$: "Con", "head": _error_0, "tail": {$: "Nil"}});
}));
}

function $fpe_def$(_d_0) {
  return $fpe_defs_next$(run_loop($fpe_terms$({$: "Con", "head": ($dt$(_d_0)), "tail": {$: "Con", "head": ($dv$(_d_0)), "tail": {$: "Nil"}}})), ($dc$(_d_0)));
}

function $f_graph_fresh_hashed$(_rest_0, _done_0, _d_0, _hash_0) {
  return $f_graph_fresh_name$(_rest_0, _done_0, _d_0, _hash_0, run_loop($index_find$(_done_0, ($dn$(_d_0)), _hash_0, 32)));
}

function $fpe_defs$(_ds_0) {
  if (_ds_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _head_0 = _ds_0["head"];
    const _tail_0 = _ds_0["tail"];
    return $fpe_defs_next$(run_loop($fpe_def$(_head_0)), _tail_0);
  }
}

function $fs_book$(_seed_0) {
  const _book_0 = _seed_0["book"];
  return _book_0;
}

function $f_graph_count_defs$($0, $1) {
  for (;;) {
    {
      const _book_0 = $0;
      const _count_0 = $1;
      if (_book_0.$ === "Nil") {
        return _count_0;
      } else {
        const _tail_0 = _book_0["tail"];
        $0 = _tail_0;
        $1 = ((_count_0 + 1) >>> 0);
        continue;
      }
    }
  }
}

function $fs_imports$($0, $1, $2, $3, $4, $5, $6, $7, $8) {
  for (;;) {
    {
      const _s_0 = $0;
      const _ns_0 = $1;
      const _book_0 = $2;
      const _allimports_0 = $3;
      const _imports_0 = $4;
      const _sources_0 = $5;
      const _g_0 = $6;
      const _stack_0 = $7;
      const _seed_0 = $8;
      if (_imports_0.$ === "Nil") {
        return $f_graph_finish$(_s_0, _ns_0, _book_0, ($f_graph_aliases$(_allimports_0, _s_0, _sources_0, ($fs_root$(_seed_0)))), _g_0);
      } else {
        const _im_0 = _imports_0["head"];
        const _rest_0 = _imports_0["tail"];
        $0 = _s_0;
        $1 = _ns_0;
        $2 = _book_0;
        $3 = _allimports_0;
        $4 = _rest_0;
        $5 = _sources_0;
        $6 = run_loop($fs_load$(run_loop($f_import_pathname$(_im_0, _s_0, _sources_0)), run_loop($f_import_namespace_at$(_im_0, _s_0, _sources_0, ($fs_root$(_seed_0)))), _sources_0, _g_0, _stack_0, _seed_0));
        $7 = _stack_0;
        $8 = _seed_0;
        continue;
      }
    }
  }
}

function $f_graph_error$(_g_0, _err_0) {
  const _book_0 = _g_0["book"];
  const _done_0 = _g_0["done"];
  return {$: "FGraph", "book": _book_0, "error": _err_0, "done": _done_0};
}

function $dg_no_report$(_name_0, _message_0) {
  return {$: "DDiagnostic", "expected": {$: "DText", "text": _message_0}, "observed": {$: "DText", "text": ""}, "has_observed": false, "context": {$: "Nil"}, "definition": _name_0, "span": {$: "DNoSpan"}, "note": "", "trail": {$: "Nil"}};
}

function $dg_finish$(_error_0, _book_0, _diagnostic_0, _origins_0) {
  return {$: "DResult", "error": _error_0, "book": _book_0, "diagnostic": ($diagnostic_locate$(_diagnostic_0, _origins_0))};
}

function $check_open_message$(_n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_4 = run_loop($kc$((_n_0 === 1), run_clo((_x_2) => {
  return "";
}), run_clo((_x_3) => {
  return "s";
})));
  const _x_5 = (_x_4 + " found.\nThe code is incomplete, and not a valid proof yet.");
  const _x_6 = ($U32$show$(_n_0));
  const _x_7 = (" TODO" + _x_5);
  return (_x_6 + _x_7);
}));
}

function $count_open$(_book_0) {
  if (_book_0.$ === "Nil") {
    return 0;
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    const _x_2 = run_loop($kc$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), ($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))), ($Bool$not$(($db$(_d_0)))))), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  return 0;
})));
    const _x_3 = ($count_open$(_rest_0));
    return ((_x_2 + _x_3) >>> 0);
  }
}

function $dg_suffix_check$(_rest_0, _done_0, _d_0, _seen_0, _original_0, _origins_0, _checked_0) {
  return $kc$(($good$(_checked_0)), run_clo((_x_0) => {
  return $dg_suffix_events$(_rest_0, run_loop($check_event_install$(_done_0, _d_0, _rest_0)), run_loop($book_put$(_seen_0, _d_0)), _original_0, _origins_0);
}), run_clo((_x_1) => {
  const _x_2 = ($ce$(_checked_0));
  const _x_3 = ($dn$(_d_0));
  const _x_4 = (": " + _x_2);
  return $dg_finish$((_x_3 + _x_4), run_loop($book_put$(_done_0, ($declared$(_d_0)))), run_loop($dg_report$(_checked_0, ($dn$(_d_0)))), _origins_0);
}));
}

function $check_definition_result$(_book_0, _d_0) {
  return $check_definition_type$(_book_0, _d_0, {$: "KEnv", "book": _book_0, "name": ($dn$(_d_0)), "lhs": ($ref$(($dn$(_d_0)))), "pending": 0, "quantities": {$: "Nil"}, "unsafe": ($du$(_d_0))}, run_loop($check$({$: "KEnv", "book": _book_0, "name": ($dn$(_d_0)), "lhs": ($ref$(($dn$(_d_0)))), "pending": 0, "quantities": {$: "Nil"}, "unsafe": ($du$(_d_0))}, {$: "Nil"}, ($dt$(_d_0)), 0, ($typ$(1)))));
}

function $signature_mode$(_d_0, _later_0) {
  return $kc$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), ($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))), run_clo((_x_0) => {
  return $signature_fill_mode$(_d_0, run_loop($lookup$(_later_0, ($dn$(_d_0)))));
}), run_clo((_x_1) => {
  return _d_0;
}));
}

function $constructor_names$(_done_0, _ctrs_0, _names_0) {
  if (_ctrs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ctrs_0["head"];
    const _rest_0 = _ctrs_0["tail"];
    const _x_0 = run_loop($has_name$(_names_0, ($dn$(_h_0))));
    const _x_1 = ($constructor_exists$(_done_0, ($dn$(_h_0))));
    return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return "duplicate constructor name";
}), run_clo((_x_3) => {
  return $constructor_names$(_done_0, _rest_0, {$: "Con", "head": ($dn$(_h_0)), "tail": _names_0});
}));
  }
}

function $compare$(_book_0, _a_0, _b_0, _le_0) {
  return $kc$(run_loop($norm_exact$(_a_0, _b_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  const _x_2 = run_loop($norm_max$(run_loop($norm_book_bound$(_book_0)), run_loop($norm_max$(($norm_max_term$(_a_0)), ($norm_max_term$(_b_0))))));
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": _a_0, "b": _b_0, "le": _le_0, "fresh": ((1 + _x_2) >>> 0)}, "tail": {$: "Nil"}}, {$: "Nil"});
}));
}

function $dg_rpad$(_s_0, _width_0) {
  const _x_0 = ($dg_width$(_s_0));
  const _x_4 = run_loop($dg_padding$(run_loop($kc$((_width_0 > _x_0), run_clo((_x_1) => {
  const _x_2 = ($dg_width$(_s_0));
  return ((_width_0 - _x_2) >>> 0);
}), run_clo((_x_3) => {
  return 0;
})))));
  return (_s_0 + _x_4);
}

function $dg_width$(_s_0) {
  if (_s_0 === "") {
    return 0;
  } else {
    const _c_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _rest_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_0 = run_loop($dg_units$(_c_0));
    const _x_1 = ($dg_width$(_rest_0));
    return ((_x_0 + _x_1) >>> 0);
  }
}

function $dg_location_text$(_name_0, _snippet_0) {
  return $kc$(($Bool$and$(($String$eq$(_name_0, "")), ($String$eq$(_snippet_0, "")))), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_4 = run_loop($kc$(($String$eq$(_name_0, "")), run_clo((_x_2) => {
  return "";
}), run_clo((_x_3) => {
  return (" " + _name_0);
})));
  const _x_5 = (_x_4 + _snippet_0);
  return ("\nLocation:" + _x_5);
}));
}

function $dg_snippet$(_span_0) {
  if (_span_0.$ === "DNoSpan") {
    return "";
  } else {
    const _source_0 = _span_0["source"];
    const _begin_0 = _span_0["begin"];
    return $dg_snippet_at$(($String$lines$(_source_0)), run_loop($dg_line_at$(_source_0, _begin_0, 1)));
  }
}

function $norm_exact_lists$(_as_0, _bs_0) {
  if (_as_0.$ === "Nil") {
    if (_bs_0.$ === "Nil") {
      return true;
    } else {
      return false;
    }
  } else {
    const _a_0 = _as_0["head"];
    const _ar_0 = _as_0["tail"];
    if (_bs_0.$ === "Con") {
      const _b_0 = _bs_0["head"];
      const _br_0 = _bs_0["tail"];
      return $kc$(($norm_exact_head$(_a_0, _b_0)), run_clo((_x_0) => {
  return $norm_exact_lists$(($norm_join$(($ks$(_a_0)), _ar_0)), ($norm_join$(($ks$(_b_0)), _br_0)));
}), run_clo((_x_1) => {
  return false;
}));
    } else {
      return false;
    }
  }
}

function $dg_span_fields$(_s_0, _b0_0, _e0_0, _b_0) {
  if (_b_0.$ === "DNoSpan") {
    return false;
  } else {
    const _t_0 = _b_0["source"];
    const _b1_0 = _b_0["begin"];
    const _e1_0 = _b_0["end"];
    return $Bool$and$(($Bool$and$(($String$eq$(_s_0, _t_0)), (_b0_0 === _b1_0))), (_e0_0 === _e1_0));
  }
}

function $fp_loaded_has$(_book_0, _definition_0) {
  if (_book_0.$ === "Nil") {
    return false;
  } else {
    const _head_0 = _book_0["head"];
    const _tail_0 = _book_0["tail"];
    return $f_choose$(($String$eq$(($dn$(_head_0)), _definition_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $fp_loaded_has$(_tail_0, _definition_0);
}));
  }
}

function $fp_loaded_defs$(_book_0, _source_0, _all_0, _definition_0) {
  if (_book_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _head_0 = _book_0["head"];
    const _tail_0 = _book_0["tail"];
    const _x_0 = ($String$eq$(($dn$(_head_0)), _definition_0));
    return $List$append$(run_loop($f_choose$((_all_0 || _x_0), run_clo((_x_1) => {
  return $fp_def$(_head_0, _source_0);
}), run_clo((_x_2) => {
  return {$: "Nil"};
}))), ($fp_loaded_defs$(_tail_0, _source_0, _all_0, _definition_0)));
  }
}

function $j_printable_ctors$(_book_0, _ctors_0, _params_0, _seen_0, _fuel_0) {
  if (_ctors_0.$ === "Nil") {
    return true;
  } else {
    const _d_0 = _ctors_0["head"];
    const _rest_0 = _ctors_0["tail"];
    return $Bool$and$(run_loop($j_printable_fields$(_book_0, ($j_specialize$(_book_0, ($dt$(_d_0)), _params_0)), _seen_0, _fuel_0)), ($j_printable_ctors$(_book_0, _rest_0, _params_0, _seen_0, _fuel_0)));
  }
}

function $j_layout_mark$(_bad_0, _todo_0) {
  return $kc$(_bad_0, run_clo((_x_0) => {
  return {$: "Con", "head": "$layout.open-array", "tail": _todo_0};
}), run_clo((_x_1) => {
  return _todo_0;
}));
}

function $j_layout_array_intrinsic$(_book_0, _f_0) {
  const _x_0 = ($nm$(_f_0));
  const _x_1 = (_x_0 + "|");
  return $Bool$and$(($Bool$and$(($String$eq$(($tg$(_f_0)), "Ref")), ($db$(run_loop($lookup$(_book_0, ($nm$(_f_0)))))))), ($String$contains$("|Array.new|Array.set|Array.get|Array.swap|Array.size|", ("|" + _x_1))));
}

function $j_layout_app$(_book_0, _env_0, _t_0, _fty_0, _todo_0) {
  const _x_0 = ($qt$(_fty_0));
  return $j_layout_mark$(run_loop($j_layout_intrinsic$(_book_0, run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), run_loop($kid$(_t_0, 1)))), run_loop($j_layout_function$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), _fty_0, run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_fty_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return _todo_0;
}), run_clo((_x_2) => {
  return $j_layout_term$(_book_0, _env_0, run_loop($kid$(_t_0, 1)), run_loop($kid$(_fty_0, 0)), _todo_0);
}))))));
}

function $j_layout_lam$(_book_0, _env_0, _t_0, _ty_0, _todo_0) {
  return $j_layout_term$(_book_0, {$: "Con", "head": ($kt$("Env", "", ($ix$(_t_0)), 0, {$: "Con", "head": run_loop($kid$(_ty_0, 0)), "tail": {$: "Nil"}})), "tail": _env_0}, run_loop($kid$(_t_0, 0)), run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))), _todo_0);
}

function $j_layout_match$(_book_0, _env_0, _t_0, _ty_0, _todo_0) {
  const _x_0 = ($j_constructor_count$(_book_0, run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0))))));
  return $j_layout_mark$(run_loop($j_layout_open$(_book_0, run_loop($kid$(_ty_0, 0)))), run_loop($j_layout_term$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($j_arm_type$(_book_0, _ty_0, ($nm$(_t_0)))), run_loop($kc$((_x_0 === 1), run_clo((_x_1) => {
  return _todo_0;
}), run_clo((_x_2) => {
  return $j_layout_term$(_book_0, _env_0, run_loop($kid$(_t_0, 1)), _ty_0, _todo_0);
}))))));
}

function $j_layout_open$(_book_0, _ty_0) {
  return $j_layout_open_head$(_book_0, run_loop($wnf$(_book_0, _ty_0)));
}

function $j_layout_fields$($0, $1, $2, $3, $4) {
  for (;;) {
    {
      const _book_0 = $0;
      const _env_0 = $1;
      const _args_0 = $2;
      const _tel_0 = $3;
      const _todo_0 = $4;
      if (_args_0.$ === "Nil") {
        return _todo_0;
      } else {
        const _h_0 = _args_0["head"];
        const _rest_0 = _args_0["tail"];
        const _x_0 = ($qt$(_tel_0));
        $0 = _book_0;
        $1 = _env_0;
        $2 = _rest_0;
        $3 = run_loop($j_app_type$(_tel_0, _h_0));
        $4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_tel_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return _todo_0;
}), run_clo((_x_2) => {
  return $j_layout_term$(_book_0, _env_0, _h_0, run_loop($kid$(_tel_0, 0)), _todo_0);
})));
        continue;
      }
    }
  }
}

function $j_layout_let$(_book_0, _env_0, _xs_0, _ty_0, _todo_0) {
  return $j_layout_bindings$(_book_0, _env_0, _xs_0, run_loop($j_layout_term$(_book_0, ($j_context$(_book_0, _env_0, _xs_0)), ($j_body$(_xs_0)), _ty_0, _todo_0)));
}

function $kr_refs_list$($0, $1) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _t_0 = $0;
      const _todo_0 = $1;
      const _x_0 = ($String$eq$(($tg$(_t_0)), "Ref"));
      const _x_1 = ($String$eq$(($tg$(_t_0)), "ADT"));
      const _x_2 = (_x_0 || _x_1);
      const _x_3 = ($String$eq$(($tg$(_t_0)), "Ctr"));
      const _x_4 = (_x_2 || _x_3);
      const _x_5 = ($String$eq$(($tg$(_t_0)), "Mat"));
      $0 = ($ks$(_t_0));
      $1 = run_loop($kc$((_x_4 || _x_5), run_clo((_x_6) => {
  return $kr_push$(($nm$(_t_0)), _todo_0);
}), run_clo((_x_7) => {
  return _todo_0;
})));
      $pc = 1; continue;
    }
    case 1: {
      const _terms_0 = $0;
      const _todo_0 = $1;
      if (_terms_0.$ === "Nil") {
        return _todo_0;
      } else {
        const _h_0 = _terms_0["head"];
        const _rest_0 = _terms_0["tail"];
        $0 = _h_0;
        $1 = ($kr_refs_list$(_rest_0, _todo_0));
        $pc = 0; continue;
      }
    }
  }
}

function $kr_push$(_name_0, _names_0) {
  return $kc$(run_loop($has_name$(_names_0, _name_0)), run_clo((_x_0) => {
  return _names_0;
}), run_clo((_x_1) => {
  return {$: "Con", "head": _name_0, "tail": _names_0};
}));
}

function $j_schema_fields$(_book_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_ty_0));
  const _x_4 = run_loop($j_schema_fields$(_book_0, run_loop($kid$(_ty_0, 1))));
  const _x_5 = run_loop($kc$((_x_1 === 0), run_clo((_x_2) => {
  return "[\"Erased\"]";
}), run_clo((_x_3) => {
  return $j_descriptor$(_book_0, run_loop($kid$(_ty_0, 0)), 64);
})));
  const _x_6 = ("," + _x_4);
  return (_x_5 + _x_6);
}), run_clo((_x_7) => {
  return "";
}));
}

function $j_foreign_args$(_book_0, _ty_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = run_loop($j_foreign_args$(_book_0, run_loop($kid$(_ty_0, 1)), ((_n_0 - 1) >>> 0)));
  const _x_3 = run_loop($j_descriptor$(_book_0, run_loop($kid$(_ty_0, 0)), 64));
  const _x_4 = ("]," + _x_2);
  const _x_5 = (_x_3 + _x_4);
  const _x_6 = ($U32$show$(($qt$(_ty_0))));
  const _x_7 = ("," + _x_5);
  const _x_8 = (_x_6 + _x_7);
  return ("[" + _x_8);
}));
}

function $j_io_result$(_book_0, _ty_0) {
  return $kid$(run_loop($wnf$(_book_0, run_loop($kid$(run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 1)))), 0)))), 0);
}

function $j_foreign_return$(_book_0, _ty_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return $wnf$(_book_0, _ty_0);
}), run_clo((_x_1) => {
  return $j_foreign_return$(_book_0, run_loop($kid$(_ty_0, 1)), ((_n_0 - 1) >>> 0));
}));
}

function $j_l_deep$(_t_0, _depth_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $j_l_deep$(run_loop($kid$(_t_0, 0)), _depth_0);
}), run_clo((_x_1) => {
  const _x_2 = ($String$eq$(($tg$(_t_0)), "Var"));
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Ref"));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return false;
}), run_clo((_x_5) => {
  const _x_6 = ($String$eq$(($tg$(_t_0)), "Lam"));
  const _x_7 = ($String$eq$(($tg$(_t_0)), "Mat"));
  return $kc$((_x_6 || _x_7), run_clo((_x_8) => {
  return $kc$((_depth_0 >= 32), run_clo((_x_9) => {
  return true;
}), run_clo((_x_10) => {
  return $j_l_deeps$(($ks$(_t_0)), ((_depth_0 + 1) >>> 0));
}));
}), run_clo((_x_11) => {
  return $j_l_deeps$(($ks$(_t_0)), _depth_0);
}));
}));
}));
}

function $j_l_definition$(_book_0, _d_0, _t_0) {
  const _x_0 = ($j_l_global$(_book_0, _d_0, _t_0));
  const _x_1 = run_loop($j_l_walk$(_book_0, {$: "Nil"}, _t_0, ($dt$(_d_0))));
  const _x_2 = (_x_0 + "}\n");
  const _x_3 = (_x_1 + _x_2);
  return ("{const F=Object.create(null);\n" + _x_3);
}

function $j_l_mark$(_t_0, _path_0, _depth_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": {$: "Con", "head": run_loop($j_l_mark$(run_loop($kid$(_t_0, 0)), _path_0, _depth_0)), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Nil"}}}, "removed": ($rm$(_t_0))};
}), run_clo((_x_1) => {
  const _x_2 = ($String$eq$(($tg$(_t_0)), "Var"));
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Ref"));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return _t_0;
}), run_clo((_x_5) => {
  const _x_6 = ($String$eq$(($tg$(_t_0)), "Lam"));
  const _x_7 = ($String$eq$(($tg$(_t_0)), "Mat"));
  return $kc$((_x_6 || _x_7), run_clo((_x_8) => {
  return $kc$((_depth_0 >= 32), run_clo((_x_9) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($j_l_marks$(($ks$(_t_0)), _path_0, 0, 0)), "removed": {$: "Con", "head": ("$js." + _path_0), "tail": {$: "Nil"}}};
}), run_clo((_x_10) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($j_l_marks$(($ks$(_t_0)), _path_0, ((_depth_0 + 1) >>> 0), 0)), "removed": ($rm$(_t_0))};
}));
}), run_clo((_x_11) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($j_l_marks$(($ks$(_t_0)), _path_0, _depth_0, 0)), "removed": ($rm$(_t_0))};
}));
}));
}));
}

function $j_l_global$(_book_0, _d_0, _t_0) {
  return $j_l_global_worker$(_book_0, _d_0, _t_0, run_loop($j_projection_worker$(_book_0, _t_0, ($dt$(_d_0)))));
}

function $fpe_snippet$(_lines_0, _at_0) {
  const _x_0 = ($fpe_lines_count$(_lines_0));
  const _x_1 = ((_at_0 + 1) >>> 0);
  return $fpe_snippet_lines$(_lines_0, _at_0, run_loop($f_choose$((_x_0 < _x_1), run_clo((_x_2) => {
  return $fpe_lines_count$(_lines_0);
}), run_clo((_x_3) => {
  return ((_at_0 + 1) >>> 0);
}))), 1);
}

function $String$lines$(_s_0) {
  return $String$split$(_s_0, "\n");
}

function $f_import_path$(_ts_0, _path_0, _book_0, _imports_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "as")), run_clo((_x_0) => {
  return $f_import_alias$(_ts_0, _path_0, _book_0, _imports_0);
}), run_clo((_x_1) => {
  const _x_2 = ($f_eq$(($f_tx$(_ts_0)), "\n"));
  const _x_3 = ($f_eq$(($f_tx$(_ts_0)), "<eof>"));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $f_choose$(($f_eq$(_path_0, "Base")), run_clo((_x_5) => {
  return $f_tops$(_ts_0, _book_0, {$: "Con", "head": ($kt$("Import", _path_0, 0, 0, {$: "Nil"})), "tail": _imports_0}, false);
}), run_clo((_x_6) => {
  return $f_result$(_book_0, ($kt$("Error", "a module import requires as followed by an alias", 0, 0, {$: "Nil"})), _imports_0);
}));
}), run_clo((_x_7) => {
  const _x_8 = ($f_tx$(_ts_0));
  return $f_import_path$(($f_tl$(_ts_0)), (_path_0 + _x_8), _book_0, _imports_0);
}));
}));
}

function $f_name_chars$(_s_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  const _x_2 = ($Bool$not$(($Char$is_eq$(($f_head$(_s_0)), "."))));
  const _x_3 = ($f_ascii_alpha$(($f_head$(($f_tail$(_s_0))))));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($Char$is_eq$(($f_head$(($f_tail$(_s_0)))), "_"));
  return $Bool$and$(($Bool$and$(($f_ident$(($f_head$(_s_0)))), (_x_4 || _x_5))), run_loop($f_name_chars$(($f_tail$(_s_0)))));
}));
}

function $f_reserved$(_s_0) {
  const _x_0 = ($f_eq$(_s_0, "def"));
  const _x_1 = ($f_eq$(_s_0, "type"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(_s_0, "law"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(_s_0, "match"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($f_eq$(_s_0, "case"));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($f_eq$(_s_0, "do"));
  const _x_10 = (_x_8 || _x_9);
  const _x_11 = ($f_eq$(_s_0, "return"));
  const _x_12 = (_x_10 || _x_11);
  const _x_13 = ($f_eq$(_s_0, "for"));
  const _x_14 = (_x_12 || _x_13);
  const _x_15 = ($f_eq$(_s_0, "exs"));
  const _x_16 = (_x_14 || _x_15);
  const _x_17 = ($f_eq$(_s_0, "where"));
  const _x_18 = (_x_16 || _x_17);
  const _x_19 = ($f_eq$(_s_0, "is"));
  const _x_20 = (_x_18 || _x_19);
  const _x_21 = ($f_eq$(_s_0, "import"));
  const _x_22 = (_x_20 || _x_21);
  const _x_23 = ($f_eq$(_s_0, "Type"));
  const _x_24 = (_x_22 || _x_23);
  const _x_25 = ($f_eq$(_s_0, "Data"));
  const _x_26 = (_x_24 || _x_25);
  const _x_27 = ($f_eq$(_s_0, "Kind"));
  const _x_28 = (_x_26 || _x_27);
  const _x_29 = ($f_eq$(_s_0, "Quant"));
  return (_x_28 || _x_29);
}

function $f_law_clause$(_name_0, _exi_0, _ts_0, _book_0, _imports_0, _clauses_0) {
  const _x_0 = ($f_templates$(_clauses_0));
  const _x_1 = ($terms_len$(_clauses_0));
  return $f_choose$(($Bool$and$(($Bool$and$(($Bool$not$(_exi_0)), ($f_eq$(($f_tx$(_ts_0)), "~")))), (_x_0 < _x_1))), run_clo((_x_2) => {
  return $f_result$(_book_0, ($f_pn$(($fpe_error$(_ts_0, "expected a plain clause (only leading clauses take ~)", "a plain clause (only leading clauses take ~)")))), _imports_0);
}), run_clo((_x_3) => {
  return $f_law_type$(_name_0, ($kt$(run_loop($f_choose$(_exi_0, run_clo((_x_4) => {
  return "Exists";
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "~")), run_clo((_x_6) => {
  return "Template";
}), run_clo((_x_7) => {
  return "Bind";
}));
}))), ($f_tx$(run_loop($f_unmark$(_ts_0)))), ($f_atid$(_ts_0)), run_loop($f_quant$(_ts_0)), {$: "Nil"})), run_loop($f_expr$(($f_tl$(($f_tl$(run_loop($f_unmark$(_ts_0)))))), 0)), _book_0, _imports_0, _clauses_0);
}));
}

function $f_law_end$(_name_0, _p_0, _book_0, _imports_0, _clauses_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _ty_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_tops$(_ts_0, {$: "Con", "head": {$: "KDef", "name": _name_0, "kind": "Def", "arity": run_loop($f_law_arity$(_clauses_0)), "templates": ($f_templates$(_clauses_0)), "typ": run_loop($f_law_bind$(_clauses_0, _ty_0)), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": false, "unsafe": false}, "tail": _book_0}, _imports_0, false);
}));
}

function $f_expr$(_ts_0, _min_0) {
  return $f_grow$(run_loop($f_atom$(run_loop($f_skip$(_ts_0)))), _min_0);
}

function $f_def_prior$(_name_0, _p_0, _book_0, _imports_0, _unsafe_0, _old_0) {
  return $f_choose$(($f_eq$(($dk$(_old_0)), "Missing")), run_clo((_x_0) => {
  return $f_def_base$(_name_0, _p_0, _book_0, _imports_0, _unsafe_0);
}), run_clo((_x_1) => {
  const _x_2 = ($terms_len$(($ks$(($f_pn$(_p_0))))));
  const _x_3 = ($dx$(_old_0));
  return $f_choose$(($Bool$and$(($Bool$and$(($Bool$and$(($f_eq$(($dk$(_old_0)), "Def")), ($f_eq$(($tg$(($dv$(_old_0)))), "Absent")))), ($f_bare_params$(($ks$(($f_pn$(_p_0)))))))), (_x_2 >= _x_3))), run_clo((_x_4) => {
  return $f_choose$(($f_eq$(($f_tx$(($f_pr$(_p_0)))), ":")), run_clo((_x_5) => {
  return $f_def_base$(_name_0, _p_0, _book_0, _imports_0, _unsafe_0);
}), run_clo((_x_6) => {
  return $f_result$(_book_0, ($f_pn$(($f_err$(($f_pr$(_p_0)), "expected : (a definition filling a law has no return annotation)")))), _imports_0);
}));
}), run_clo((_x_7) => {
  return $f_result$(_book_0, ($kt$("Error", "a definition must uniquely fill its law with plain parameter names", 0, 0, {$: "Nil"})), _imports_0);
}));
}));
}

function $f_tele_at$(_ts_0, _end_0, _acc_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), _end_0)), run_clo((_x_0) => {
  return {$: "FParsed", "term": ($kt$("Tele", "", 0, 0, ($List$reverse$(_acc_0)))), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_1) => {
  return $f_validate_param$(_ts_0, _end_0, _acc_0);
}));
}

function $f_type_params$(_name_0, _p_0, _book_0, _imports_0) {
  const _pars_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_pars_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _pars_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_type_kind$(_name_0, ($ks$(_pars_0)), run_loop($f_expect$(run_loop($f_expr$(($f_pr$(run_loop($f_expect$({$: "FParsed", "term": _pars_0, "rest": _ts_0}, "is")))), 0)), ":")), _book_0, _imports_0);
}));
}

function $f_type_base$(_name_0, _ts_0, _book_0, _imports_0) {
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), "<"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), "<-"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_type_params$(_name_0, run_loop($f_tele$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), "<-")), run_clo((_x_3) => {
  const _x_4 = ($f_col$(_ts_0));
  return {$: "Con", "head": {$: "FToken", "text": "-", "f_line": ($f_line$(_ts_0)), "f_col": ((_x_4 + 1) >>> 0), "f_kind": 0}, "tail": ($f_tl$(_ts_0))};
}), run_clo((_x_5) => {
  return $f_tl$(_ts_0);
}))), ">", {$: "Nil"})), _book_0, _imports_0);
}), run_clo((_x_6) => {
  return $f_type_params$(_name_0, {$: "FParsed", "term": ($kt$("Tele", "", 0, 0, {$: "Nil"})), "rest": _ts_0}, _book_0, _imports_0);
}));
}

function $ffd_done$($0, $1, $2, $3, $4, $5) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      if (_book_0.$ === "Nil") {
        $0 = ($List$reverse$(_built_0));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 1; continue;
      } else {
        const _definition_0 = _book_0["head"];
        const _pending_0 = _book_0["tail"];
        $0 = _definition_0;
        $1 = _pending_0;
        $2 = _built_0;
        $3 = _stack_0;
        $4 = run_loop($f_fresh_term$(($dt$(_definition_0)), {$: "Nil"}, _next_0));
        $pc = 3; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFreshDefs", "defs": _book_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _book_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 2; continue;
      }
    }
    case 2: {
      const _frame_0 = $0;
      const _ctors_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      const _definition_0 = _frame_0["definition"];
      const _pending_0 = _frame_0["pending"];
      const _built_0 = _frame_0["built"];
      const _typ_0 = _frame_0["typ"];
      const _value_0 = _frame_0["value"];
      $0 = _pending_0;
      $1 = _next_0;
      $2 = {$: "Con", "head": {$: "KDef", "name": ($dn$(_definition_0)), "kind": ($dk$(_definition_0)), "arity": ($da$(_definition_0)), "templates": ($dx$(_definition_0)), "typ": _typ_0, "value": _value_0, "ctors": _ctors_0, "native": ($db$(_definition_0)), "unsafe": ($du$(_definition_0))}, "tail": _built_0};
      $3 = _stack_0;
      $pc = 0; continue;
    }
    case 3: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _result_0 = $4;
      const _typ_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = _definition_0;
      $1 = _pending_0;
      $2 = _built_0;
      $3 = _stack_0;
      $4 = _typ_0;
      $5 = run_loop($f_fresh_term$(($dv$(_definition_0)), {$: "Nil"}, _next_0));
      $pc = 4; continue;
    }
    case 4: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _typ_0 = $4;
      const _result_0 = $5;
      const _value_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = ($dc$(_definition_0));
      $1 = _next_0;
      $2 = {$: "Nil"};
      $3 = {$: "Con", "head": {$: "FFDefFrame", "definition": _definition_0, "pending": _pending_0, "built": _built_0, "typ": _typ_0, "value": _value_0}, "tail": _stack_0};
      $pc = 0; continue;
    }
  }
}

function $ffd_type$($0, $1, $2, $3, $4, $5) {
  let $pc = 3;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      if (_book_0.$ === "Nil") {
        $0 = ($List$reverse$(_built_0));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 1; continue;
      } else {
        const _definition_0 = _book_0["head"];
        const _pending_0 = _book_0["tail"];
        $0 = _definition_0;
        $1 = _pending_0;
        $2 = _built_0;
        $3 = _stack_0;
        $4 = run_loop($f_fresh_term$(($dt$(_definition_0)), {$: "Nil"}, _next_0));
        $pc = 3; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFreshDefs", "defs": _book_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _book_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 2; continue;
      }
    }
    case 2: {
      const _frame_0 = $0;
      const _ctors_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      const _definition_0 = _frame_0["definition"];
      const _pending_0 = _frame_0["pending"];
      const _built_0 = _frame_0["built"];
      const _typ_0 = _frame_0["typ"];
      const _value_0 = _frame_0["value"];
      $0 = _pending_0;
      $1 = _next_0;
      $2 = {$: "Con", "head": {$: "KDef", "name": ($dn$(_definition_0)), "kind": ($dk$(_definition_0)), "arity": ($da$(_definition_0)), "templates": ($dx$(_definition_0)), "typ": _typ_0, "value": _value_0, "ctors": _ctors_0, "native": ($db$(_definition_0)), "unsafe": ($du$(_definition_0))}, "tail": _built_0};
      $3 = _stack_0;
      $pc = 0; continue;
    }
    case 3: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _result_0 = $4;
      const _typ_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = _definition_0;
      $1 = _pending_0;
      $2 = _built_0;
      $3 = _stack_0;
      $4 = _typ_0;
      $5 = run_loop($f_fresh_term$(($dv$(_definition_0)), {$: "Nil"}, _next_0));
      $pc = 4; continue;
    }
    case 4: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _typ_0 = $4;
      const _result_0 = $5;
      const _value_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = ($dc$(_definition_0));
      $1 = _next_0;
      $2 = {$: "Nil"};
      $3 = {$: "Con", "head": {$: "FFDefFrame", "definition": _definition_0, "pending": _pending_0, "built": _built_0, "typ": _typ_0, "value": _value_0}, "tail": _stack_0};
      $pc = 0; continue;
    }
  }
}

function $f_fresh_term$(_t_0, _env_0, _next_0) {
  return $f_fresh_stack$(_t_0, _env_0, _next_0);
}

function $f_path_terms$(_ts_0, _dir_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": ($f_path_term$(_t_0, _dir_0)), "tail": ($f_path_terms$(_rest_0, _dir_0))};
  }
}

function $f_qual_defs$(_ds_0, _book_0, _ns_0, _imports_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return {$: "Con", "head": ($f_qual_def$(_d_0, _book_0, _ns_0, _imports_0)), "tail": ($f_qual_defs$(_rest_0, _book_0, _ns_0, _imports_0))};
  }
}

function $f_elab_def$(_d_0, _book_0) {
  const _name_0 = _d_0["name"];
  const _kind_0 = _d_0["kind"];
  const _arity_0 = _d_0["arity"];
  const _templates_0 = _d_0["templates"];
  const _ty_0 = _d_0["typ"];
  const _value_0 = _d_0["value"];
  const _ctors_0 = _d_0["ctors"];
  const _native_0 = _d_0["native"];
  const _unsafe_0 = _d_0["unsafe"];
  return {$: "KDef", "name": _name_0, "kind": _kind_0, "arity": _arity_0, "templates": _templates_0, "typ": run_loop($f_scope$(_ty_0, {$: "Nil"}, _book_0)), "value": run_loop($f_scope$(_value_0, {$: "Nil"}, _book_0)), "ctors": ($f_elab_defs$(_ctors_0, _book_0)), "native": _native_0, "unsafe": _unsafe_0};
}

function $core_nat_make$(_n_0) {
  return $kt$("LitNat", "", 0, _n_0, {$: "Nil"});
}

function $ka_app_spine_finish$(_e_0, _ctx_0, _arg_0, _r_0) {
  const _node_0 = _r_0["node"];
  const _ty_0 = _r_0["typ"];
  return $ka_app_spine_root$(_e_0, _ctx_0, _arg_0, _node_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)));
}

function $ka_spine$(_e_0, _ctx_0, _t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $ka_spine_finish$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), run_loop($ka_spine$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)))));
}), run_clo((_x_1) => {
  return {$: "KAnnotatedSpine", "node": _t_0, "typ": run_loop($ka_type$(_e_0, _ctx_0, _t_0))};
}));
}

function $ka_type_node$(_e_0, _ctx_0, _t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  return $kid$(run_loop($ctx_get$(_ctx_0, ($ix$(_t_0)))), 0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ref")), run_clo((_x_2) => {
  return $dt$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_t_0)))));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_4) => {
  return $kid$(_t_0, 1);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_6) => {
  return $ka_type_app$(_e_0, _t_0, run_loop($wnf$(($cb$(_e_0)), run_loop($ka_type$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)))))));
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "ADT")), run_clo((_x_8) => {
  return $tele_fill$(($cb$(_e_0)), ($dt$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_t_0)))))), ($ks$(_t_0)));
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Eql")), run_clo((_x_10) => {
  return $typ$(2);
}), run_clo((_x_11) => {
  const _x_12 = ($String$eq$(($tg$(_t_0)), "Qua"));
  const _x_13 = ($String$eq$(($tg$(_t_0)), "Min"));
  return $kc$((_x_12 || _x_13), run_clo((_x_14) => {
  return $atom$("Qnt");
}), run_clo((_x_15) => {
  const _x_16 = ($String$eq$(($tg$(_t_0)), "Typ"));
  const _x_17 = ($String$eq$(($tg$(_t_0)), "Qnt"));
  const _x_18 = (_x_16 || _x_17);
  const _x_19 = ($String$eq$(($tg$(_t_0)), "All"));
  return $kc$((_x_18 || _x_19), run_clo((_x_20) => {
  return $typ$(1);
}), run_clo((_x_21) => {
  return $atom$("Error");
}));
}));
}));
}));
}));
}));
}));
}));
}

function $ka_args_cached_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return $ka_args_after_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0, ($annotate$(_e_0, _ctx_0, _h_0, run_loop($kid$(_tel_0, 0)))));
}), run_clo((_x_1) => {
  return $ka_args_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0);
}));
}

function $tele_fill_head$(_book_0, _tel_0, _h_0, _rest_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return $tele_fill$(_book_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), _h_0)), _rest_0);
}), run_clo((_x_1) => {
  return $atom$("Error");
}));
}

function $ka_mat_ctr$(_e_0, _ctx_0, _t_0, _ty_0, _a_0, _c_0) {
  return $kt$("Mat", ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), {$: "Con", "head": ($annotate$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), run_loop($mat_goal$(($cb$(_e_0)), _ty_0, run_loop($tele_fill$(($cb$(_e_0)), ($dt$(_c_0)), ($ks$(_a_0)))), ($da$(_c_0)), ($nm$(_t_0)), {$: "Nil"})))), "tail": {$: "Con", "head": ($annotate$(_e_0, _ctx_0, run_loop($mat_rest$(($cb$(_e_0)), _t_0, _a_0)), ($all$(($qt$(_ty_0)), ($nm$(_ty_0)), ($ix$(_ty_0)), {$: "KTerm", "tag": ($tg$(_a_0)), "name": ($nm$(_a_0)), "id": ($ix$(_a_0)), "quant": ($qt$(_a_0)), "kids": ($ks$(_a_0)), "removed": {$: "Con", "head": ($nm$(_t_0)), "tail": ($rm$(_a_0))}}, run_loop($kid$(_ty_0, 1)))))), "tail": {$: "Nil"}}});
}

function $ka_let_head$(_e_0, _outer_0, _ctx_0, _h_0, _rest_0, _ty_0, _vty_0) {
  return {$: "Con", "head": ($kt$("Bind", ($nm$(_h_0)), ($ix$(_h_0)), ($qt$(_h_0)), {$: "Con", "head": ($annotate$(_e_0, _outer_0, run_loop($kid$(_h_0, 0)), _vty_0)), "tail": {$: "Nil"}})), "tail": run_loop($ka_let$(_e_0, _outer_0, ($ctx_bind$(_ctx_0, ($ix$(_h_0)), ($qt$(_h_0)), ($nm$(_h_0)), _vty_0)), ($subst_terms$(_rest_0, ($ix$(_h_0)), ($kt$("Var", ($nm$(_h_0)), ($ix$(_h_0)), 0, {$: "Con", "head": run_loop($kid$(_h_0, 0)), "tail": {$: "Nil"}})))), _ty_0))};
}

function $kapply$(_fn_0, _x_0) {
  return $kc$(($String$eq$(($tg$(run_loop($strip$(_fn_0)))), "Lam")), run_clo((_x_1) => {
  return $subst$(run_loop($kid$(run_loop($strip$(_fn_0)), 0)), ($ix$(run_loop($strip$(_fn_0)))), _x_0);
}), run_clo((_x_2) => {
  return $app$(_fn_0, _x_0);
}));
}

function $j_choice_match$(_t_0) {
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Mat")), ($String$eq$(($nm$(_t_0)), "True")))), ($j_choice_arm$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), true)))), ($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(_t_0, 1)))))), "Mat")))), ($String$eq$(($nm$(run_loop($j_strip$(run_loop($kid$(_t_0, 1)))))), "False")))), ($j_choice_arm$(run_loop($j_strip$(run_loop($kid$(run_loop($j_strip$(run_loop($kid$(_t_0, 1)))), 0)))), false)))), ($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(run_loop($j_strip$(run_loop($kid$(_t_0, 1)))), 1)))))), "Efq")));
}

function $j_choice_after_bool$(_book_0, _env_0, _args_0, _tail_0, _condition_0, _ty_0) {
  const _x_0 = ($j_choice_branch$(_book_0, _env_0, run_loop($j_strip$(run_loop($terms_at$(_args_0, 3)))), run_loop($wnf$(_book_0, run_loop($kid$(run_loop($wnf$(_book_0, run_loop($j_app_type$(_ty_0, run_loop($terms_at$(_args_0, 2)))))), 0)))), _tail_0));
  const _x_1 = (_x_0 + ")");
  const _x_2 = ($j_choice_branch$(_book_0, _env_0, run_loop($j_strip$(run_loop($terms_at$(_args_0, 2)))), run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0)))), _tail_0));
  const _x_3 = (":" + _x_1);
  const _x_4 = (_x_2 + _x_3);
  const _x_5 = ("?" + _x_4);
  const _x_6 = (_condition_0 + _x_5);
  return ("(/* choice */" + _x_6);
}

function $j_apply_args_head$(_book_0, _env_0, _args_0, _ty_0) {
  if (_args_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    const _x_0 = ($qt$(_ty_0));
    const _x_3 = ($j_apply_args$(_book_0, _env_0, _rest_0, run_loop($j_app_type$(_ty_0, _h_0))));
    const _x_4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return "null";
}), run_clo((_x_2) => {
  return $j_expr$(_book_0, _env_0, _h_0, run_loop($kid$(_ty_0, 0)), false);
})));
    const _x_5 = ("," + _x_3);
    return (_x_4 + _x_5);
  }
}

function $j_literal_ctor$(_t_0) {
  return $kc$(($String$eq$(($nm$(_t_0)), "U32")), run_clo((_x_0) => {
  return $j_word_text$(run_loop($j_word$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), 0, 0)), false);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "F32")), run_clo((_x_2) => {
  return $j_word_text$(run_loop($j_word$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), 0, 0)), true);
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "Chr")), run_clo((_x_4) => {
  return $j_char_text$(run_loop($j_u32$(run_loop($kid$(_t_0, 0)))));
}), run_clo((_x_5) => {
  const _x_6 = ($String$eq$(($nm$(_t_0)), "Zero"));
  const _x_7 = ($String$eq$(($nm$(_t_0)), "Succ"));
  return $kc$((_x_6 || _x_7), run_clo((_x_8) => {
  return $j_nat_text$(run_loop($j_nat$(_t_0, 0)));
}), run_clo((_x_9) => {
  const _x_10 = ($String$eq$(($nm$(_t_0)), "SNil"));
  const _x_11 = ($String$eq$(($nm$(_t_0)), "SCon"));
  return $kc$((_x_10 || _x_11), run_clo((_x_12) => {
  return $j_string_text$(run_loop($j_string$(_t_0, "")));
}), run_clo((_x_13) => {
  return "";
}));
}));
}));
}));
}));
}

function $norm_min_right$(_a_0, _b_0) {
  return $kc$(($String$eq$(($tg$(_b_0)), "Qua")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_b_0));
  return $kc$((_x_1 === 2), run_clo((_x_2) => {
  return _a_0;
}), run_clo((_x_3) => {
  const _x_4 = ($qt$(_b_0));
  return $kc$(($Bool$and$((_x_4 === 1), ($Bool$not$(($String$eq$(($tg$(_a_0)), "Qua")))))), run_clo((_x_5) => {
  return $kt$("Min", "", 0, 0, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}), run_clo((_x_6) => {
  return _b_0;
}));
}));
}), run_clo((_x_7) => {
  return $kt$("Min", "", 0, 0, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}));
}

function $norm_stuck$(_t_0, _x_0, _args_0, _left_0, _fallback_0) {
  return $kc$((_left_0 === 0), run_clo((_x_1) => {
  return $norm_apply$(($app$(_t_0, _x_0)), _args_0);
}), run_clo((_x_2) => {
  return _fallback_0;
}));
}

function $kp_float_show$(_n_0) {
  const _x_0 = ($kp_float$(_n_0));
  return $kp_float_text$(f32_show(_x_0));
}

function $kp_ctor_other$(_t_0, _p_0, _env_0) {
  const _x_0 = ($kp_eq$(($nm$(_t_0)), "Succ"));
  const _x_1 = ($kp_eq$(($nm$(_t_0)), "Zero"));
  return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return $kp_nat$(_t_0, 0, _p_0, _env_0);
}), run_clo((_x_3) => {
  return $kp_ctor_char$(run_loop($kp_char$(_t_0, 39)), _t_0, _p_0, _env_0);
}));
}

function $kp_word$(_t_0, _bit_0, _left_0, _acc_0) {
  return $kc$((_left_0 === 0), run_clo((_x_0) => {
  return $kc$(($kp_is$(_t_0, "Ctr", "WNil")), run_clo((_x_1) => {
  return {$: "Some", "value": _acc_0};
}), run_clo((_x_2) => {
  return {$: "None"};
}));
}), run_clo((_x_3) => {
  const _x_4 = ($terms_len$(($ks$(_t_0))));
  const _x_5 = ($kp_is$(run_loop($kid$(_t_0, 0)), "Ctr", "True"));
  const _x_6 = ($kp_is$(run_loop($kid$(_t_0, 0)), "Ctr", "False"));
  return $kc$(($Bool$and$(($Bool$and$(($kp_is$(_t_0, "Ctr", "WCon")), (_x_4 === 2))), (_x_5 || _x_6))), run_clo((_x_7) => {
  return $kp_word$(run_loop($kid$(_t_0, 1)), ((_bit_0 << 1) >>> 0), ((_left_0 - 1) >>> 0), run_loop($kc$(($kp_is$(run_loop($kid$(_t_0, 0)), "Ctr", "True")), run_clo((_x_8) => {
  return ((_acc_0 | _bit_0) >>> 0);
}), run_clo((_x_9) => {
  return _acc_0;
}))));
}), run_clo((_x_10) => {
  return {$: "None"};
}));
}));
}

function $kp_rewrite_motive$(_e_0, _m_0, _env_0) {
  return $kc$(($Bool$and$(($kp_eq$(($tg$(_m_0)), "Lam")), ($kp_eq$(($tg$(run_loop($kid$(_m_0, 0)))), "Lam")))), run_clo((_x_0) => {
  const _x_4 = run_loop($kp_go$(run_loop($kid$(run_loop($kid$(_m_0, 0)), 0)), 2, ($kp_bind$(($kp_bind$(_env_0, _m_0)), run_loop($kid$(_m_0, 0))))));
  const _x_5 = run_loop($kp_go$(_e_0, 2, _env_0));
  const _x_6 = (" : " + _x_4);
  const _x_7 = run_loop($kc$(($kp_eq$(($nm$(run_loop($kid$(_m_0, 0)))), "")), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  const _x_3 = ($nm$(run_loop($kid$(_m_0, 0))));
  return (_x_3 + "@");
})));
  const _x_8 = (_x_5 + _x_6);
  return (_x_7 + _x_8);
}), run_clo((_x_9) => {
  const _x_10 = run_loop($kp_go$(_m_0, 2, _env_0));
  const _x_11 = run_loop($kp_go$(_e_0, 2, _env_0));
  const _x_12 = (" : " + _x_10);
  return (_x_11 + _x_12);
}));
}

function $kp_let_names$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($terms_len$(_rest_0));
    return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  const _x_3 = ($terms_len$(_rest_0));
  const _x_7 = ($nm$(_h_0));
  const _x_8 = run_loop($kc$((_x_3 === 1), run_clo((_x_4) => {
  return "";
}), run_clo((_x_5) => {
  const _x_6 = run_loop($kp_let_names$(_rest_0));
  return (" " + _x_6);
})));
  const _x_9 = run_loop($kp_quant$(($qt$(_h_0))));
  const _x_10 = (_x_7 + _x_8);
  return (_x_9 + _x_10);
}));
  }
}

function $kp_let_vals$(_ts_0, _env_0) {
  if (_ts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($terms_len$(_rest_0));
    return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  const _x_3 = ($terms_len$(_rest_0));
  const _x_7 = run_loop($kp_go$(run_loop($kid$(_h_0, 0)), 2, _env_0));
  const _x_8 = run_loop($kc$((_x_3 === 1), run_clo((_x_4) => {
  return "";
}), run_clo((_x_5) => {
  const _x_6 = run_loop($kp_let_vals$(_rest_0, _env_0));
  return (" " + _x_6);
})));
  return (_x_7 + _x_8);
}));
  }
}

function $kp_let_body$(_ts_0, _env_0) {
  if (_ts_0.$ === "Nil") {
    return "<missing let body>";
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($terms_len$(_rest_0));
    return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return $kp_go$(_h_0, 0, _env_0);
}), run_clo((_x_2) => {
  return $kp_let_body$(_rest_0, ($kp_bind$(_env_0, _h_0)));
}));
  }
}

function $g_term$(_r_0) {
  const _term_0 = _r_0["term"];
  return _term_0;
}

function $g_snf_open$(_book_0, _st_0, _t_0, _stack_0, _fresh_0) {
  return $g_snf_children$(_book_0, _st_0, _t_0, {$: "Nil"}, ($ks$(_t_0)), _stack_0, _fresh_0);
}

function $g_state$(_r_0) {
  const _state_0 = _r_0["state"];
  return _state_0;
}

function $norm_rebind$(_t_0, _fresh_0) {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": _fresh_0, "quant": ($qt$(_t_0)), "kids": run_loop($kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_0) => {
  return {$: "Con", "head": run_loop($subst$(run_loop($kid$(_t_0, 0)), ($ix$(_t_0)), ($var$(($nm$(_t_0)), _fresh_0)))), "tail": {$: "Nil"}};
}), run_clo((_x_1) => {
  return {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Con", "head": run_loop($subst$(run_loop($kid$(_t_0, 1)), ($ix$(_t_0)), ($var$(($nm$(_t_0)), _fresh_0)))), "tail": {$: "Nil"}}};
}))), "removed": ($rm$(_t_0))};
}

function $g_eval$(_book_0, _st_0, _t_0, _args_0, _pending_0, _fallback_0, _stack_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "GCell")), run_clo((_x_0) => {
  return $g_cell$(_book_0, _st_0, _t_0, _args_0, _pending_0, _fallback_0, _stack_0, run_loop($g_get$(($g_heap$(_st_0)), ($ix$(_t_0)))));
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_2) => {
  return $g_app$(_book_0, run_loop($kid$(_t_0, 0)), _args_0, _pending_0, _fallback_0, _stack_0, run_loop($g_share$(_st_0, run_loop($kid$(_t_0, 1)))));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_4) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_t_0, 0)), _args_0, _pending_0, _fallback_0, _stack_0);
}), run_clo((_x_5) => {
  const _x_6 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Var")), (_x_6 > 0))), run_clo((_x_7) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_t_0, 0)), _args_0, _pending_0, _fallback_0, _stack_0);
}), run_clo((_x_8) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Let")), run_clo((_x_9) => {
  return $g_let$(_book_0, _st_0, ($ks$(_t_0)), {$: "Nil"}, _args_0, _pending_0, _fallback_0, _stack_0);
}), run_clo((_x_10) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ref")), run_clo((_x_11) => {
  return $g_ref$(_book_0, _st_0, _t_0, _args_0, _stack_0, run_loop($lookup$(_book_0, ($nm$(_t_0)))));
}), run_clo((_x_12) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Min")), run_clo((_x_13) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_t_0, 0)), {$: "Nil"}, 0, ($atom$("Absent")), {$: "Con", "head": {$: "GMinA", "other": run_loop($kid$(_t_0, 1)), "args": _args_0}, "tail": _stack_0});
}), run_clo((_x_14) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_15) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_t_0, 0)), {$: "Nil"}, 0, ($atom$("Absent")), {$: "Con", "head": {$: "GRewrite", "original": _t_0, "args": _args_0, "pending": _pending_0, "fallback": _fallback_0}, "tail": _stack_0});
}), run_clo((_x_16) => {
  return $g_args$(_book_0, _st_0, _t_0, _args_0, _pending_0, _fallback_0, _stack_0);
}));
}));
}));
}));
}));
}));
}));
}));
}

function $sp_template$(_st_0, _d_0, _xs_0, _ctx_0, _owner_0, _depth_0) {
  const _x_0 = ($terms_len$(_xs_0));
  const _x_1 = ($dx$(_d_0));
  return $kc$((_x_0 < _x_1), run_clo((_x_2) => {
  return {$: "KSpecTerm", "state": ($sp_fail$(_st_0, "template requires all closed comptime arguments")), "term": ($norm_apply$(($ref$(($dn$(_d_0)))), _xs_0))};
}), run_clo((_x_3) => {
  return $sp_template_args$(_st_0, _d_0, run_loop($sp_take$(_xs_0, ($dx$(_d_0)))), run_loop($sp_drop$(_xs_0, ($dx$(_d_0)))), _ctx_0, _owner_0, _depth_0);
}));
}

function $sp_regular_head$(_st_0, _head_0, _xs_0, _ctx_0, _owner_0, _depth_0) {
  return $sp_regular_done$(_xs_0, _ctx_0, _owner_0, _depth_0, ($sp_type$(_st_0, _head_0, _ctx_0, _owner_0)), run_loop($kc$(($String$eq$(($tg$(_head_0)), "Ref")), run_clo((_x_0) => {
  return {$: "KSpecTerm", "state": _st_0, "term": _head_0};
}), run_clo((_x_1) => {
  return $sp_term$(_st_0, _head_0, _ctx_0, ($sp_type$(_st_0, _head_0, _ctx_0, _owner_0)), _owner_0, _depth_0);
}))));
}

function $core_force$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $core_force$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  const _x_2 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Var")), (_x_2 > 0))), run_clo((_x_3) => {
  return $core_force$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_4) => {
  return _t_0;
}));
}));
}

function $sp_match_ctor$(_st_0, _t_0, _ctx_0, _goal_0, _owner_0, _depth_0, _a_0, _ctr_0) {
  return $sp_match_hit$(_t_0, _ctx_0, _goal_0, _owner_0, _depth_0, _a_0, run_loop($sp_term$(_st_0, run_loop($kid$(_t_0, 0)), _ctx_0, run_loop($mat_goal$(($sp_book$(_st_0)), _goal_0, run_loop($tele_fill$(($sp_book$(_st_0)), ($dt$(_ctr_0)), ($ks$(_a_0)))), ($da$(_ctr_0)), ($nm$(_t_0)), {$: "Nil"})), _owner_0, _depth_0)));
}

function $sp_states$(_r_0) {
  const _state_0 = _r_0["state"];
  return _state_0;
}

function $sp_values$(_r_0) {
  const _terms_0 = _r_0["terms"];
  return _terms_0;
}

function $sp_arg_head$(_st_0, _x_0, _rest_0, _ctx_0, _ty_0, _owner_0, _depth_0) {
  const _x_1 = ($qt$(_ty_0));
  return $sp_arg_done$(_x_0, _rest_0, _ctx_0, _ty_0, _owner_0, _depth_0, run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "All")), (_x_1 === 0))), run_clo((_x_2) => {
  return {$: "KSpecTerm", "state": _st_0, "term": _x_0};
}), run_clo((_x_3) => {
  return $sp_term$(_st_0, _x_0, _ctx_0, run_loop($kid$(_ty_0, 0)), _owner_0, _depth_0);
}))));
}

function $sp_let_bound$(_h_0, _rest_0, _outer_0, _ctx_0, _goal_0, _owner_0, _depth_0, _ty_0, _r_0) {
  return $sp_cons$({$: "KTerm", "tag": ($tg$(_h_0)), "name": ($nm$(_h_0)), "id": ($ix$(_h_0)), "quant": ($qt$(_h_0)), "kids": {$: "Con", "head": ($sp_value$(_r_0)), "tail": {$: "Nil"}}, "removed": ($rm$(_h_0))}, run_loop($sp_let$(($sp_state$(_r_0)), _rest_0, _outer_0, ($ctx_bind$(_ctx_0, ($ix$(_h_0)), ($qt$(_h_0)), ($nm$(_h_0)), _ty_0)), _goal_0, _owner_0, _depth_0)));
}

function $cy$(_r_0) {
  const _typ_0 = _r_0["typ"];
  return _typ_0;
}

function $infer$(_e_0, _ctx_0, _t_0, _dem_0, _sp_0) {
  return $dg_trace$(_e_0, _ctx_0, _t_0, ($atom$("Absent")), run_loop($infer_node$(_e_0, _ctx_0, run_loop($core_beta$(_t_0)), _dem_0, _sp_0)));
}

function $sp_rewrite_done$(_t_0, _r_0) {
  return {$: "KSpecTerm", "state": ($sp_state$(_r_0)), "term": {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Con", "head": ($sp_value$(_r_0)), "tail": {$: "Nil"}}}}, "removed": ($rm$(_t_0))}};
}

function $nv_id$(_name_0) {
  return {$: "KDef", "name": _name_0, "kind": "NativeId", "arity": 0, "templates": 0, "typ": ($atom$("Absent")), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": false, "unsafe": false};
}

function $nt_replace_go$(_s_0, _key_0, _value_0, _acc_0) {
  return $nt_choose$(($String$starts_with$(_s_0, _key_0)), run_clo((_x_0) => {
  const _x_1 = ($String$drop$(_s_0, [..._key_0].length));
  const _x_2 = (_value_0 + _x_1);
  return (_acc_0 + _x_2);
}), run_clo((_x_3) => {
  return $nt_replace_step$(_s_0, _key_0, _value_0, _acc_0);
}));
}

function $nb_seg_ids_go$($0, $1, $2) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _i_0 = $1;
      const _acc_0 = $2;
      if (_ss_0.$ === "Nil") {
        const _x_0 = ($U32$show$(((_i_0 + 3) >>> 0)));
        const _x_1 = (_x_0 + "\n");
        const _x_2 = ($U32$show$(((_i_0 + 2) >>> 0)));
        const _x_3 = ("\n#define FID_ENTER " + _x_1);
        const _x_4 = (_x_2 + _x_3);
        const _x_5 = ($U32$show$(((_i_0 + 1) >>> 0)));
        const _x_6 = ("\n#define FID_EXIT " + _x_4);
        const _x_7 = (_x_5 + _x_6);
        const _x_8 = ($U32$show$(_i_0));
        const _x_9 = ("\n#define BEND_CLO_APPLY " + _x_7);
        const _x_10 = (_x_8 + _x_9);
        const _x_11 = ("#define FID_IO_EMIT " + _x_10);
        return (_acc_0 + _x_11);
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _t_1 = _ss_0["tail"];
        const _x_12 = ($U32$show$(_i_0));
        const _x_13 = (_x_12 + "\n");
        const _x_14 = ($nt_fid$(_k_0));
        const _x_15 = (" " + _x_13);
        const _x_16 = (_x_14 + _x_15);
        const _x_17 = ("#define " + _x_16);
        $0 = _t_1;
        $1 = ((_i_0 + 1) >>> 0);
        $2 = (_acc_0 + _x_17);
        continue;
      }
    }
  }
}

function $nb_width$(_ss_0) {
  return $nb_width_go$(_ss_0, 2);
}

function $nb_returns$(_ss_0) {
  return $nb_returns_go$(_ss_0, 1);
}

function $nb_regs$(_n_0, _i_0) {
  if (_n_0 == 0) {
    return {$: "Nil"};
  } else {
    const _10_0 = u32_to_word(_n_0)["head"];
    const _11_0 = u32_to_word(_n_0)["tail"];
    const _x_0 = ($U32$show$(_i_0));
    const _x_1 = word_to_u32({$: "WCon", "head": _10_0, "tail": _11_0});
    return {$: "Con", "head": ("r" + _x_0), "tail": ($nb_regs$(((_x_1 - 1) >>> 0), ((_i_0 + 1) >>> 0)))};
  }
}

function $nb_pad$(_rs_0, _i_0) {
  if (_rs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _rs_0["head"];
    const _t_0 = _rs_0["tail"];
    return $nt_choose$((_i_0 === 6), run_clo((_x_0) => {
  return {$: "Con", "head": "rp", "tail": {$: "Con", "head": _h_0, "tail": _t_0}};
}), run_clo((_x_1) => {
  return {$: "Con", "head": _h_0, "tail": run_loop($nb_pad$(_t_0, ((_i_0 + 1) >>> 0)))};
}));
  }
}

function $nb_bangs$(_ss_0) {
  return $nb_bangs_go$(_ss_0, 0);
}

function $nb_load$(_rs_0, _i_0) {
  if (_rs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _rs_0["head"];
    const _t_0 = _rs_0["tail"];
    const _x_0 = ($nb_load$(_t_0, ((_i_0 + 1) >>> 0)));
    const _x_1 = ($U32$show$(_i_0));
    const _x_2 = ("]; \\\n" + _x_0);
    const _x_3 = (_x_1 + _x_2);
    const _x_4 = (" = e.mem[(A) + " + _x_3);
    const _x_5 = (_h_0 + _x_4);
    const _x_6 = ($U32$show$(_i_0));
    const _x_7 = (") break; " + _x_5);
    const _x_8 = (_x_6 + _x_7);
    return ("    if ((N) <= " + _x_8);
  }
}

function $nb_last$(_rs_0, _i_0) {
  if (_rs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _rs_0["head"];
    const _t_0 = _rs_0["tail"];
    const _x_0 = ($nb_last$(_t_0, ((_i_0 + 1) >>> 0)));
    const _x_1 = (" = (X); break; \\\n" + _x_0);
    const _x_2 = (_h_0 + _x_1);
    const _x_3 = ($U32$show$(_i_0));
    const _x_4 = (": " + _x_2);
    const _x_5 = (_x_3 + _x_4);
    return ("    case " + _x_5);
  }
}

function $nb_save$(_rs_0, _i_0) {
  if (_rs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _rs_0["head"];
    const _t_0 = _rs_0["tail"];
    const _x_0 = ($nb_save$(_t_0, ((_i_0 + 1) >>> 0)));
    const _x_1 = ("; " + _x_0);
    const _x_2 = (_h_0 + _x_1);
    const _x_3 = ($U32$show$(_i_0));
    const _x_4 = ("] = " + _x_2);
    const _x_5 = (_x_3 + _x_4);
    return ("(V)[" + _x_5);
  }
}

function $nb_take$(_rs_0, _i_0) {
  if (_rs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _rs_0["head"];
    const _t_0 = _rs_0["tail"];
    const _x_0 = ($nb_take$(_t_0, ((_i_0 + 1) >>> 0)));
    const _x_1 = ($U32$show$(_i_0));
    const _x_2 = ("]; " + _x_0);
    const _x_3 = (_x_1 + _x_2);
    const _x_4 = (" = (V)[" + _x_3);
    return (_h_0 + _x_4);
  }
}

function $nb_typed$(_rs_0) {
  if (_rs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _rs_0["head"];
    const _t_0 = _rs_0["tail"];
    return {$: "Con", "head": ("Term " + _h_0), "tail": ($nb_typed$(_t_0))};
  }
}

function $nb_arities_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return (_acc_0 + "1, 2");
      } else {
        const _t_0 = _ss_0["head"];
        const _ps_0 = _t_0["params"];
        const _t_1 = _ss_0["tail"];
        const _x_0 = ($U32$show$(($nt_count$(_ps_0))));
        const _x_1 = (_x_0 + ", ");
        $0 = _t_1;
        $1 = (_acc_0 + _x_1);
        continue;
      }
    }
  }
}

function $nb_flags_go$($0, $1, $2) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _forks_0 = $1;
      const _acc_0 = $2;
      if (_ss_0.$ === "Nil") {
        return (_acc_0 + "2, 0");
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _fork_0 = _t_0["fork"];
        const _bang_0 = _t_0["bang"];
        const _t_1 = _ss_0["tail"];
        const _x_2 = ($nt_bool$(run_loop($nt_choose$(_fork_0, run_clo((_x_0) => {
  return false;
}), run_clo((_x_1) => {
  return $Bool$not$(($nb_contains$(_forks_0, _k_0)));
})))));
        const _x_3 = ($nt_bool$(_bang_0));
        const _x_4 = (Math.imul(2, _x_2) >>> 0);
        const _x_5 = ($U32$show$(((_x_3 + _x_4) >>> 0)));
        const _x_6 = (_x_5 + ", ");
        $0 = _t_1;
        $1 = _forks_0;
        $2 = (_acc_0 + _x_6);
        continue;
      }
    }
  }
}

function $nb_fork_next$(_ss_0, _roots_0, _next_0, _fuel_0) {
  const _x_0 = ($nt_count$(_roots_0));
  const _x_1 = ($nt_count$(_next_0));
  return $nt_choose$((_x_0 === _x_1), run_clo((_x_2) => {
  return _next_0;
}), run_clo((_x_3) => {
  return $nb_fork_close$(_ss_0, _next_0, _fuel_0);
}));
}

function $nb_fork_step$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _roots_0 = $1;
      if (_ss_0.$ === "Nil") {
        return _roots_0;
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _refs_0 = _t_0["refs"];
        const _fork_0 = _t_0["fork"];
        const _t_1 = _ss_0["tail"];
        $0 = _t_1;
        $1 = run_loop($nt_choose$(_fork_0, run_clo((_x_0) => {
  return _roots_0;
}), run_clo((_x_1) => {
  return $nt_choose$(($Bool$and$(($Bool$not$(($nb_contains$(_roots_0, _k_0)))), ($nb_reaches$(_refs_0, _roots_0)))), run_clo((_x_2) => {
  return {$: "Con", "head": _k_0, "tail": _roots_0};
}), run_clo((_x_3) => {
  return _roots_0;
}));
})));
        continue;
      }
    }
  }
}

function $nb_fork_roots_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _fork_0 = _t_0["fork"];
        const _t_1 = _ss_0["tail"];
        $0 = _t_1;
        $1 = run_loop($nt_choose$(_fork_0, run_clo((_x_0) => {
  return {$: "Con", "head": _k_0, "tail": _acc_0};
}), run_clo((_x_1) => {
  return _acc_0;
})));
        continue;
      }
    }
  }
}

function $nb_result_words_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return (_acc_0 + "0, 0");
      } else {
        const _t_0 = _ss_0["head"];
        const _ps_0 = _t_0["params"];
        const _f_0 = _t_0["frame"];
        const _t_1 = _ss_0["tail"];
        const _x_0 = ($U32$show$(($nb_frame_results$(_f_0, ($nt_count$(_ps_0))))));
        const _x_1 = (_x_0 + ", ");
        $0 = _t_1;
        $1 = (_acc_0 + _x_1);
        continue;
      }
    }
  }
}

function $nb_dispatch_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return (_acc_0 + "WL_X(FID_IO_EMIT) WL_X(BEND_CLO_APPLY) WL_X(FID_EXIT)");
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _t_1 = _ss_0["tail"];
        const _x_0 = ($nt_fid$(_k_0));
        const _x_1 = (_x_0 + ") ");
        const _x_2 = ("WL_X(" + _x_1);
        $0 = _t_1;
        $1 = (_acc_0 + _x_2);
        continue;
      }
    }
  }
}

function $ne_segment$(_seg_0) {
  const _k_0 = _seg_0["name"];
  const _ps_0 = _seg_0["params"];
  const _f_0 = _seg_0["frame"];
  const _body_0 = _seg_0["body"];
  const _host_0 = _seg_0["host"];
  const _spin_0 = _seg_0["spin"];
  const _x_8 = run_loop($nt_choose$(_host_0, run_clo((_x_6) => {
  return "#endif\n";
}), run_clo((_x_7) => {
  return "";
})));
  const _x_9 = run_loop($nt_choose$(_spin_0, run_clo((_x_4) => {
  return "    WL_SPUN\n";
}), run_clo((_x_5) => {
  return "";
})));
  const _x_10 = ("  }}\n" + _x_8);
  const _x_11 = (_x_9 + _x_10);
  const _x_12 = ($nt_indent$(_body_0));
  const _x_13 = ("\n" + _x_11);
  const _x_14 = run_loop($nt_choose$(_spin_0, run_clo((_x_2) => {
  return "    WL_SPIN\n";
}), run_clo((_x_3) => {
  return "";
})));
  const _x_15 = (_x_12 + _x_13);
  const _x_16 = (_x_14 + _x_15);
  const _x_17 = ($ne_take$(_ps_0, _f_0));
  const _x_18 = ("    WL_OPEN\n" + _x_16);
  const _x_19 = (_x_17 + _x_18);
  const _x_20 = ($nt_fid$(_k_0));
  const _x_21 = (")\n  {\n" + _x_19);
  const _x_22 = (_x_20 + _x_21);
  const _x_23 = run_loop($nt_choose$(_host_0, run_clo((_x_0) => {
  return "#if !DEVICE\n";
}), run_clo((_x_1) => {
  return "";
})));
  const _x_24 = ("  WL_CASE(" + _x_22);
  return (_x_23 + _x_24);
}

function $nc_show_find$(_book_0, _ty_0, _types_0, _i_0) {
  if (_types_0.$ === "Nil") {
    return 4294967295;
  } else {
    const _h_0 = _types_0["head"];
    const _rest_0 = _types_0["tail"];
    return $nt_choose$(run_loop($norm_compare$(_book_0, _ty_0, _h_0, false, 4000000000)), run_clo((_x_0) => {
  return _i_0;
}), run_clo((_x_1) => {
  return $nc_show_find$(_book_0, _ty_0, _rest_0, ((_i_0 + 1) >>> 0));
}));
  }
}

function $nc_show_arms$(_book_0, _cs_0, _args_0, _types_0) {
  if (_cs_0.$ === "Nil") {
    return {$: "NC_Desc", "cells": {$: "Nil"}, "types": _types_0, "error": ""};
  } else {
    const _c_0 = _cs_0["head"];
    const _rest_0 = _cs_0["tail"];
    return $nc_show_arm$(_book_0, _c_0, _rest_0, _args_0, run_loop($nc_show_fields$(_book_0, ($nc_tele_fill$(_book_0, ($dt$(_c_0)), _args_0)), ($da$(_c_0)), 0, _types_0)));
  }
}

function $nc_occurs_list$(_ts_0, _id_0) {
  if (_ts_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ts_0["head"];
    const _t_0 = _ts_0["tail"];
    const _x_0 = run_loop($nc_occurs$(_h_0, _id_0));
    const _x_1 = ($nc_occurs_list$(_t_0, _id_0));
    return (_x_0 || _x_1);
  }
}

function $ne_ret$(_ws_0) {
  const _x_0 = ($U32$show$(($nt_count$(_ws_0))));
  const _x_1 = (_x_0 + ");\n");
  const _x_2 = ($ne_registers$(_ws_0, 0));
  const _x_3 = ("WL_RETN(" + _x_1);
  return (_x_2 + _x_3);
}

function $ne_registers$(_ws_0, _i_0) {
  if (_ws_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ws_0["head"];
    const _t_0 = _ws_0["tail"];
    const _x_0 = ($ne_registers$(_t_0, ((_i_0 + 1) >>> 0)));
    const _x_1 = (";\n" + _x_0);
    const _x_2 = (_h_0 + _x_1);
    const _x_3 = ($U32$show$(_i_0));
    const _x_4 = (" = " + _x_2);
    const _x_5 = (_x_3 + _x_4);
    return ("r" + _x_5);
  }
}

function $nc_name$(_n_0) {
  const _x_0 = ($U32$show$(_n_0));
  return ("native_k_" + _x_0);
}

function $nc_closure_result$(_s_0, _body_0, _emitted_0) {
  const _code_0 = _emitted_0["code"];
  const _word_0 = _emitted_0["value"];
  const _fresh_0 = _emitted_0["fresh"];
  const _x_0 = ($ne_ret$({$: "Con", "head": _word_0, "tail": {$: "Nil"}}));
  return {$: "NC_Code", "body": (_code_0 + _x_0), "segments": {$: "Con", "head": _s_0, "tail": ($nc_segs$(_body_0))}, "fresh": _fresh_0, "error": ($nc_error$(_body_0))};
}

function $ne_closure$(_k_0, _ws_0, _n_0) {
  if (_ws_0.$ === "Nil") {
    const _x_0 = ($nt_fid$(_k_0));
    const _x_1 = (_x_0 + ", 0)");
    return {$: "N_Emitted", "code": "", "value": ("term_clo(" + _x_1), "fresh": _n_0};
  } else {
    const _h_0 = _ws_0["head"];
    const _t_0 = _ws_0["tail"];
    const _x_2 = ($U32$show$(($nt_count$({$: "Con", "head": _h_0, "tail": _t_0}))));
    const _x_3 = (_x_2 + "))");
    return $ne_closure_wrap$(_k_0, ($ne_node$("cl", ("heap_alloc(e, cls_fit(" + _x_3), {$: "Con", "head": _h_0, "tail": _t_0}, _n_0, false)));
  }
}

function $nc_words$(_env_0) {
  if (_env_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _env_0["head"];
    const _word_0 = _t_0["word"];
    const _rest_0 = _env_0["tail"];
    return {$: "Con", "head": _word_0, "tail": ($nc_words$(_rest_0))};
  }
}

function $nd_head$(_t_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $nd_head$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $nd_args$(_t_0, _acc_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $nd_args$(run_loop($kid$(_t_0, 0)), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _acc_0});
}), run_clo((_x_1) => {
  return _acc_0;
}));
}

function $nd_beta$(_head_0, _args_0) {
  if (_args_0.$ === "Nil") {
    return _head_0;
  } else {
    const _arg_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return $nt_choose$(($String$eq$(($tg$(_head_0)), "Lam")), run_clo((_x_0) => {
  return $nt_choose$(($String$eq$(($tg$(_arg_0)), "Var")), run_clo((_x_1) => {
  return $nd_beta$(run_loop($subst$(run_loop($kid$(_head_0, 0)), ($ix$(_head_0)), _arg_0)), _rest_0);
}), run_clo((_x_2) => {
  return $nc_mklet$(($ix$(_head_0)), _arg_0, run_loop($nd_beta$(run_loop($kid$(_head_0, 0)), _rest_0)));
}));
}), run_clo((_x_3) => {
  return $nd_reapply$(_head_0, {$: "Con", "head": _arg_0, "tail": _rest_0});
}));
  }
}

function $nd_match$(_book_0, _head_0, _arg_0, _env_0, _n_0) {
  return $nt_choose$(($String$eq$(($tg$(_arg_0)), "Var")), run_clo((_x_0) => {
  return $nc_lower$(_book_0, ($kt$("NMatch", "", 0, 0, {$: "Con", "head": _head_0, "tail": {$: "Con", "head": _arg_0, "tail": {$: "Nil"}}})), _env_0, _n_0);
}), run_clo((_x_1) => {
  return $nc_lower$(_book_0, ($nc_mklet$(($nc_id$(_n_0)), _arg_0, ($kt$("NMatch", "", 0, 0, {$: "Con", "head": _head_0, "tail": {$: "Con", "head": ($var$("", ($nc_id$(_n_0)))), "tail": {$: "Nil"}}})))), _env_0, ((_n_0 + 1) >>> 0));
}));
}

function $nd_arity$(_book_0, _name_0) {
  const _d_0 = run_loop($lookup$(_book_0, _name_0));
  return $nt_choose$(($nc_native_def$(_d_0)), run_clo((_x_0) => {
  return $nc_primitive_arity$(($nc_primitive_name$(_name_0)));
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($tg$(run_loop($nc_unann$(($dv$(_d_0)))))), "Foreign")), run_clo((_x_2) => {
  return $nd_foreign_arity$(_book_0, ($dt$(_d_0)), 0);
}), run_clo((_x_3) => {
  return $nd_leading$(($dv$(_d_0)), 0);
}));
}));
}

function $nc_sequence$(_tag_0, _name_0, _xs_0, _acc_0, _n_0) {
  if (_xs_0.$ === "Nil") {
    return $kt$(_tag_0, _name_0, 0, 0, ($List$reverse$(_acc_0)));
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    return $nc_mklet$(($nc_id$(_n_0)), _h_0, ($nc_sequence$(_tag_0, _name_0, _t_0, {$: "Con", "head": ($var$("", ($nc_id$(_n_0)))), "tail": _acc_0}, ((_n_0 + 1) >>> 0))));
  }
}

function $nc_app_slow$(_book_0, _t_0, _env_0, _n_0) {
  const _f_0 = ($nc_id$(_n_0));
  const _a_0 = ($nc_id$(((_n_0 + 1) >>> 0)));
  return $nc_lower$(_book_0, ($nc_mklet$(_f_0, run_loop($kid$(_t_0, 0)), ($nc_mklet$(_a_0, run_loop($kid$(_t_0, 1)), ($kt$("NApply", "", 0, 0, {$: "Con", "head": ($var$("", _f_0)), "tail": {$: "Con", "head": ($var$("", _a_0)), "tail": {$: "Nil"}}})))))), _env_0, ((_n_0 + 2) >>> 0));
}

function $nc_last_term$($0) {
  for (;;) {
    {
      const _xs_0 = $0;
      if (_xs_0.$ === "Nil") {
        return $atom$("Absent");
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        if (_t_0.$ === "Nil") {
          return _h_0;
        } else {
          $0 = _t_0;
          continue;
        }
      }
    }
  }
}

function $nc_parallel_binds$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return {$: "Nil"};
    } else {
      return {$: "Con", "head": ($nc_binding$(($ix$(_h_0)))), "tail": ($nc_parallel_binds$(_t_0))};
    }
  }
}

function $ne_task$(_k_0, _rem_0, _ws_0, _cont_0, _idx_0, _n_0) {
  const _x_0 = ($U32$show$(_rem_0));
  const _x_1 = (_x_0 + ")");
  const _x_2 = (", " + _x_1);
  const _x_3 = (_idx_0 + _x_2);
  const _x_4 = (", " + _x_3);
  const _x_5 = (_cont_0 + _x_4);
  const _x_6 = ($nt_fid$(_k_0));
  const _x_7 = (", " + _x_5);
  const _x_8 = (_x_6 + _x_7);
  return $ne_node$("task", ("task_node(e, " + _x_8), _ws_0, _n_0, false);
}

function $nc_parallel_task$(_book_0, _xs_0, _env_0, _name_0, _join_0, _seq_0, _task_0, _params_0, _idx_0) {
  const _code_0 = _task_0["code"];
  const _word_0 = _task_0["value"];
  const _n_0 = _task_0["fresh"];
  return $nc_parallel_finish$(_env_0, _xs_0, _name_0, _join_0, _seq_0, ($nc_children$(_book_0, _xs_0, _env_0, _name_0, _word_0, _idx_0, _n_0)), {$: "N_Emitted", "code": _code_0, "value": _word_0, "fresh": _n_0}, _params_0);
}

function $nc_let$(_book_0, _value_0, _body_0, _env_0, _id_0, _n_0) {
  const _next_0 = ($nc_name$(_n_0));
  const _held_0 = run_loop($nc_live_env$(_env_0, _body_0));
  const _newenv_0 = ($List$append$(_held_0, {$: "Con", "head": ($nc_binding$(_id_0)), "tail": {$: "Nil"}}));
  const _rest_0 = ($nc_lower$(_book_0, _body_0, _newenv_0, ((_n_0 + 1) >>> 0)));
  const _val_0 = ($nc_lower$(_book_0, _value_0, run_loop($nc_live_env$(_env_0, _value_0)), ($nc_fresh$(_rest_0))));
  const _seg_0 = {$: "N_Segment", "name": _next_0, "params": ($nc_params$(_newenv_0)), "result": 1, "frame": {$: "N_Frame", "pop": ($nt_count$(_held_0)), "slots": ($nc_slots$(_held_0, 0))}, "body": ($nc_body$(_rest_0)), "refs": {$: "Nil"}, "host": false, "spin": false, "fork": false, "bang": false};
  const _x_0 = ($nc_cut$(($nc_words$(_held_0)), _next_0, ($nc_fresh$(_val_0))));
  const _x_1 = ($nc_body$(_val_0));
  const _x_2 = ($nc_share_env$(_env_0, _value_0, _body_0));
  const _x_3 = (_x_0 + _x_1);
  return {$: "NC_Code", "body": (_x_2 + _x_3), "segments": {$: "Con", "head": _seg_0, "tail": ($nt_append$(($nc_segs$(_rest_0)), ($nc_segs$(_val_0))))}, "fresh": ($nc_fresh$(_val_0)), "error": run_loop($nc_first_error$(_rest_0, _val_0))};
}

function $nc_head$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return "0";
  } else {
    const _h_0 = _xs_0["head"];
    return _h_0;
  }
}

function $nc_tail$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _xs_0["tail"];
    return _t_0;
  }
}

function $nc_ctor_result$(_x_0) {
  const _code_0 = _x_0["code"];
  const _word_0 = _x_0["value"];
  const _n_0 = _x_0["fresh"];
  const _x_1 = ($ne_ret$({$: "Con", "head": _word_0, "tail": {$: "Nil"}}));
  return {$: "NC_Code", "body": (_code_0 + _x_1), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}

function $ne_constructor$(_k_0, _ws_0, _packed_0, _n_0, _hot_0) {
  if (_ws_0.$ === "Nil") {
    const _x_0 = ($nt_cid$(_k_0));
    const _x_1 = (_x_0 + ", 0)");
    return {$: "N_Emitted", "code": "", "value": ("term_pak(" + _x_1), "fresh": _n_0};
  } else {
    const _h_0 = _ws_0["head"];
    const _t_0 = _ws_0["tail"];
    return $nt_choose$(_packed_0, run_clo((_x_2) => {
  const _x_3 = (_h_0 + ")");
  const _x_4 = ($nt_cid$(_k_0));
  const _x_5 = (", " + _x_3);
  const _x_6 = (_x_4 + _x_5);
  return {$: "N_Emitted", "code": "", "value": ("term_pak(" + _x_6), "fresh": _n_0};
}), run_clo((_x_7) => {
  const _x_8 = ($U32$show$(($nt_count$({$: "Con", "head": _h_0, "tail": _t_0}))));
  const _x_9 = (_x_8 + "))");
  return $ne_wrap_ctor$(_k_0, ($ne_node$("nd", ("heap_alloc(e, cls_fit(" + _x_9), {$: "Con", "head": _h_0, "tail": _t_0}, _n_0, _hot_0)));
}));
  }
}

function $np_can_match$(_term_0) {
  return $Bool$and$(($np_supported$(_term_0)), ($np_level_valid$(run_loop($np_level$(_term_0, ($atom$("Efq")), ($atom$("Efq")), false, false)))));
}

function $np_match_apply$(_book_0, _term_0, _env_0, _next_0) {
  return $np_emit$(_book_0, run_loop($np_collect$(run_loop($kid$(_term_0, 0)), 0, {$: "Nil"})), run_loop($nc_word$(($ix$(run_loop($kid$(_term_0, 1)))), _env_0)), run_loop($nc_remove_env$(_env_0, ($ix$(run_loop($kid$(_term_0, 1)))))), _next_0);
}

function $nc_match_apply_slow$(_book_0, _t_0, _env_0, _n_0) {
  const _mat_0 = run_loop($kid$(_t_0, 0));
  const _arg_0 = run_loop($kid$(_t_0, 1));
  const _word_0 = run_loop($nc_word$(($ix$(_arg_0)), _env_0));
  const _x_0 = ($ix$(_mat_0));
  const _count_0 = run_loop($nt_choose$((_x_0 === 0), run_clo((_x_1) => {
  return $nc_field_count$(_book_0, ($nm$(_mat_0)));
}), run_clo((_x_2) => {
  const _x_3 = ($ix$(_mat_0));
  return ((_x_3 - 1) >>> 0);
})));
  const _hit_0 = ($nc_lower$(_book_0, run_loop($nc_field_apps$(run_loop($kid$(_mat_0, 0)), _count_0, 0, _n_0)), ($List$append$(run_loop($nc_remove_env$(_env_0, ($ix$(_arg_0)))), run_loop($nc_field_env$(($nm$(_mat_0)), _word_0, _count_0, 0, _n_0)))), ((_n_0 + _count_0) >>> 0)));
  const _miss_0 = ($nc_lower$(_book_0, ($app$(run_loop($kid$(_mat_0, 1)), _arg_0)), _env_0, ($nc_fresh$(_hit_0))));
  const _x_4 = ($String$eq$(($nm$(_mat_0)), "Emit"));
  const _x_5 = ($String$eq$(($nm$(_mat_0)), "Halt"));
  const _guard_0 = run_loop($nt_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  const _x_7 = (_word_0 + ") != CID_HALT) { err_post(e.mem, ERR_TAGS); return 0; }\n");
  const _x_8 = (") != CID_EMIT && term_aux(" + _x_7);
  const _x_9 = (_word_0 + _x_8);
  return ("if (term_aux(" + _x_9);
}), run_clo((_x_10) => {
  return "";
})));
  const _x_11 = ($nc_body$(_miss_0));
  const _x_12 = (_x_11 + "}\n");
  const _x_13 = ($nc_body$(_hit_0));
  const _x_14 = ("} else {\n" + _x_12);
  const _x_15 = ($nc_destructure$(($nm$(_mat_0)), _word_0, _count_0, _n_0));
  const _x_16 = (_x_13 + _x_14);
  const _x_17 = (_x_15 + _x_16);
  const _x_18 = run_loop($nc_condition$(($nm$(_mat_0)), _word_0));
  const _x_19 = (") {\n" + _x_17);
  const _x_20 = (_x_18 + _x_19);
  const _x_21 = ("if (" + _x_20);
  return {$: "NC_Code", "body": (_guard_0 + _x_21), "segments": ($nt_append$(($nc_segs$(_hit_0)), ($nc_segs$(_miss_0)))), "fresh": ($nc_fresh$(_miss_0)), "error": run_loop($nc_first_error$(_hit_0, _miss_0))};
}

function $nc_array$(_k_0, _ws_0, _n_0) {
  const _a_0 = ($nc_head$(_ws_0));
  const _i_0 = ($nc_head$(($nc_tail$(_ws_0))));
  const _v_0 = ($nc_head$(($nc_tail$(($nc_tail$(_ws_0))))));
  return $nt_choose$(($String$eq$(_k_0, "array_new")), run_clo((_x_0) => {
  const _x_1 = (_a_0 + ", 0, 1, init)");
  const _x_2 = ($ne_ret$({$: "Con", "head": ("blk_new(e, 1, " + _x_1), "tail": {$: "Nil"}}));
  const _x_3 = (" };\n" + _x_2);
  const _x_4 = (_i_0 + _x_3);
  return {$: "NC_Code", "body": ("Term init[1] = { " + _x_4), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}), run_clo((_x_5) => {
  return $nt_choose$(($String$eq$(_k_0, "array_size")), run_clo((_x_6) => {
  const _x_7 = (_a_0 + "))");
  return $nc_array_pair$("", _a_0, ("(1ull << blk_cls(" + _x_7), _n_0);
}), run_clo((_x_8) => {
  return $nt_choose$(($String$eq$(_k_0, "array_clone")), run_clo((_x_9) => {
  const _x_10 = (_a_0 + ")");
  return $nc_array_pair$("", ("blk_copy(e, " + _x_10), _a_0, _n_0);
}), run_clo((_x_11) => {
  return $nt_choose$(($String$eq$(_k_0, "array_get")), run_clo((_x_12) => {
  const _x_13 = (_i_0 + ", 0);\n");
  const _x_14 = (", " + _x_13);
  const _x_15 = (_a_0 + _x_14);
  const _x_16 = (_a_0 + ") + at)");
  return $nc_array_pair$(("u32 at = blk_at(" + _x_15), _a_0, ("blk_keep(e, term_loc(" + _x_16), _n_0);
}), run_clo((_x_17) => {
  return $nt_choose$(($String$eq$(_k_0, "array_swap")), run_clo((_x_18) => {
  const _x_19 = (_v_0 + "));\n");
  const _x_20 = ("), at, rfc_seal(e, " + _x_19);
  const _x_21 = (_a_0 + _x_20);
  const _x_22 = ("), at);\nblk_write(e.mem, 1, term_loc(" + _x_21);
  const _x_23 = (_a_0 + _x_22);
  const _x_24 = (", 0);\nTerm old = blk_read(e.mem, 1, term_loc(" + _x_23);
  const _x_25 = (_i_0 + _x_24);
  const _x_26 = (", " + _x_25);
  const _x_27 = (_a_0 + _x_26);
  return $nc_array_pair$(("u32 at = blk_at(" + _x_27), _a_0, "old", _n_0);
}), run_clo((_x_28) => {
  const _x_29 = ($ne_ret$({$: "Con", "head": _a_0, "tail": {$: "Nil"}}));
  const _x_30 = ("));\n" + _x_29);
  const _x_31 = (_v_0 + _x_30);
  const _x_32 = ("), at, rfc_seal(e, " + _x_31);
  const _x_33 = (_a_0 + _x_32);
  const _x_34 = ("), at));\nblk_write(e.mem, 1, term_loc(" + _x_33);
  const _x_35 = (_a_0 + _x_34);
  const _x_36 = (", 0);\nterm_sink(e, blk_read(e.mem, 1, term_loc(" + _x_35);
  const _x_37 = (_i_0 + _x_36);
  const _x_38 = (", " + _x_37);
  const _x_39 = (_a_0 + _x_38);
  return {$: "NC_Code", "body": ("u32 at = blk_at(" + _x_39), "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
}));
}));
}));
}));
}));
}

function $ni_emit$(_k_0, _xs_0) {
  return $ni_fill$(run_loop($ni_find$(_k_0, ($ni_templates$()))), _xs_0, 0);
}

function $core_rebuild$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $core_apply$(run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $subst_terms$(_ts_0, _id_0, _v_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _t_0 = _ts_0["tail"];
    return {$: "Con", "head": run_loop($subst$(_h_0, _id_0, _v_0)), "tail": ($subst_terms$(_t_0, _id_0, _v_0))};
  }
}

function $fpe_defs_next$(_error_0, _rest_0) {
  return $f_choose$(($f_eq$(($tg$(_error_0)), "Absent")), run_clo((_x_0) => {
  return $fpe_defs$(_rest_0);
}), run_clo((_x_1) => {
  return _error_0;
}));
}

function $fpe_terms$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _head_0 = _ts_0["head"];
    const _tail_0 = _ts_0["tail"];
    return $fpe_terms_next$(run_loop($fpe_term$(_head_0)), _tail_0);
  }
}

function $f_graph_fresh_name$(_rest_0, _done_0, _d_0, _hash_0, _old_0) {
  const _x_0 = ($Bool$not$(($db$(_old_0))));
  const _x_1 = ($db$(_d_0));
  const _x_2 = ($f_eq$(($dk$(_old_0)), "Absent"));
  const _x_3 = ($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($f_eq$(($dk$(_old_0)), "Def")), ($f_eq$(($dk$(_d_0)), "Def")))), ($f_eq$(($tg$(($dv$(_old_0)))), "Absent")))), ($Bool$not$(($f_eq$(($tg$(($dv$(_d_0)))), "Absent")))))), (_x_0 || _x_1)));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $f_graph_fresh_names$(_rest_0, run_loop($index_set$(_done_0, _d_0, _hash_0, 32)));
}), run_clo((_x_5) => {
  const _x_6 = ($dn$(_d_0));
  const _x_7 = (_x_6 + ")");
  return ("expected a fresh name (duplicate declaration: " + _x_7);
}));
}

function $f_graph_finish$(_s_0, _ns_0, _book_0, _imports_0, _g_0) {
  const _prior_0 = _g_0["book"];
  const _err_0 = _g_0["error"];
  const _done_0 = _g_0["done"];
  return $f_graph_finish_alias$(_s_0, _ns_0, ($f_alias_defs$(_book_0, _imports_0, _prior_0)), _imports_0, _prior_0, run_loop($f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $f_graph_fresh_names$(_book_0, run_loop($index_build$(($List$reverse$(_prior_0)))));
}), run_clo((_x_1) => {
  return _err_0;
}))), _done_0);
}

function $f_graph_aliases$(_imports_0, _source_0, _sources_0, _root_0) {
  if (_imports_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _im_0 = _imports_0["head"];
    const _rest_0 = _imports_0["tail"];
    return {$: "Con", "head": ($kt$("Import", run_loop($f_import_namespace_at$(_im_0, _source_0, _sources_0, _root_0)), 0, 0, ($ks$(_im_0)))), "tail": ($f_graph_aliases$(_rest_0, _source_0, _sources_0, _root_0))};
  }
}

function $fs_root$(_seed_0) {
  const _root_0 = _seed_0["root"];
  return _root_0;
}

function $f_import_pathname$(_im_0, _s_0, _sources_0) {
  return $f_choose$(($f_eq$(($nm$(_im_0)), "Base")), run_clo((_x_0) => {
  return $f_source_path$(run_loop($f_source$("Base", _sources_0)));
}), run_clo((_x_1) => {
  return $f_path_normal$(run_loop($f_path_join$(run_loop($f_path_dir$(($f_source_path$(_s_0)))), ($nm$(_im_0)))));
}));
}

function $f_import_namespace_at$(_im_0, _source_0, _sources_0, _root_0) {
  return $f_choose$(($f_eq$(($nm$(_im_0)), "Base")), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  return $f_strip_bend$(run_loop($f_relative_parts$(run_loop($f_path_segments$(run_loop($f_path_normal$(_root_0)))), run_loop($f_path_segments$(($f_source_path$(run_loop($f_graph_source$(run_loop($f_import_pathname$(_im_0, _source_0, _sources_0)), _sources_0)))))))));
}));
}

function $good$(_r_0) {
  return $String$eq$(($ce$(_r_0)), "");
}

function $ce$(_r_0) {
  const _error_0 = _r_0["error"];
  return _error_0;
}

function $dg_report$(_r_0, _name_0) {
  return $kc$(($String$eq$(($tg$(($ct$(_r_0)))), "DTrace")), run_clo((_x_0) => {
  const _x_1 = ($qt$(($ct$(_r_0))));
  return {$: "DDiagnostic", "expected": run_loop($dg_as_expr$(run_loop($kid$(($ct$(_r_0)), 0)))), "observed": run_loop($dg_as_expr$(run_loop($kid$(($ct$(_r_0)), 1)))), "has_observed": (_x_1 === 1), "context": ($ks$(run_loop($kid$(($ct$(_r_0)), 2)))), "definition": ($nm$(($ct$(_r_0)))), "span": {$: "DNoSpan"}, "note": "", "trail": ($ks$(run_loop($kid$(($ct$(_r_0)), 4))))};
}), run_clo((_x_2) => {
  return $dg_no_report$(_name_0, ($ce$(_r_0)));
}));
}

function $check_definition_type$(_book_0, _d_0, _e_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_1) => {
  return $bad$(run_loop($check_adt_declaration$(_e_0, _d_0)));
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($tg$(($dv$(_d_0)))), "Absent")), run_clo((_x_3) => {
  return _r_0;
}), run_clo((_x_4) => {
  return $kc$(($String$eq$(($tg$(($dv$(_d_0)))), "Foreign")), run_clo((_x_5) => {
  return $bad$(run_loop($check_foreign$(_book_0, _d_0)));
}), run_clo((_x_6) => {
  return $check_template_definition$(_book_0, _d_0, ($dt$(_d_0)), ($dv$(_d_0)), ($ref$(($dn$(_d_0)))), ($dx$(_d_0)));
}));
}));
}));
}), run_clo((_x_7) => {
  return _r_0;
}));
}

function $check$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0) {
  return $dg_trace$(_e_0, _ctx_0, _t_0, _ty_0, run_loop($check_node$(_e_0, _ctx_0, run_loop($core_beta$(_t_0)), _dem_0, _ty_0)));
}

function $typ$(_q_0) {
  return $kt$("Typ", "", 0, 0, {$: "Con", "head": ($qua$(_q_0)), "tail": {$: "Nil"}});
}

function $signature_fill_mode$(_d_0, _fill_0) {
  return $kc$(($String$eq$(($dk$(_fill_0)), "Def")), run_clo((_x_0) => {
  return $declared$(_fill_0);
}), run_clo((_x_1) => {
  return _d_0;
}));
}

function $constructor_exists$(_ds_0, _name_0) {
  if (_ds_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    const _x_0 = ($Bool$and$(($Bool$not$(($String$eq$(($dk$(_h_0)), "BookCache")))), ($Bool$not$(($String$eq$(($dk$(run_loop($lookup$(($dc$(_h_0)), _name_0)))), "Absent"))))));
    const _x_1 = ($constructor_exists$(_rest_0, _name_0));
    return (_x_0 || _x_1);
  }
}

function $norm_cmp_loop$(_book_0, _todo_0, _alts_0) {
  if (_todo_0.$ === "Nil") {
    return true;
  } else {
    const _t_0 = _todo_0["head"];
    const _a_0 = _t_0["a"];
    const _b_0 = _t_0["b"];
    const _le_0 = _t_0["le"];
    const _fresh_0 = _t_0["fresh"];
    const _rest_0 = _todo_0["tail"];
    return $kc$(run_loop($norm_cmp_quick$(_a_0, _b_0)), run_clo((_x_0) => {
  return $norm_cmp_loop$(_book_0, _rest_0, _alts_0);
}), run_clo((_x_1) => {
  return $norm_cmp_heads$(_book_0, run_loop($wnf$(_book_0, _a_0)), run_loop($wnf$(_book_0, _b_0)), _le_0, _fresh_0, _rest_0, _alts_0);
}));
  }
}

function $dg_padding$(_n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = run_loop($dg_padding$(((_n_0 - 1) >>> 0)));
  return (" " + _x_2);
}));
}

function $dg_units$(_c_0) {
  const _x_0 = ($Char$to_u32$(_c_0));
  return $kc$((_x_0 > 65535), run_clo((_x_1) => {
  return 2;
}), run_clo((_x_2) => {
  return 1;
}));
}

function $dg_snippet_at$(_lines_0, _at_0) {
  const _x_0 = ($dg_lines_count$(_lines_0));
  const _x_1 = ((_at_0 + 1) >>> 0);
  return $dg_snippet_lines$(_lines_0, _at_0, run_loop($kc$((_x_0 < _x_1), run_clo((_x_2) => {
  return $dg_lines_count$(_lines_0);
}), run_clo((_x_3) => {
  return ((_at_0 + 1) >>> 0);
}))), 1);
}

function $dg_line_at$(_s_0, _offset_0, _line_0) {
  if (_s_0 === "") {
    return _line_0;
  } else {
    const _c_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _rest_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_0 = run_loop($dg_units$(_c_0));
    return $kc$((_offset_0 < _x_0), run_clo((_x_1) => {
  return _line_0;
}), run_clo((_x_2) => {
  const _x_3 = run_loop($dg_units$(_c_0));
  return $dg_line_at$(_rest_0, ((_offset_0 - _x_3) >>> 0), run_loop($kc$(($Char$is_eq$(_c_0, "\n")), run_clo((_x_4) => {
  return ((_line_0 + 1) >>> 0);
}), run_clo((_x_5) => {
  return _line_0;
}))));
}));
  }
}

function $norm_exact_head$(_a_0, _b_0) {
  const _x_0 = ($ix$(_a_0));
  const _x_1 = ($ix$(_b_0));
  const _x_2 = ($qt$(_a_0));
  const _x_3 = ($qt$(_b_0));
  const _x_4 = ($terms_len$(($ks$(_a_0))));
  const _x_5 = ($terms_len$(($ks$(_b_0))));
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_a_0)), ($tg$(_b_0)))), ($String$eq$(($nm$(_a_0)), ($nm$(_b_0)))))), (_x_0 === _x_1))), (_x_2 === _x_3))), (_x_4 === _x_5))), run_loop($norm_exact_names$(($rm$(_a_0)), ($rm$(_b_0)))));
}

function $fp_def$(_d_0, _source_0) {
  return $List$append$(($fp_term$(($dt$(_d_0)), ($dn$(_d_0)), _source_0, {$: "Con", "head": 0, "tail": {$: "Nil"}})), ($List$append$(($fp_term$(($dv$(_d_0)), ($dn$(_d_0)), _source_0, {$: "Con", "head": 1, "tail": {$: "Nil"}})), ($fp_ctors$(($dc$(_d_0)), ($dn$(_d_0)), _source_0, 0)))));
}

function $j_printable_fields$(_book_0, _ty_0, _seen_0, _fuel_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_ty_0));
  return $Bool$and$(($Bool$and$(($Bool$not$((_x_1 === 0))), run_loop($j_printable$(_book_0, run_loop($kid$(_ty_0, 0)), _seen_0, _fuel_0)))), run_loop($j_printable_fields$(_book_0, run_loop($kid$(_ty_0, 1)), _seen_0, _fuel_0)));
}), run_clo((_x_2) => {
  return true;
}));
}

function $j_layout_intrinsic$(_book_0, _f_0, _element_0) {
  return $kc$(($j_layout_array_intrinsic$(_book_0, _f_0)), run_clo((_x_0) => {
  return $Bool$not$(($String$eq$(($tg$(run_loop($wnf$(_book_0, run_loop($j_strip$(_element_0)))))), "ADT")));
}), run_clo((_x_1) => {
  return false;
}));
}

function $j_layout_function$(_book_0, _env_0, _t_0, _ty_0, _todo_0) {
  return $kc$(($String$eq$(($tg$(run_loop($j_strip$(_t_0)))), "Ref")), run_clo((_x_0) => {
  return {$: "Con", "head": ($nm$(run_loop($j_strip$(_t_0)))), "tail": _todo_0};
}), run_clo((_x_1) => {
  return $j_layout_term$(_book_0, _env_0, _t_0, _ty_0, _todo_0);
}));
}

function $j_layout_open_head$(_book_0, _ty_0) {
  return $kc$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "ADT")), ($String$eq$(($nm$(_ty_0)), "Array")))), run_clo((_x_0) => {
  return $Bool$not$(($String$eq$(($tg$(run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0)))))), "ADT")));
}), run_clo((_x_1) => {
  return false;
}));
}

function $j_layout_bindings$($0, $1, $2, $3) {
  for (;;) {
    {
      const _book_0 = $0;
      const _env_0 = $1;
      const _xs_0 = $2;
      const _todo_0 = $3;
      if (_xs_0.$ === "Nil") {
        return _todo_0;
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        if (_t_0.$ === "Nil") {
          return _todo_0;
        } else {
          const _x_0 = ($qt$(_h_0));
          $0 = _book_0;
          $1 = _env_0;
          $2 = _t_0;
          $3 = run_loop($kc$((_x_0 === 0), run_clo((_x_1) => {
  return _todo_0;
}), run_clo((_x_2) => {
  return $j_layout_term$(_book_0, _env_0, run_loop($kid$(_h_0, 0)), run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_h_0, 0)))), _todo_0);
})));
          continue;
        }
      }
    }
  }
}

function $j_l_deeps$(_ts_0, _depth_0) {
  if (_ts_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return $kc$(run_loop($j_l_deep$(_h_0, _depth_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $j_l_deeps$(_rest_0, _depth_0);
}));
  }
}

function $j_l_walk$(_book_0, _env_0, _t_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $j_l_walk$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)));
}), run_clo((_x_1) => {
  const _x_12 = run_loop($kc$(($String$eq$(run_loop($j_l_name$(_t_0)), "")), run_clo((_x_2) => {
  return "";
}), run_clo((_x_3) => {
  const _x_4 = run_loop($j_expr_on$(_book_0, _env_0, _t_0, _ty_0, false, ($tg$(_t_0))));
  const _x_5 = (_x_4 + ";};\n");
  const _x_6 = run_loop($j_l_capture$(_env_0, {$: "Nil"}));
  const _x_7 = ("){return " + _x_5);
  const _x_8 = (_x_6 + _x_7);
  const _x_9 = ($j_quote$(run_loop($j_l_name$(_t_0))));
  const _x_10 = ("]=function(" + _x_8);
  const _x_11 = (_x_9 + _x_10);
  return ("F[" + _x_11);
})));
  const _x_13 = run_loop($j_l_children$(_book_0, _env_0, _t_0, _ty_0));
  return (_x_12 + _x_13);
}));
}

function $j_l_marks$(_ts_0, _path_0, _depth_0, _at_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($U32$show$(_at_0));
    const _x_1 = ("_" + _x_0);
    return {$: "Con", "head": run_loop($j_l_mark$(_h_0, (_path_0 + _x_1), _depth_0)), "tail": ($j_l_marks$(_rest_0, _path_0, _depth_0, ((_at_0 + 1) >>> 0)))};
  }
}

function $j_l_global_worker$(_book_0, _d_0, _t_0, _worker_0) {
  const _x_8 = run_loop($kc$(($Bool$not$(($String$eq$(_worker_0, "")))), run_clo((_x_0) => {
  return _worker_0;
}), run_clo((_x_1) => {
  const _x_2 = ($String$eq$(($tg$(run_loop($j_strip$(_t_0)))), "Lam"));
  const _x_3 = ($String$eq$(($tg$(run_loop($j_strip$(_t_0)))), "Mat"));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $j_expr$(_book_0, {$: "Nil"}, _t_0, ($dt$(_d_0)), false);
}), run_clo((_x_5) => {
  const _x_6 = run_loop($j_expr$(_book_0, {$: "Nil"}, _t_0, ($dt$(_d_0)), true));
  const _x_7 = (_x_6 + ";})");
  return ("fn(0,function(){return " + _x_7);
}));
})));
  const _x_9 = (_x_8 + ";\n");
  const _x_10 = ($j_quote$(($dn$(_d_0))));
  const _x_11 = ("]=" + _x_9);
  const _x_12 = (_x_10 + _x_11);
  return ("G[" + _x_12);
}

function $j_projection_worker$(_book_0, _t_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(run_loop($j_strip$(_t_0)))), "Mat")), run_clo((_x_0) => {
  return $j_projection_match$(_book_0, run_loop($j_strip$(_t_0)), run_loop($wnf$(_book_0, _ty_0)));
}), run_clo((_x_1) => {
  return "";
}));
}

function $fpe_snippet_lines$(_lines_0, _at_0, _end_0, _line_0) {
  if (_lines_0.$ === "Nil") {
    return "";
  } else {
    const _head_0 = _lines_0["head"];
    const _tail_0 = _lines_0["tail"];
    return $f_choose$((_line_0 > _end_0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = ((_line_0 + 1) >>> 0);
  const _x_13 = run_loop($f_choose$((_x_2 < _at_0), run_clo((_x_3) => {
  return "";
}), run_clo((_x_4) => {
  const _x_5 = ($U32$show$(_end_0));
  const _x_6 = [..._x_5].length;
  const _x_9 = run_loop($f_choose$((_line_0 === _at_0), run_clo((_x_7) => {
  return ">| ";
}), run_clo((_x_8) => {
  return " | ";
})));
  const _x_10 = run_loop($fpe_pad$(($U32$show$(_line_0)), (_x_6 >>> 0)));
  const _x_11 = (_x_9 + _head_0);
  const _x_12 = (_x_10 + _x_11);
  return ("\n" + _x_12);
})));
  const _x_14 = run_loop($fpe_snippet_lines$(_tail_0, _at_0, _end_0, ((_line_0 + 1) >>> 0)));
  return (_x_13 + _x_14);
}));
  }
}

function $fpe_lines_count$(_lines_0) {
  if (_lines_0.$ === "Nil") {
    return 0;
  } else {
    const _tail_0 = _lines_0["tail"];
    const _x_0 = ($fpe_lines_count$(_tail_0));
    return ((1 + _x_0) >>> 0);
  }
}

function $f_import_alias$(_ts_0, _path_0, _book_0, _imports_0) {
  return $f_choose$(($Bool$and$(($String$ends_with$(_path_0, ".bend")), ($f_alias_valid$(($f_tx$(($f_tl$(_ts_0)))))))), run_clo((_x_0) => {
  return $f_choose$(($f_import_used$(($f_tx$(($f_tl$(_ts_0)))), _imports_0)), run_clo((_x_1) => {
  const _x_2 = ($f_tx$(($f_tl$(_ts_0))));
  const _x_3 = (_x_2 + " names an earlier import)");
  return $f_result$(_book_0, ($kt$("Error", ("expected a fresh alias (" + _x_3), 0, 0, {$: "Nil"})), _imports_0);
}), run_clo((_x_4) => {
  return $f_tops$(($f_tl$(($f_tl$(_ts_0)))), _book_0, {$: "Con", "head": ($kt$("Import", _path_0, 0, 0, {$: "Con", "head": ($kt$("Alias", ($f_tx$(($f_tl$(_ts_0)))), 0, 0, {$: "Nil"})), "tail": {$: "Nil"}})), "tail": _imports_0}, false);
}));
}), run_clo((_x_5) => {
  return $f_result$(_book_0, ($kt$("Error", "an import requires a .bend path and a valid alias", 0, 0, {$: "Nil"})), _imports_0);
}));
}

function $f_templates$(_pars_0) {
  if (_pars_0.$ === "Nil") {
    return 0;
  } else {
    const _p_0 = _pars_0["head"];
    const _ps_0 = _pars_0["tail"];
    const _x_2 = run_loop($f_choose$(($f_eq$(($tg$(_p_0)), "Template")), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  return 0;
})));
    const _x_3 = ($f_templates$(_ps_0));
    return ((_x_2 + _x_3) >>> 0);
  }
}

function $f_law_type$(_name_0, _binder_0, _p_0, _book_0, _imports_0, _clauses_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _ty_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(run_loop($f_skip$(_ts_0)))), "where")), run_clo((_x_2) => {
  return $f_law_where$(_name_0, _binder_0, _ty_0, run_loop($f_expr$(($f_tl$(run_loop($f_skip$(_ts_0)))), 0)), _book_0, _imports_0, _clauses_0);
}), run_clo((_x_3) => {
  return $f_law$(_name_0, run_loop($f_skip$(_ts_0)), _book_0, _imports_0, {$: "Con", "head": ($kt$(($tg$(_binder_0)), ($nm$(_binder_0)), ($ix$(_binder_0)), ($qt$(_binder_0)), {$: "Con", "head": _ty_0, "tail": {$: "Nil"}})), "tail": _clauses_0});
}));
}));
}

function $f_unmark$(_ts_0) {
  const _x_0 = run_loop($f_quant$(_ts_0));
  return $f_choose$((_x_0 === 1), run_clo((_x_1) => {
  return _ts_0;
}), run_clo((_x_2) => {
  return $f_tl$(_ts_0);
}));
}

function $f_atid$(_ts_0) {
  const _x_0 = ($f_line$(_ts_0));
  const _x_1 = (Math.imul(_x_0, 65536) >>> 0);
  const _x_2 = ($f_col$(_ts_0));
  return ((_x_1 + _x_2) >>> 0);
}

function $f_quant$(_ts_0) {
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), "-"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), "~"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return 0;
}), run_clo((_x_3) => {
  const _x_4 = ($f_eq$(($f_tx$(_ts_0)), "+"));
  const _x_5 = ($f_eq$(($f_tx$(_ts_0)), "+bind"));
  return $f_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  return 2;
}), run_clo((_x_7) => {
  return 1;
}));
}));
}

function $f_law_arity$(_clauses_0) {
  if (_clauses_0.$ === "Nil") {
    return 0;
  } else {
    const _c_0 = _clauses_0["head"];
    const _rest_0 = _clauses_0["tail"];
    return $f_choose$(($f_eq$(($tg$(_c_0)), "Exists")), run_clo((_x_0) => {
  return 0;
}), run_clo((_x_1) => {
  const _x_2 = run_loop($f_law_arity$(_rest_0));
  return ((1 + _x_2) >>> 0);
}));
  }
}

function $f_law_bind$(_clauses_0, _ty_0) {
  if (_clauses_0.$ === "Nil") {
    return _ty_0;
  } else {
    const _c_0 = _clauses_0["head"];
    const _cs_0 = _clauses_0["tail"];
    return $f_choose$(($f_eq$(($tg$(_c_0)), "Exists")), run_clo((_x_0) => {
  return $f_app$(($kt$("Ref", "Exists", 0, 1, {$: "Nil"})), {$: "Con", "head": run_loop($kid$(_c_0, 0)), "tail": {$: "Con", "head": ($kt$("Lam", ($nm$(_c_0)), ($ix$(_c_0)), 1, {$: "Con", "head": run_loop($f_law_bind$(_cs_0, _ty_0)), "tail": {$: "Nil"}})), "tail": {$: "Nil"}}});
}), run_clo((_x_1) => {
  return $kt$("All", ($nm$(_c_0)), ($ix$(_c_0)), ($qt$(_c_0)), {$: "Con", "head": run_loop($kid$(_c_0, 0)), "tail": {$: "Con", "head": run_loop($f_law_bind$(_cs_0, _ty_0)), "tail": {$: "Nil"}}});
}));
  }
}

function $f_grow$(_p_0, _min_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  const _x_0 = run_loop($f_prec$(($f_tx$(run_loop($f_skip$(_ts_0))))));
  const _x_1 = ($f_eq$(($f_tx$(run_loop($f_skip$(_ts_0)))), "%"));
  const _x_2 = ($f_eq$(($f_tx$(run_loop($f_skip$(_ts_0)))), "-"));
  const _x_3 = ($f_col$(run_loop($f_skip$(_ts_0))));
  const _x_4 = ($f_col$(($f_tl$(run_loop($f_skip$(_ts_0))))));
  const _x_5 = ((_x_3 + 1) >>> 0);
  return $f_choose$(($Bool$and$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "\n")), (_x_0 > 0))), ($Bool$not$(($Bool$and$((_x_1 || _x_2), (_x_4 === _x_5))))))), run_clo((_x_6) => {
  return $f_grow_base$({$: "FParsed", "term": _n_0, "rest": run_loop($f_skip$(_ts_0))}, _min_0);
}), run_clo((_x_7) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "!")), run_clo((_x_8) => {
  return $f_bang$(_n_0, _ts_0, _min_0);
}), run_clo((_x_9) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "[")), run_clo((_x_10) => {
  return $f_index$(_n_0, run_loop($f_expect$(run_loop($f_expr$(($f_tl$(_ts_0)), 0)), "]")), _min_0);
}), run_clo((_x_11) => {
  return $f_grow_base$({$: "FParsed", "term": _n_0, "rest": _ts_0}, _min_0);
}));
}));
}));
}

function $f_atom$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "~")), run_clo((_x_0) => {
  return $f_template_expr$(run_loop($f_expr$(($f_tl$(_ts_0)), 0)));
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "do")), run_clo((_x_2) => {
  return $f_do_start$(($f_tl$(_ts_0)));
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "%")), run_clo((_x_4) => {
  return $f_rewrite$(($f_tl$(_ts_0)));
}), run_clo((_x_5) => {
  return $f_atom_base$(_ts_0);
}));
}));
}));
}

function $f_def_base$(_name_0, _p_0, _book_0, _imports_0, _unsafe_0) {
  const _pars_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_pars_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _pars_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "->")), run_clo((_x_2) => {
  return $f_def_type$(_name_0, ($ks$(_pars_0)), run_loop($f_expr$(($f_tl$(_ts_0)), 0)), _book_0, _imports_0, _unsafe_0);
}), run_clo((_x_3) => {
  return $f_def_type$(_name_0, ($ks$(_pars_0)), {$: "FParsed", "term": ($dt$(run_loop($f_find$(_name_0, _book_0)))), "rest": _ts_0}, _book_0, _imports_0, _unsafe_0);
}));
}));
}

function $f_bare_params$(_params_0) {
  if (_params_0.$ === "Nil") {
    return true;
  } else {
    const _p_0 = _params_0["head"];
    const _rest_0 = _params_0["tail"];
    return $Bool$and$(($Bool$and$(($f_eq$(($tg$(run_loop($kid$(_p_0, 0)))), "Qnt")), ($Bool$not$(($f_eq$(($tg$(_p_0)), "Template")))))), ($f_bare_params$(_rest_0)));
  }
}

function $f_pr$(_p_0) {
  const _ts_0 = _p_0["rest"];
  return _ts_0;
}

function $f_validate_param$(_ts_0, _end_0, _acc_0) {
  return $f_choose$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "~")), ($Bool$not$(($f_eq$(_end_0, ")")))))), run_clo((_x_0) => {
  return $f_err$(_ts_0, "~ is only allowed on def or law template parameters");
}), run_clo((_x_1) => {
  return $f_choose$(($Bool$not$(($f_valid_name$(($f_tx$(run_loop($f_unmark$(_ts_0)))))))), run_clo((_x_2) => {
  return $f_err$(_ts_0, "reserved parameter name");
}), run_clo((_x_3) => {
  return $f_choose$(($Bool$and$(($f_eq$(_end_0, "}")), ($f_named_field$(($f_tx$(run_loop($f_unmark$(_ts_0)))), _acc_0)))), run_clo((_x_4) => {
  const _x_5 = ($f_tx$(run_loop($f_unmark$(_ts_0))));
  const _x_6 = (_x_5 + ")");
  return $fpe_error$(run_loop($f_unmark$(_ts_0)), "duplicate constructor field", ("a fresh field name (duplicate declaration: " + _x_6));
}), run_clo((_x_7) => {
  const _x_8 = ($f_templates$(_acc_0));
  const _x_9 = ($terms_len$(_acc_0));
  return $f_choose$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "~")), (_x_8 < _x_9))), run_clo((_x_10) => {
  return $f_err$(_ts_0, "only leading parameters may use ~");
}), run_clo((_x_11) => {
  return $f_tele_binder$(($f_tx$(run_loop($f_unmark$(_ts_0)))), ($f_atid$(_ts_0)), run_loop($f_quant$(_ts_0)), ($f_eq$(($f_tx$(_ts_0)), "~")), ($f_tl$(run_loop($f_unmark$(_ts_0)))), _end_0, _acc_0);
}));
}));
}));
}));
}

function $f_type_kind$(_name_0, _pars_0, _p_0, _book_0, _imports_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _ty_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_type_ctors$(_name_0, _pars_0, _ty_0, run_loop($f_skip$(_ts_0)), _book_0, _imports_0, {$: "Nil"});
}));
}

function $f_expect$(_p_0, _s_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  const _x_0 = ($f_eq$(($tg$(_n_0)), "Error"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), _s_0));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return {$: "FParsed", "term": _n_0, "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_3) => {
  const _x_4 = ($f_eq$(_s_0, ")"));
  const _x_5 = ($f_eq$(_s_0, "}"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($f_eq$(_s_0, "]"));
  return $f_choose$((_x_6 || _x_7), run_clo((_x_8) => {
  const _x_9 = (_s_0 + "'");
  return $fpe_error$(_ts_0, ("expected " + _s_0), ("'" + _x_9));
}), run_clo((_x_10) => {
  return $f_err$(_ts_0, ("expected " + _s_0));
}));
}));
}

function $ffd_frame$($0, $1, $2, $3, $4, $5) {
  let $pc = 2;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      if (_book_0.$ === "Nil") {
        $0 = ($List$reverse$(_built_0));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 1; continue;
      } else {
        const _definition_0 = _book_0["head"];
        const _pending_0 = _book_0["tail"];
        $0 = _definition_0;
        $1 = _pending_0;
        $2 = _built_0;
        $3 = _stack_0;
        $4 = run_loop($f_fresh_term$(($dt$(_definition_0)), {$: "Nil"}, _next_0));
        $pc = 3; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFreshDefs", "defs": _book_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _book_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 2; continue;
      }
    }
    case 2: {
      const _frame_0 = $0;
      const _ctors_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      const _definition_0 = _frame_0["definition"];
      const _pending_0 = _frame_0["pending"];
      const _built_0 = _frame_0["built"];
      const _typ_0 = _frame_0["typ"];
      const _value_0 = _frame_0["value"];
      $0 = _pending_0;
      $1 = _next_0;
      $2 = {$: "Con", "head": {$: "KDef", "name": ($dn$(_definition_0)), "kind": ($dk$(_definition_0)), "arity": ($da$(_definition_0)), "templates": ($dx$(_definition_0)), "typ": _typ_0, "value": _value_0, "ctors": _ctors_0, "native": ($db$(_definition_0)), "unsafe": ($du$(_definition_0))}, "tail": _built_0};
      $3 = _stack_0;
      $pc = 0; continue;
    }
    case 3: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _result_0 = $4;
      const _typ_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = _definition_0;
      $1 = _pending_0;
      $2 = _built_0;
      $3 = _stack_0;
      $4 = _typ_0;
      $5 = run_loop($f_fresh_term$(($dv$(_definition_0)), {$: "Nil"}, _next_0));
      $pc = 4; continue;
    }
    case 4: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _typ_0 = $4;
      const _result_0 = $5;
      const _value_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = ($dc$(_definition_0));
      $1 = _next_0;
      $2 = {$: "Nil"};
      $3 = {$: "Con", "head": {$: "FFDefFrame", "definition": _definition_0, "pending": _pending_0, "built": _built_0, "typ": _typ_0, "value": _value_0}, "tail": _stack_0};
      $pc = 0; continue;
    }
  }
}

function $ffd_value$($0, $1, $2, $3, $4, $5) {
  let $pc = 4;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      if (_book_0.$ === "Nil") {
        $0 = ($List$reverse$(_built_0));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 1; continue;
      } else {
        const _definition_0 = _book_0["head"];
        const _pending_0 = _book_0["tail"];
        $0 = _definition_0;
        $1 = _pending_0;
        $2 = _built_0;
        $3 = _stack_0;
        $4 = run_loop($f_fresh_term$(($dt$(_definition_0)), {$: "Nil"}, _next_0));
        $pc = 3; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFreshDefs", "defs": _book_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _book_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 2; continue;
      }
    }
    case 2: {
      const _frame_0 = $0;
      const _ctors_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      const _definition_0 = _frame_0["definition"];
      const _pending_0 = _frame_0["pending"];
      const _built_0 = _frame_0["built"];
      const _typ_0 = _frame_0["typ"];
      const _value_0 = _frame_0["value"];
      $0 = _pending_0;
      $1 = _next_0;
      $2 = {$: "Con", "head": {$: "KDef", "name": ($dn$(_definition_0)), "kind": ($dk$(_definition_0)), "arity": ($da$(_definition_0)), "templates": ($dx$(_definition_0)), "typ": _typ_0, "value": _value_0, "ctors": _ctors_0, "native": ($db$(_definition_0)), "unsafe": ($du$(_definition_0))}, "tail": _built_0};
      $3 = _stack_0;
      $pc = 0; continue;
    }
    case 3: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _result_0 = $4;
      const _typ_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = _definition_0;
      $1 = _pending_0;
      $2 = _built_0;
      $3 = _stack_0;
      $4 = _typ_0;
      $5 = run_loop($f_fresh_term$(($dv$(_definition_0)), {$: "Nil"}, _next_0));
      $pc = 4; continue;
    }
    case 4: {
      const _definition_0 = $0;
      const _pending_0 = $1;
      const _built_0 = $2;
      const _stack_0 = $3;
      const _typ_0 = $4;
      const _result_0 = $5;
      const _value_0 = _result_0["term"];
      const _next_0 = _result_0["next"];
      $0 = ($dc$(_definition_0));
      $1 = _next_0;
      $2 = {$: "Nil"};
      $3 = {$: "Con", "head": {$: "FFDefFrame", "definition": _definition_0, "pending": _pending_0, "built": _built_0, "typ": _typ_0, "value": _value_0}, "tail": _stack_0};
      $pc = 0; continue;
    }
  }
}

function $f_fresh_stack$(_term_0, _env_0, _next_0) {
  return $ffw_walk$(_term_0, _env_0, _next_0, {$: "Nil"});
}

function $f_qual_def$(_d_0, _book_0, _ns_0, _imports_0) {
  const _name_0 = _d_0["name"];
  const _kind_0 = _d_0["kind"];
  const _arity_0 = _d_0["arity"];
  const _templates_0 = _d_0["templates"];
  const _ty_0 = _d_0["typ"];
  const _value_0 = _d_0["value"];
  const _ctors_0 = _d_0["ctors"];
  const _native_0 = _d_0["native"];
  const _unsafe_0 = _d_0["unsafe"];
  return {$: "KDef", "name": run_loop($f_qual_name$(_name_0, _ns_0)), "kind": _kind_0, "arity": _arity_0, "templates": _templates_0, "typ": ($f_qual_term$(_ty_0, _book_0, _ns_0, _imports_0)), "value": ($f_qual_term$(_value_0, _book_0, _ns_0, _imports_0)), "ctors": ($f_qual_defs$(_ctors_0, _book_0, _ns_0, _imports_0)), "native": _native_0, "unsafe": _unsafe_0};
}

function $f_scope$(_t_0, _env_0, _book_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "FDo")), run_clo((_x_0) => {
  return $f_scope_do$(_t_0, _env_0, _book_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Call")), run_clo((_x_2) => {
  return $f_scope_call$(_t_0, _env_0, _book_0);
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "TemplateArg")), run_clo((_x_4) => {
  return $kt$("Error", "~ is only valid in a named template call", 0, 0, {$: "Nil"});
}), run_clo((_x_5) => {
  return $f_scope_lower$(_t_0, _env_0, _book_0);
}));
}));
}));
}

function $ka_app_spine_root$(_e_0, _ctx_0, _arg_0, _node_0, _fty_0) {
  return $app$(($ka_wrap$(_node_0, _fty_0)), ($annotate$(_e_0, _ctx_0, _arg_0, run_loop($kid$(_fty_0, 0)))));
}

function $ka_spine_finish$(_e_0, _ctx_0, _arg_0, _r_0) {
  const _node_0 = _r_0["node"];
  const _ty_0 = _r_0["typ"];
  return $ka_spine_step$(_e_0, _ctx_0, _arg_0, _node_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)));
}

function $ctx_get$(_ctx_0, _id_0) {
  if (_ctx_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _h_0 = _ctx_0["head"];
    const _t_0 = _ctx_0["tail"];
    const _x_0 = ($ix$(_h_0));
    return $kc$((_x_0 === _id_0), run_clo((_x_1) => {
  return _h_0;
}), run_clo((_x_2) => {
  return $ctx_get$(_t_0, _id_0);
}));
  }
}

function $ka_type_app$(_e_0, _t_0, _fty_0) {
  return $subst$(run_loop($kid$(_fty_0, 1)), ($ix$(_fty_0)), run_loop($kid$(_t_0, 1)));
}

function $ka_args_after_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0, _annotated_0) {
  return $kc$(run_loop($core_subst_stable$(run_loop($kid$(_tel_0, 1)))), run_clo((_x_0) => {
  return {$: "Con", "head": _annotated_0, "tail": run_loop($ka_args_static$(_e_0, _ctx_0, run_loop($kid$(_tel_0, 1)), _rest_0))};
}), run_clo((_x_1) => {
  return {$: "Con", "head": _annotated_0, "tail": ($ka_args$(_e_0, _ctx_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), _h_0)), _rest_0))};
}));
}

function $ka_args_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0) {
  return {$: "Con", "head": ($annotate$(_e_0, _ctx_0, _h_0, run_loop($kid$(_tel_0, 0)))), "tail": ($ka_args$(_e_0, _ctx_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), _h_0)), _rest_0))};
}

function $mat_goal$(_book_0, _goal_0, _tel_0, _n_0, _name_0, _xs_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return $subst$(run_loop($kid$(_goal_0, 1)), ($ix$(_goal_0)), ($kt$("Ctr", _name_0, 0, 0, ($norm_join$(_xs_0, {$: "Nil"})))));
}), run_clo((_x_1) => {
  return $mat_goal_head$(_book_0, _goal_0, run_loop($wnf$(_book_0, _tel_0)), _n_0, _name_0, _xs_0);
}));
}

function $mat_rest$(_book_0, _t_0, _a_0) {
  return $kc$(($Bool$and$(($Bool$not$(($String$eq$(($tg$(run_loop($kid$(_t_0, 1)))), "Mat")))), ($defs_empty$(run_loop($remaining$(($dc$(run_loop($lookup$(_book_0, ($nm$(_a_0)))))), {$: "Con", "head": ($nm$(_t_0)), "tail": ($rm$(_a_0))})))))), run_clo((_x_0) => {
  return $atom$("Efq");
}), run_clo((_x_1) => {
  return $kid$(_t_0, 1);
}));
}

function $j_choice_arm$(_t_0, _first_0) {
  return $Bool$and$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Lam")), ($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))))), "Lam")))), ($j_choice_leaf$(run_loop($j_strip$(run_loop($kid$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), 0)))), run_loop($kc$(_first_0, run_clo((_x_0) => {
  return $ix$(_t_0);
}), run_clo((_x_1) => {
  return $ix$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))));
}))))));
}

function $j_choice_branch$(_book_0, _env_0, _t_0, _ty_0, _tail_0) {
  const _x_0 = ($qt$(_ty_0));
  const _x_3 = run_loop($kc$((_x_0 === 0), run_clo((_x_1) => {
  return "null";
}), run_clo((_x_2) => {
  return "ctor(\"Unit\",[])";
})));
  const _x_4 = (_x_3 + ")");
  const _x_5 = run_loop($j_expr$(_book_0, {$: "Con", "head": ($kt$("Env", "", ($ix$(_t_0)), 0, {$: "Con", "head": run_loop($kid$(_ty_0, 0)), "tail": {$: "Nil"}})), "tail": _env_0}, run_loop($kid$(_t_0, 0)), run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))), _tail_0));
  const _x_6 = (")(" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  const _x_8 = ($j_local$(($ix$(_t_0))));
  const _x_9 = (")=>" + _x_7);
  const _x_10 = (_x_8 + _x_9);
  return ("((" + _x_10);
}

function $j_word_text$(_value_0, _float_0) {
  if (_value_0.$ === "None") {
    return "";
  } else {
    const _n_0 = _value_0["value"];
    return $kc$(_float_0, run_clo((_x_0) => {
  const _x_1 = ($U32$show$(_n_0));
  const _x_2 = (_x_1 + ")");
  return ("bitsFloat(" + _x_2);
}), run_clo((_x_3) => {
  return $U32$show$(_n_0);
}));
  }
}

function $j_word$(_t_0, _at_0, _acc_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_0) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "WNil")), run_clo((_x_1) => {
  return $kc$((_at_0 === 32), run_clo((_x_2) => {
  return {$: "Some", "value": _acc_0};
}), run_clo((_x_3) => {
  return {$: "None"};
}));
}), run_clo((_x_4) => {
  return $kc$(($Bool$and$(($String$eq$(($nm$(_t_0)), "WCon")), (_at_0 < 32))), run_clo((_x_5) => {
  return $j_word_bit$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), run_loop($j_strip$(run_loop($kid$(_t_0, 1)))), _at_0, _acc_0);
}), run_clo((_x_6) => {
  return {$: "None"};
}));
}));
}), run_clo((_x_7) => {
  return {$: "None"};
}));
}

function $j_char_text$(_value_0) {
  if (_value_0.$ === "None") {
    return "";
  } else {
    const _n_0 = _value_0["value"];
    const _x_0 = ($U32$show$(_n_0));
    const _x_1 = (_x_0 + ")");
    return ("checkedChar(" + _x_1);
  }
}

function $j_u32$(_t_0) {
  return $j_u32_node$(run_loop($j_strip$(_t_0)));
}

function $j_nat_text$(_value_0) {
  if (_value_0.$ === "None") {
    return "";
  } else {
    const _n_0 = _value_0["value"];
    const _x_0 = ($Nat$show$(_n_0));
    return (_x_0 + "n");
  }
}

function $j_nat$(_t_0, _acc_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  const _x_1 = ($qt$(_t_0));
  return {$: "Some", "value": nat_chk(_acc_0 + _x_1)};
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_3) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "Zero")), run_clo((_x_4) => {
  return {$: "Some", "value": _acc_0};
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "Succ")), run_clo((_x_6) => {
  return $j_nat$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), nat_chk(_acc_0 + 1));
}), run_clo((_x_7) => {
  return {$: "None"};
}));
}));
}), run_clo((_x_8) => {
  return {$: "None"};
}));
}));
}

function $j_string_text$(_value_0) {
  if (_value_0.$ === "None") {
    return "";
  } else {
    const _s_0 = _value_0["value"];
    return $j_quote$(_s_0);
  }
}

function $j_string$(_t_0, _acc_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_0) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "SNil")), run_clo((_x_1) => {
  return {$: "Some", "value": ($String$reverse$(_acc_0))};
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($nm$(_t_0)), "SCon")), run_clo((_x_3) => {
  return $j_string_head$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), run_loop($j_strip$(run_loop($kid$(_t_0, 1)))), _acc_0);
}), run_clo((_x_4) => {
  return {$: "None"};
}));
}));
}), run_clo((_x_5) => {
  return {$: "None"};
}));
}

function $kp_float_text$(_s_0) {
  const _x_0 = ($String$contains$(_s_0, "."));
  const _x_1 = ($String$contains$(_s_0, "n"));
  return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return _s_0;
}), run_clo((_x_3) => {
  return $kp_float_point$(_s_0);
}));
}

function $kp_float$(_n_0) {
  return f32_from_bits(_n_0);
}

function $kp_nat$(_t_0, _n_0, _p_0, _env_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  const _x_1 = ($qt$(_t_0));
  const _x_2 = ((4294967295 - _x_1) >>> 0);
  return $kc$(($Nat$is_le$(_n_0, _x_2)), run_clo((_x_3) => {
  const _x_4 = ($qt$(_t_0));
  const _x_5 = ($Nat$show$(nat_chk(_n_0 + _x_4)));
  return (_x_5 + "n");
}), run_clo((_x_6) => {
  const _x_7 = ($U32$show$(($qt$(_t_0))));
  const _x_8 = (_x_7 + "n");
  const _x_9 = ($Nat$show$(_n_0));
  const _x_10 = ("n+" + _x_8);
  return $kp_par$((_x_9 + _x_10), (_p_0 > 2));
}));
}), run_clo((_x_11) => {
  return $kc$(($kp_is$(_t_0, "Ctr", "Zero")), run_clo((_x_12) => {
  const _x_13 = ($Nat$show$(_n_0));
  return (_x_13 + "n");
}), run_clo((_x_14) => {
  const _x_15 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($kp_is$(_t_0, "Ctr", "Succ")), (_x_15 === 1))), run_clo((_x_16) => {
  return $kp_nat$(run_loop($kid$(_t_0, 0)), nat_chk(_n_0 + 1), _p_0, _env_0);
}), run_clo((_x_17) => {
  const _x_18 = run_loop($kp_go$(_t_0, 2, _env_0));
  const _x_19 = ($Nat$show$(_n_0));
  const _x_20 = ("n+" + _x_18);
  return $kp_par$((_x_19 + _x_20), (_p_0 > 2));
}));
}));
}));
}

function $kp_ctor_char$(_c_0, _t_0, _p_0, _env_0) {
  if (_c_0.$ === "Some") {
    const _s_0 = _c_0["value"];
    const _x_0 = (_s_0 + "'");
    return ("'" + _x_0);
  } else {
    return $kp_ctor_string$(run_loop($kp_string$(_t_0)), _t_0, _p_0, _env_0);
  }
}

function $kp_char$(_t_0, _quote_0) {
  const _x_0 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($kp_is$(_t_0, "Ctr", "Chr")), (_x_0 === 1))), run_clo((_x_1) => {
  return $kp_char_num$(run_loop($kp_number$(run_loop($kid$(_t_0, 0)))), _quote_0);
}), run_clo((_x_2) => {
  return {$: "None"};
}));
}

function $g_snf_children$($0, $1, $2, $3, $4, $5, $6) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _parent_0 = $2;
      const _done_0 = $3;
      const _todo_0 = $4;
      const _stack_0 = $5;
      const _fresh_0 = $6;
      if (_todo_0.$ === "Nil") {
        $0 = _book_0;
        $1 = _st_0;
        $2 = {$: "KTerm", "tag": ($tg$(_parent_0)), "name": ($nm$(_parent_0)), "id": ($ix$(_parent_0)), "quant": ($qt$(_parent_0)), "kids": ($List$reverse$(_done_0)), "removed": ($rm$(_parent_0))};
        $3 = _stack_0;
        $4 = _fresh_0;
        $pc = 1; continue;
      } else {
        const _h_0 = _todo_0["head"];
        const _rest_0 = _todo_0["tail"];
        return $g_snf_go$(_book_0, _st_0, _h_0, {$: "Con", "head": {$: "KNormFrame", "parent": _parent_0, "done": _done_0, "todo": _rest_0}, "tail": _stack_0}, _fresh_0);
      }
    }
    case 1: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _t_0 = $2;
      const _stack_0 = $3;
      const _fresh_0 = $4;
      if (_stack_0.$ === "Nil") {
        return _t_0;
      } else {
        const _t_1 = _stack_0["head"];
        const _parent_0 = _t_1["parent"];
        const _done_0 = _t_1["done"];
        const _todo_0 = _t_1["todo"];
        const _rest_0 = _stack_0["tail"];
        $0 = _book_0;
        $1 = _st_0;
        $2 = _parent_0;
        $3 = {$: "Con", "head": _t_0, "tail": _done_0};
        $4 = _todo_0;
        $5 = _rest_0;
        $6 = _fresh_0;
        $pc = 0; continue;
      }
    }
  }
}

function $g_cell$(_book_0, _st_0, _t_0, _args_0, _pending_0, _fallback_0, _stack_0, _cell_0) {
  return $kc$(($String$eq$(($tg$(_cell_0)), "GValue")), run_clo((_x_0) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_cell_0, 0)), _args_0, _pending_0, _fallback_0, _stack_0);
}), run_clo((_x_1) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_cell_0, 0)), {$: "Nil"}, 0, ($atom$("Absent")), {$: "Con", "head": {$: "GFill", "id": ($ix$(_t_0)), "args": _args_0, "pending": _pending_0, "fallback": _fallback_0}, "tail": _stack_0});
}));
}

function $g_get$(_heap_0, _id_0) {
  if (_heap_0.$ === "GEmpty") {
    return $atom$("Absent");
  } else {
    const _value_0 = _heap_0["value"];
    const _left_0 = _heap_0["left"];
    const _right_0 = _heap_0["right"];
    return $kc$((_id_0 === 0), run_clo((_x_0) => {
  return _value_0;
}), run_clo((_x_1) => {
  const _x_2 = ((_id_0 & 1) >>> 0);
  return $kc$((_x_2 === 0), run_clo((_x_3) => {
  return $g_get$(_left_0, ((_id_0 >>> 1) >>> 0));
}), run_clo((_x_4) => {
  return $g_get$(_right_0, ((_id_0 >>> 1) >>> 0));
}));
}));
  }
}

function $g_heap$(_st_0) {
  const _heap_0 = _st_0["heap"];
  return _heap_0;
}

function $g_app$(_book_0, _fn_0, _args_0, _pending_0, _fallback_0, _stack_0, _r_0) {
  return $g_eval$(_book_0, ($g_state$(_r_0)), _fn_0, {$: "Con", "head": ($g_term$(_r_0)), "tail": _args_0}, _pending_0, _fallback_0, _stack_0);
}

function $g_share$(_st_0, _t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "GCell")), run_clo((_x_0) => {
  return {$: "GResult", "state": _st_0, "term": _t_0};
}), run_clo((_x_1) => {
  const _x_2 = ($g_next$(_st_0));
  return {$: "GResult", "state": {$: "GState", "heap": run_loop($g_put$(($g_heap$(_st_0)), ($g_next$(_st_0)), ($kt$("GThunk", "", 0, 0, {$: "Con", "head": _t_0, "tail": {$: "Nil"}})))), "next": ((_x_2 + 1) >>> 0)}, "term": ($kt$("GCell", "", ($g_next$(_st_0)), 0, {$: "Nil"}))};
}));
}

function $g_let$(_book_0, _st_0, _ts_0, _bindings_0, _args_0, _pending_0, _fallback_0, _stack_0) {
  if (_ts_0.$ === "Nil") {
    return $g_return$(_book_0, _st_0, ($atom$("Absent")), _stack_0);
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return $kc$(($String$eq$(($tg$(_h_0)), "Bind")), run_clo((_x_0) => {
  return $g_let_shared$(_book_0, _h_0, _rest_0, _bindings_0, _args_0, _pending_0, _fallback_0, _stack_0, run_loop($g_share$(_st_0, run_loop($kid$(_h_0, 0)))));
}), run_clo((_x_1) => {
  return $g_eval$(_book_0, _st_0, ($g_let_sub$(_h_0, _bindings_0)), _args_0, _pending_0, _fallback_0, _stack_0);
}));
  }
}

function $g_ref$(_book_0, _st_0, _t_0, _args_0, _stack_0, _d_0) {
  return $kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_0) => {
  const _x_1 = ($da$(_d_0));
  return $g_return$(_book_0, _st_0, ($norm_apply$(run_loop($kc$((_x_1 === 0), run_clo((_x_2) => {
  return $kt$("ADT", ($nm$(_t_0)), 0, 0, {$: "Nil"});
}), run_clo((_x_3) => {
  return _t_0;
}))), _args_0)), _stack_0);
}), run_clo((_x_4) => {
  const _x_5 = ($String$eq$(($tg$(($dv$(_d_0)))), "Absent"));
  const _x_6 = ($String$eq$(($tg$(($dv$(_d_0)))), "Foreign"));
  const _x_7 = ($da$(_d_0));
  const _x_8 = ($terms_len$(_args_0));
  return $kc$(($Bool$and$(($Bool$not$((_x_5 || _x_6))), (_x_7 <= _x_8))), run_clo((_x_9) => {
  return $g_eval$(_book_0, _st_0, ($dv$(_d_0)), _args_0, ($da$(_d_0)), ($norm_apply$(_t_0, _args_0)), _stack_0);
}), run_clo((_x_10) => {
  return $g_return$(_book_0, _st_0, ($norm_apply$(_t_0, _args_0)), _stack_0);
}));
}));
}

function $g_args$(_book_0, _st_0, _t_0, _args_0, _pending_0, _fallback_0, _stack_0) {
  if (_args_0.$ === "Nil") {
    return $g_return$(_book_0, _st_0, _t_0, _stack_0);
  } else {
    const _x_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_1) => {
  return $g_eval$(_book_0, _st_0, run_loop($subst$(run_loop($kid$(_t_0, 0)), ($ix$(_t_0)), _x_0)), _rest_0, run_loop($norm_dec$(_pending_0)), _fallback_0, _stack_0);
}), run_clo((_x_2) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Mat")), run_clo((_x_3) => {
  return $g_eval$(_book_0, _st_0, _x_0, {$: "Nil"}, 0, ($atom$("Absent")), {$: "Con", "head": {$: "GMatch", "arm": _t_0, "raw": _x_0, "args": _rest_0, "pending": _pending_0, "fallback": _fallback_0}, "tail": _stack_0});
}), run_clo((_x_4) => {
  return $g_return$(_book_0, _st_0, run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Efq")), (_pending_0 > 0))), run_clo((_x_5) => {
  return _fallback_0;
}), run_clo((_x_6) => {
  return $norm_apply$(_t_0, {$: "Con", "head": _x_0, "tail": _rest_0});
}))), _stack_0);
}));
}));
  }
}

function $sp_template_args$(_st_0, _d_0, _closed_0, _rest_0, _ctx_0, _owner_0, _depth_0) {
  return $sp_template_checked$(_st_0, _d_0, _closed_0, _rest_0, _ctx_0, _owner_0, _depth_0, run_loop($template_args$({$: "KEnv", "book": ($sp_book$(_st_0)), "name": _owner_0, "lhs": ($ref$(_owner_0)), "pending": 0, "quantities": {$: "Nil"}, "unsafe": ($du$(_d_0))}, ($dt$(_d_0)), _closed_0, ($dx$(_d_0)))));
}

function $sp_take$(_ts_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return $sp_take_next$(_ts_0, _n_0);
}));
}

function $sp_drop$(_ts_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return _ts_0;
}), run_clo((_x_1) => {
  return $sp_drop_next$(_ts_0, _n_0);
}));
}

function $sp_regular_done$(_xs_0, _ctx_0, _owner_0, _depth_0, _ty_0, _r_0) {
  return $sp_apply_result$(($sp_value$(_r_0)), ($sp_args$(($sp_state$(_r_0)), _xs_0, _ctx_0, _ty_0, _owner_0, _depth_0)));
}

function $sp_match_hit$(_t_0, _ctx_0, _goal_0, _owner_0, _depth_0, _a_0, _r_0) {
  return $sp_pair$(_t_0, ($sp_value$(_r_0)), run_loop($sp_term$(($sp_state$(_r_0)), run_loop($kid$(_t_0, 1)), _ctx_0, ($all$(($qt$(_goal_0)), ($nm$(_goal_0)), ($ix$(_goal_0)), {$: "KTerm", "tag": ($tg$(_a_0)), "name": ($nm$(_a_0)), "id": ($ix$(_a_0)), "quant": ($qt$(_a_0)), "kids": ($ks$(_a_0)), "removed": {$: "Con", "head": ($nm$(_t_0)), "tail": ($rm$(_a_0))}}, run_loop($kid$(_goal_0, 1)))), _owner_0, _depth_0)));
}

function $sp_arg_done$(_raw_0, _rest_0, _ctx_0, _ty_0, _owner_0, _depth_0, _r_0) {
  return $sp_cons$(($sp_value$(_r_0)), ($sp_args$(($sp_state$(_r_0)), _rest_0, _ctx_0, run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), _raw_0)), _owner_0, _depth_0)));
}

function $sp_cons$(_h_0, _r_0) {
  return {$: "KSpecTerms", "state": ($sp_states$(_r_0)), "terms": {$: "Con", "head": _h_0, "tail": ($sp_values$(_r_0))}};
}

function $dg_trace$(_e_0, _ctx_0, _t_0, _ty_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return _r_0;
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(($ct$(_r_0)))), "DTrace")), run_clo((_x_2) => {
  return {$: "KChecked", "term": ($kt$("DTrace", ($nm$(($ct$(_r_0)))), ($ix$(($ct$(_r_0)))), ($qt$(($ct$(_r_0)))), {$: "Con", "head": run_loop($kid$(($ct$(_r_0)), 0)), "tail": {$: "Con", "head": run_loop($kid$(($ct$(_r_0)), 1)), "tail": {$: "Con", "head": run_loop($kid$(($ct$(_r_0)), 2)), "tail": {$: "Con", "head": run_loop($kid$(($ct$(_r_0)), 3)), "tail": {$: "Con", "head": ($kt$("DTrail", "", 0, 0, ($norm_join$(($ks$(run_loop($kid$(($ct$(_r_0)), 4)))), {$: "Con", "head": _t_0, "tail": {$: "Nil"}})))), "tail": {$: "Nil"}}}}}})), "typ": ($cy$(_r_0)), "uses": ($cs$(_r_0)), "error": ($ce$(_r_0))};
}), run_clo((_x_3) => {
  return $dg_trace_detail$(_e_0, _ctx_0, _t_0, _r_0, run_loop($kc$(($String$eq$(($tg$(($ct$(_r_0)))), "DDetail")), run_clo((_x_4) => {
  return $ct$(_r_0);
}), run_clo((_x_5) => {
  return $dg_reason$(_e_0, _ctx_0, _t_0, _ty_0, ($ce$(_r_0)));
}))));
}));
}));
}

function $infer_node$(_e_0, _ctx_0, _t_0, _dem_0, _sp_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_0) => {
  return $infer_var$(_ctx_0, _t_0, _dem_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ref")), run_clo((_x_2) => {
  return $infer_ref$(_e_0, _t_0, _dem_0, _sp_0, run_loop($lookup$(($cb$(_e_0)), ($nm$(_t_0)))));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Typ")), run_clo((_x_4) => {
  return $checked$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), 0, ($atom$("Qnt")))), _t_0, ($typ$(1)));
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Qnt")), run_clo((_x_6) => {
  return $ok$(_t_0, ($typ$(1)), {$: "Nil"});
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Qua")), run_clo((_x_8) => {
  return $ok$(_t_0, ($atom$("Qnt")), {$: "Nil"});
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Min")), run_clo((_x_10) => {
  return $both$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), _dem_0, ($atom$("Qnt")))), run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), _dem_0, ($atom$("Qnt")))), _t_0, ($atom$("Qnt")), false);
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "All")), run_clo((_x_12) => {
  return $both$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), 0, ($typ$(run_loop($kindq$(_e_0, ($qt$(_t_0)))))))), run_loop($check$(_e_0, ($ctx_bind$(_ctx_0, ($ix$(_t_0)), ($qt$(_t_0)), ($nm$(_t_0)), run_loop($kid$(_t_0, 0)))), run_loop($kid$(_t_0, 1)), 0, ($typ$(1)))), _t_0, ($typ$(1)), false);
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_14) => {
  return $infer_app$(_e_0, _ctx_0, _t_0, _dem_0, run_loop($infer$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), _dem_0, {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _sp_0})));
}), run_clo((_x_15) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "ADT")), run_clo((_x_16) => {
  return $infer_adt$(_e_0, _ctx_0, _t_0, _dem_0, run_loop($lookup$(($cb$(_e_0)), ($nm$(_t_0)))));
}), run_clo((_x_17) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Eql")), run_clo((_x_18) => {
  return $both$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 2)), 0, ($typ$(1)))), run_loop($both$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), 0, run_loop($kid$(_t_0, 2)))), run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), 0, run_loop($kid$(_t_0, 2)))), _t_0, ($typ$(2)), false)), _t_0, ($typ$(2)), false);
}), run_clo((_x_19) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_20) => {
  return $both$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), 0, ($typ$(1)))), run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), _dem_0, run_loop($kid$(_t_0, 1)))), run_loop($kid$(_t_0, 0)), run_loop($kid$(_t_0, 1)), false);
}), run_clo((_x_21) => {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_22) => {
  return $infer$(_e_0, _ctx_0, run_loop($core_nat_step$(_t_0)), _dem_0, _sp_0);
}), run_clo((_x_23) => {
  return $bad$("cannot infer: annotation required");
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $nt_replace_step$(_s_0, _key_0, _value_0, _acc_0) {
  if (_s_0 === "") {
    return _acc_0;
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_0 = (_h_0 + "");
    return $nt_replace_go$(_t_0, _key_0, _value_0, (_acc_0 + _x_0));
  }
}

function $nb_width_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _t_0 = _ss_0["head"];
        const _ps_0 = _t_0["params"];
        const _r_0 = _t_0["result"];
        const _t_1 = _ss_0["tail"];
        $0 = _t_1;
        $1 = run_loop($nb_max$(_acc_0, run_loop($nb_max$(($nt_count$(_ps_0)), _r_0))));
        continue;
      }
    }
  }
}

function $nb_returns_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _t_0 = _ss_0["head"];
        const _r_0 = _t_0["result"];
        const _t_1 = _ss_0["tail"];
        $0 = _t_1;
        $1 = run_loop($nb_max$(_acc_0, _r_0));
        continue;
      }
    }
  }
}

function $nb_bangs_go$($0, $1) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _acc_0 = $1;
      if (_ss_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _t_0 = _ss_0["head"];
        const _bang_0 = _t_0["bang"];
        const _t_1 = _ss_0["tail"];
        const _x_0 = ($nt_bool$(_bang_0));
        $0 = _t_1;
        $1 = ((_acc_0 + _x_0) >>> 0);
        continue;
      }
    }
  }
}

function $nb_reaches$(_xs_0, _roots_0) {
  if (_xs_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    const _x_0 = ($nb_contains$(_roots_0, _h_0));
    const _x_1 = ($nb_reaches$(_t_0, _roots_0));
    return (_x_0 || _x_1);
  }
}

function $nb_frame_results$(_f_0, _n_0) {
  if (_f_0.$ === "N_Direct") {
    return 0;
  } else {
    const _at_0 = _f_0["slots"];
    const _x_0 = ($nt_count$(_at_0));
    return ((_n_0 - _x_0) >>> 0);
  }
}

function $ne_take$(_ps_0, _f_0) {
  if (_f_0.$ === "N_Direct") {
    return $ne_take_params$(_ps_0, {$: "Nil"}, 0);
  } else {
    const _pop_0 = _f_0["pop"];
    const _at_0 = _f_0["slots"];
    const _x_4 = run_loop($nt_choose$((_pop_0 === 0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = ($U32$show$(_pop_0));
  const _x_3 = (_x_2 + ");\n");
  return ("    WL_POPN(" + _x_3);
})));
    const _x_5 = ($ne_take_params$(_ps_0, _at_0, 0));
    return (_x_4 + _x_5);
  }
}

function $nt_indent$(_s_0) {
  const _x_0 = ($nt_lines$(_s_0));
  return ("    " + _x_0);
}

function $norm_compare$(_book_0, _a_0, _b_0, _le_0, _fresh_0) {
  return $kc$(run_loop($norm_exact$(_a_0, _b_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": _a_0, "b": _b_0, "le": _le_0, "fresh": _fresh_0}, "tail": {$: "Nil"}}, {$: "Nil"});
}));
}

function $nc_show_arm$(_book_0, _c_0, _rest_0, _args_0, _d_0) {
  return $nc_desc_join$({$: "NC_Desc", "cells": {$: "Con", "head": ($nt_cid$(run_loop($nc_ctor_identity$(_book_0, ($dn$(_c_0)))))), "tail": {$: "Con", "head": ($nt_cid$(run_loop($nc_ctor_identity$(_book_0, ($dn$(_c_0)))))), "tail": {$: "Con", "head": ($U32$show$(($da$(_c_0)))), "tail": ($nc_desc_cells$(_d_0))}}}, "types": ($nc_desc_types$(_d_0)), "error": ($nc_desc_error$(_d_0))}, ($nc_show_arms$(_book_0, _rest_0, _args_0, ($nc_desc_types$(_d_0)))));
}

function $nc_show_fields$(_book_0, _tel_0, _left_0, _i_0, _types_0) {
  return $nt_choose$((_left_0 === 0), run_clo((_x_0) => {
  return {$: "NC_Desc", "cells": {$: "Nil"}, "types": _types_0, "error": ""};
}), run_clo((_x_1) => {
  const _x_2 = ($qt$(run_loop($wnf$(_book_0, _tel_0))));
  return $nt_choose$((_x_2 === 0), run_clo((_x_3) => {
  return {$: "NC_Desc", "cells": {$: "Nil"}, "types": _types_0, "error": "native readback cannot print an erased field"};
}), run_clo((_x_4) => {
  return $nc_show_field$(_book_0, run_loop($wnf$(_book_0, _tel_0)), _left_0, _i_0, run_loop($nc_show_ref$(_book_0, run_loop($kid$(run_loop($wnf$(_book_0, _tel_0)), 0)), _types_0)));
}));
}));
}

function $ne_closure_wrap$(_k_0, _x_0) {
  const _code_0 = _x_0["code"];
  const _value_0 = _x_0["value"];
  const _n_0 = _x_0["fresh"];
  const _x_1 = (_value_0 + ")");
  const _x_2 = ($nt_fid$(_k_0));
  const _x_3 = (", " + _x_1);
  const _x_4 = (_x_2 + _x_3);
  return {$: "N_Emitted", "code": _code_0, "value": ("term_clo(" + _x_4), "fresh": _n_0};
}

function $ne_node$(_prefix_0, _alloc_0, _ws_0, _n_0, _seal_0) {
  const _name_0 = ($nt_local$(_prefix_0, _n_0));
  const _x_0 = ($ne_stores$(_name_0, _ws_0, 0, _seal_0));
  const _x_1 = (";\n" + _x_0);
  const _x_2 = (_alloc_0 + _x_1);
  const _x_3 = (" = " + _x_2);
  const _x_4 = (_name_0 + _x_3);
  return {$: "N_Emitted", "code": ("u64 " + _x_4), "value": _name_0, "fresh": ((_n_0 + 1) >>> 0)};
}

function $nc_mklet$(_id_0, _val_0, _body_0) {
  return $kt$("Let", "", 0, 0, {$: "Con", "head": ($kt$("Bind", "", _id_0, 1, {$: "Con", "head": _val_0, "tail": {$: "Nil"}})), "tail": {$: "Con", "head": _body_0, "tail": {$: "Nil"}}});
}

function $nd_reapply$($0, $1) {
  for (;;) {
    {
      const _head_0 = $0;
      const _args_0 = $1;
      if (_args_0.$ === "Nil") {
        return _head_0;
      } else {
        const _h_0 = _args_0["head"];
        const _rest_0 = _args_0["tail"];
        $0 = ($app$(_head_0, _h_0));
        $1 = _rest_0;
        continue;
      }
    }
  }
}

function $nd_foreign_arity$(_book_0, _ty_0, _n_0) {
  const _tel_0 = run_loop($wnf$(_book_0, _ty_0));
  return $nt_choose$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_tel_0));
  const _x_2 = ($nt_bool$(($Bool$not$((_x_1 === 0)))));
  return $nd_foreign_arity$(_book_0, run_loop($kid$(_tel_0, 1)), ((_n_0 + _x_2) >>> 0));
}), run_clo((_x_3) => {
  return _n_0;
}));
}

function $nd_leading$(_t_0, _n_0) {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Ann")), run_clo((_x_0) => {
  return $nd_leading$(run_loop($kid$(_t_0, 0)), _n_0);
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_2) => {
  const _x_3 = ($qt$(_t_0));
  const _x_4 = ($nt_bool$(($Bool$not$((_x_3 === 0)))));
  return $nd_leading$(run_loop($kid$(_t_0, 0)), ((_n_0 + _x_4) >>> 0));
}), run_clo((_x_5) => {
  return _n_0;
}));
}));
}

function $nc_parallel_finish$(_env_0, _xs_0, _name_0, _join_0, _seq_0, _children_0, _em_0, _params_0) {
  const _code_0 = _em_0["code"];
  const _word_0 = _em_0["value"];
  const _x_0 = ($nc_body$(_seq_0));
  const _x_1 = (");\n}\n" + _x_0);
  const _x_2 = (_word_0 + _x_1);
  const _x_3 = ($nt_fid$(_name_0));
  const _x_4 = (", " + _x_2);
  const _x_5 = (_x_3 + _x_4);
  const _x_6 = ($nc_body$(_children_0));
  const _x_7 = ("return term_tsk(" + _x_5);
  const _x_8 = (_x_6 + _x_7);
  const _x_9 = ($nc_parallel_share$(_env_0, _xs_0));
  const _x_10 = (_code_0 + _x_8);
  const _x_11 = (_x_9 + _x_10);
  return {$: "NC_Code", "body": ("if (!seq) {\n" + _x_11), "segments": {$: "Con", "head": {$: "N_Segment", "name": _name_0, "params": ($nc_params$(_params_0)), "result": 1, "frame": {$: "N_Direct"}, "body": ($nc_body$(_join_0)), "refs": {$: "Nil"}, "host": false, "spin": false, "fork": true, "bang": false}, "tail": ($nt_append$(($nc_segs$(_join_0)), ($nt_append$(($nc_segs$(_seq_0)), ($nc_segs$(_children_0))))))}, "fresh": ($nc_fresh$(_children_0)), "error": run_loop($nt_choose$(($String$eq$(run_loop($nc_first_error$(_seq_0, _join_0)), "")), run_clo((_x_12) => {
  return $nc_error$(_children_0);
}), run_clo((_x_13) => {
  return $nc_first_error$(_seq_0, _join_0);
})))};
}

function $nc_children$(_book_0, _xs_0, _env_0, _joinname_0, _joinword_0, _idx_0, _n_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "NC_Code", "body": "", "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    if (_t_0.$ === "Nil") {
      return {$: "NC_Code", "body": "", "segments": {$: "Nil"}, "fresh": _n_0, "error": ""};
    } else {
      const _name_0 = ($nc_name$(_n_0));
      const _caps_0 = run_loop($nc_live_env$(_env_0, run_loop($kid$(_h_0, 0))));
      const _code_0 = ($nc_lower$(_book_0, run_loop($kid$(_h_0, 0)), _caps_0, ((_n_0 + 1) >>> 0)));
      const _calls_0 = ($nc_local_calls$(_book_0, ($nc_refs$(run_loop($kid$(_h_0, 0))))));
      const _forked_0 = run_loop($nc_term_fork$(run_loop($kid$(_h_0, 0))));
      const _x_0 = (_joinword_0 + ")");
      const _x_1 = ($nt_fid$(_joinname_0));
      const _x_2 = (", " + _x_0);
      const _x_3 = (_x_1 + _x_2);
      const _task_0 = ($ne_task$(_name_0, 0, ($nc_words$(_caps_0)), ("term_tsk(" + _x_3), ($U32$show$(_idx_0)), ($nc_fresh$(_code_0))));
      const _x_4 = ($nc_fresh$(_code_0));
      const _next_0 = ($nc_children$(_book_0, _t_0, _env_0, _joinname_0, _joinword_0, ((_idx_0 + 1) >>> 0), ((_x_4 + 1) >>> 0)));
      const _x_5 = ($nc_child_task$(_name_0, _joinword_0, _idx_0, _task_0));
      const _x_6 = ($nc_body$(_next_0));
      return {$: "NC_Code", "body": (_x_5 + _x_6), "segments": {$: "Con", "head": {$: "N_Segment", "name": _name_0, "params": ($nc_params$(_caps_0)), "result": 1, "frame": {$: "N_Direct"}, "body": ($nc_body$(_code_0)), "refs": _calls_0, "host": false, "spin": false, "fork": _forked_0, "bang": false}, "tail": ($nt_append$(($nc_local_segments$(($nc_segs$(_code_0)), _calls_0, _forked_0, {$: "Nil"})), ($nc_segs$(_next_0))))}, "fresh": ($nc_fresh$(_next_0)), "error": run_loop($nc_first_error$(_code_0, _next_0))};
    }
  }
}

function $nc_slots$(_env_0, _i_0) {
  if (_env_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _rest_0 = _env_0["tail"];
    return {$: "Con", "head": ($U32$show$(_i_0)), "tail": ($nc_slots$(_rest_0, ((_i_0 + 1) >>> 0)))};
  }
}

function $nc_share_env$(_env_0, _a_0, _b_0) {
  if (_env_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _env_0["head"];
    const _id_0 = _t_0["id"];
    const _word_0 = _t_0["word"];
    const _rest_0 = _env_0["tail"];
    const _x_4 = run_loop($nt_choose$(($Bool$and$(run_loop($nc_occurs$(_a_0, _id_0)), run_loop($nc_occurs$(_b_0, _id_0)))), run_clo((_x_0) => {
  const _x_1 = (_word_0 + ");\n");
  const _x_2 = (" = term_keep(e, " + _x_1);
  return (_word_0 + _x_2);
}), run_clo((_x_3) => {
  return "";
})));
    const _x_5 = ($nc_share_env$(_rest_0, _a_0, _b_0));
    return (_x_4 + _x_5);
  }
}

function $nc_cut$(_ws_0, _next_0, _n_0) {
  const _x_0 = ($nc_cut_task$(_next_0, _ws_0, ($ne_task$(_next_0, 1, _ws_0, "WL_CONT", "WL_IDX", _n_0))));
  const _x_1 = (_x_0 + "}\n");
  const _x_2 = ($ne_frame$(_ws_0, _next_0));
  const _x_3 = ("} else {\n" + _x_1);
  const _x_4 = (_x_2 + _x_3);
  return ("if (seq) {\n" + _x_4);
}

function $ne_wrap_ctor$(_k_0, _x_0) {
  const _code_0 = _x_0["code"];
  const _value_0 = _x_0["value"];
  const _n_0 = _x_0["fresh"];
  const _x_1 = (_value_0 + ")");
  const _x_2 = ($nt_cid$(_k_0));
  const _x_3 = (", " + _x_1);
  const _x_4 = (_x_2 + _x_3);
  return {$: "N_Emitted", "code": _code_0, "value": ("term_ctr(" + _x_4), "fresh": _n_0};
}

function $np_supported$(_term_0) {
  const _x_0 = ($ix$(_term_0));
  const _x_1 = ($ix$(_term_0));
  const _x_2 = (_x_0 === 0);
  const _x_3 = (_x_1 === 1);
  const _x_4 = ($ix$(_term_0));
  const _x_5 = ($ix$(_term_0));
  const _x_6 = (_x_4 === 0);
  const _x_7 = (_x_5 === 2);
  const _x_8 = ($Bool$and$(($String$eq$(($nm$(_term_0)), "Zero")), (_x_2 || _x_3)));
  const _x_9 = ($Bool$and$(($String$eq$(($nm$(_term_0)), "Succ")), (_x_6 || _x_7)));
  return $Bool$and$(($String$eq$(($tg$(_term_0)), "Mat")), (_x_8 || _x_9));
}

function $np_level_valid$(_level_0) {
  const _hasZero_0 = _level_0["hasZero"];
  const _hasSucc_0 = _level_0["hasSucc"];
  const _valid_0 = _level_0["valid"];
  return $Bool$and$(_valid_0, (_hasZero_0 || _hasSucc_0));
}

function $np_level$(_term_0, _zero_0, _successor_0, _hasZero_0, _hasSucc_0) {
  return $nt_choose$(($String$eq$(($tg$(_term_0)), "Mat")), run_clo((_x_0) => {
  return $np_level_mat$(_term_0, _zero_0, _successor_0, _hasZero_0, _hasSucc_0);
}), run_clo((_x_1) => {
  return {$: "NPLevel", "zero": _zero_0, "successor": _successor_0, "fallback": _term_0, "hasZero": _hasZero_0, "hasSucc": _hasSucc_0, "valid": true};
}));
}

function $np_emit$(_book_0, _rows_0, _word_0, _env_0, _next_0) {
  if (_rows_0.$ === "Nil") {
    return $nc_fail$("empty Nat pattern chain", _next_0);
  } else {
    const _row_0 = _rows_0["head"];
    const _rest_0 = _rows_0["tail"];
    return $np_emit_row$(_book_0, _row_0, _rest_0, _word_0, _env_0, _next_0);
  }
}

function $np_collect$(_term_0, _depth_0, _built_0) {
  return $np_collect_level$(_term_0, _depth_0, _built_0, run_loop($np_level$(_term_0, ($atom$("Efq")), ($atom$("Efq")), false, false)));
}

function $nc_remove_env$(_env_0, _id_0) {
  if (_env_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _env_0["head"];
    const _at_0 = _t_0["id"];
    const _word_0 = _t_0["word"];
    const _rest_0 = _env_0["tail"];
    return $nt_choose$((_at_0 === _id_0), run_clo((_x_0) => {
  return _rest_0;
}), run_clo((_x_1) => {
  return {$: "Con", "head": {$: "NC_Binding", "id": _at_0, "word": _word_0}, "tail": run_loop($nc_remove_env$(_rest_0, _id_0))};
}));
  }
}

function $nc_field_count$(_book_0, _name_0) {
  const _x_0 = ($String$eq$(_name_0, "Succ"));
  const _x_1 = ($String$eq$(_name_0, "Chr"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(_name_0, "U32"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($String$eq$(_name_0, "F32"));
  return $nt_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  return 1;
}), run_clo((_x_7) => {
  const _x_8 = ($String$eq$(_name_0, "Zero"));
  const _x_9 = ($String$eq$(_name_0, "True"));
  const _x_10 = (_x_8 || _x_9);
  const _x_11 = ($String$eq$(_name_0, "False"));
  return $nt_choose$((_x_10 || _x_11), run_clo((_x_12) => {
  return 0;
}), run_clo((_x_13) => {
  return $da$(run_loop($nc_find_ctor$(_book_0, run_loop($nc_ctor_display$(_name_0)))));
}));
}));
}

function $nc_field_apps$(_term_0, _count_0, _i_0, _n_0) {
  return $nt_choose$((_i_0 === _count_0), run_clo((_x_0) => {
  return _term_0;
}), run_clo((_x_1) => {
  return $nc_field_apps$(($app$(_term_0, ($var$("", ($nc_id$(((_n_0 + _i_0) >>> 0))))))), _count_0, ((_i_0 + 1) >>> 0), _n_0);
}));
}

function $nc_field_env$(_name_0, _word_0, _count_0, _i_0, _n_0) {
  return $nt_choose$((_i_0 === _count_0), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return {$: "Con", "head": ($nc_binding$(($nc_id$(((_n_0 + _i_0) >>> 0))))), "tail": run_loop($nc_field_env$(_name_0, _word_0, _count_0, ((_i_0 + 1) >>> 0), _n_0))};
}));
}

function $nc_condition$(_name_0, _word_0) {
  return $nt_choose$(($String$eq$(_name_0, "False")), run_clo((_x_0) => {
  const _x_1 = (_word_0 + "))");
  return ("(!native_bool(" + _x_1);
}), run_clo((_x_2) => {
  return $nt_choose$(($String$eq$(_name_0, "True")), run_clo((_x_3) => {
  const _x_4 = (_word_0 + ")");
  return ("native_bool(" + _x_4);
}), run_clo((_x_5) => {
  return $nt_choose$(($String$eq$(_name_0, "Zero")), run_clo((_x_6) => {
  const _x_7 = (_word_0 + " == 0)");
  return ("(" + _x_7);
}), run_clo((_x_8) => {
  return $nt_choose$(($String$eq$(_name_0, "Succ")), run_clo((_x_9) => {
  const _x_10 = (_word_0 + " != 0)");
  return ("(" + _x_10);
}), run_clo((_x_11) => {
  const _x_12 = ($String$eq$(_name_0, "Chr"));
  const _x_13 = ($String$eq$(_name_0, "U32"));
  const _x_14 = (_x_12 || _x_13);
  const _x_15 = ($String$eq$(_name_0, "F32"));
  return $nt_choose$((_x_14 || _x_15), run_clo((_x_16) => {
  return "1";
}), run_clo((_x_17) => {
  return $nt_choose$(($String$eq$(_name_0, "ALeaf")), run_clo((_x_18) => {
  const _x_19 = (_word_0 + ") == 0)");
  return ("(blk_cls(" + _x_19);
}), run_clo((_x_20) => {
  return $nt_choose$(($String$eq$(_name_0, "ANode")), run_clo((_x_21) => {
  const _x_22 = (_word_0 + ") != 0)");
  return ("(blk_cls(" + _x_22);
}), run_clo((_x_23) => {
  const _x_24 = ($nt_cid$(_name_0));
  const _x_25 = (_x_24 + ")");
  const _x_26 = (") == " + _x_25);
  const _x_27 = (_word_0 + _x_26);
  return ("(term_aux(" + _x_27);
}));
}));
}));
}));
}));
}));
}));
}

function $nc_destructure$(_name_0, _word_0, _count_0, _n_0) {
  const _x_0 = ($String$eq$(_name_0, "Succ"));
  const _x_1 = ($String$eq$(_name_0, "Zero"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(_name_0, "True"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($String$eq$(_name_0, "False"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($String$eq$(_name_0, "Chr"));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($String$eq$(_name_0, "U32"));
  const _x_10 = (_x_8 || _x_9);
  const _x_11 = ($String$eq$(_name_0, "F32"));
  const _x_12 = (_x_10 || _x_11);
  const _x_13 = ($String$eq$(_name_0, "ALeaf"));
  const _x_14 = (_x_12 || _x_13);
  const _x_15 = ($String$eq$(_name_0, "ANode"));
  const _boxed_0 = ($Bool$and$(($Bool$not$((_x_14 || _x_15))), (_count_0 > 0)));
  const _x_43 = run_loop($nc_field_decls$(_name_0, _word_0, _count_0, 0, _n_0, _boxed_0));
  const _x_44 = run_loop($nt_choose$(($String$eq$(_name_0, "ALeaf")), run_clo((_x_40) => {
  const _x_41 = (_word_0 + ");\n");
  return ("blk_free(e, " + _x_41);
}), run_clo((_x_42) => {
  return "";
})));
  const _x_45 = run_loop($nt_choose$(_boxed_0, run_clo((_x_16) => {
  const _x_24 = run_loop($nt_choose$((_count_0 === 1), run_clo((_x_22) => {
  return "}\n";
}), run_clo((_x_23) => {
  return "";
})));
  const _x_25 = ($U32$show$(_count_0));
  const _x_26 = (", fields));\n" + _x_24);
  const _x_27 = (_x_25 + _x_26);
  const _x_28 = (", " + _x_27);
  const _x_29 = (_word_0 + _x_28);
  const _x_30 = ($U32$show$(_count_0));
  const _x_31 = ("), ctr_take(e, " + _x_29);
  const _x_32 = (_x_30 + _x_31);
  const _x_33 = run_loop($nt_choose$((_count_0 === 1), run_clo((_x_17) => {
  const _x_18 = (_word_0 + "); } else {\n");
  const _x_19 = (") == TAG_PAK) { fields[0] = term_loc(" + _x_18);
  const _x_20 = (_word_0 + _x_19);
  return ("if (term_tag(" + _x_20);
}), run_clo((_x_21) => {
  return "";
})));
  const _x_34 = ("spare_free(e, cls_fit(" + _x_32);
  const _x_35 = (_x_33 + _x_34);
  const _x_36 = ($U32$show$(_count_0));
  const _x_37 = ("];\n" + _x_35);
  const _x_38 = (_x_36 + _x_37);
  return ("Term fields[" + _x_38);
}), run_clo((_x_39) => {
  return "";
})));
  const _x_46 = (_x_43 + _x_44);
  return (_x_45 + _x_46);
}

function $nc_array_pair$(_code_0, _a_0, _b_0, _n_0) {
  return $nc_prepend$(_code_0, ($nc_ctor_result$(run_loop($ne_constructor$("Tuple", {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}}, false, _n_0, true)))));
}

function $ni_fill$($0, $1, $2) {
  for (;;) {
    {
      const _s_0 = $0;
      const _xs_0 = $1;
      const _i_0 = $2;
      if (_xs_0.$ === "Nil") {
        return _s_0;
      } else {
        const _h_0 = _xs_0["head"];
        const _t_0 = _xs_0["tail"];
        const _x_0 = ($U32$show$(_i_0));
        $0 = run_loop($ni_replace_all$(_s_0, ("$" + _x_0), _h_0));
        $1 = _t_0;
        $2 = ((_i_0 + 1) >>> 0);
        continue;
      }
    }
  }
}

function $fpe_terms_next$(_error_0, _rest_0) {
  return $f_choose$(($f_eq$(($tg$(_error_0)), "Absent")), run_clo((_x_0) => {
  return $fpe_terms$(_rest_0);
}), run_clo((_x_1) => {
  return _error_0;
}));
}

function $fpe_term$(_t_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Error")), run_clo((_x_0) => {
  return $f_choose$(($String$is_empty$(($nm$(_t_0)))), run_clo((_x_1) => {
  return $atom$("Absent");
}), run_clo((_x_2) => {
  return _t_0;
}));
}), run_clo((_x_3) => {
  return $fpe_terms$(($ks$(_t_0)));
}));
}

function $f_graph_finish_alias$(_s_0, _ns_0, _book_0, _imports_0, _prior_0, _err_0, _done_0) {
  return {$: "FGraph", "book": ($norm_defs_join$(_prior_0, ($f_path_defs$(($f_module_defs$(_book_0, _book_0, run_loop($f_family_book$(_prior_0)), _ns_0, _imports_0)), run_loop($f_path_dir$(($f_source_path$(_s_0)))), ($f_eq$(($f_source_name$(_s_0)), "Base")))))), "error": _err_0, "done": {$: "Con", "head": ($kt$("Loaded", ($f_source_path$(_s_0)), ($f_graph_count_defs$(_book_0, 0)), 0, {$: "Con", "head": ($ref$(_ns_0)), "tail": {$: "Nil"}})), "tail": _done_0}};
}

function $f_alias_defs$(_ds_0, _imports_0, _scope_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return {$: "Con", "head": {$: "KDef", "name": ($dn$(_d_0)), "kind": ($dk$(_d_0)), "arity": ($da$(_d_0)), "templates": ($dx$(_d_0)), "typ": run_loop($f_alias_term$(($dt$(_d_0)), _imports_0, _scope_0)), "value": run_loop($f_alias_term$(($dv$(_d_0)), _imports_0, _scope_0)), "ctors": ($f_alias_defs$(($dc$(_d_0)), _imports_0, _scope_0)), "native": ($db$(_d_0)), "unsafe": ($du$(_d_0))}, "tail": ($f_alias_defs$(_rest_0, _imports_0, _scope_0))};
  }
}

function $f_path_normal$(_s_0) {
  return $f_path_parts$(_s_0, "", {$: "Nil"}, ($Char$is_eq$(($f_head$(_s_0)), "/")));
}

function $f_strip_bend$(_s_0) {
  return $String$reverse$(run_loop($f_drop_chars$(($String$reverse$(_s_0)), 5)));
}

function $f_relative_parts$(_root_0, _file_0) {
  if (_root_0.$ === "Con") {
    const _r_0 = _root_0["head"];
    const _rs_0 = _root_0["tail"];
    if (_file_0.$ === "Con") {
      const _f_0 = _file_0["head"];
      const _fs_0 = _file_0["tail"];
      return $f_choose$(($String$eq$(_r_0, _f_0)), run_clo((_x_0) => {
  return $f_relative_parts$(_rs_0, _fs_0);
}), run_clo((_x_1) => {
  const _x_2 = ($f_relative_parents$({$: "Con", "head": _r_0, "tail": _rs_0}));
  const _x_3 = ($f_path_join_parts$({$: "Con", "head": _f_0, "tail": _fs_0}, ""));
  return (_x_2 + _x_3);
}));
    } else {
      const _x_4 = ($f_relative_parents$({$: "Con", "head": _r_0, "tail": _rs_0}));
      const _x_5 = ($f_path_join_parts$(_file_0, ""));
      return (_x_4 + _x_5);
    }
  } else {
    const _x_6 = ($f_relative_parents$(_root_0));
    const _x_7 = ($f_path_join_parts$(_file_0, ""));
    return (_x_6 + _x_7);
  }
}

function $f_path_segments$(_path_0) {
  return $f_path_nonempty$(($String$split$(_path_0, "/")));
}

function $ct$(_r_0) {
  const _term_0 = _r_0["term"];
  return _term_0;
}

function $dg_as_expr$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "DText")), run_clo((_x_0) => {
  return {$: "DText", "text": ($nm$(_t_0))};
}), run_clo((_x_1) => {
  return {$: "DTerm", "term": _t_0};
}));
}

function $bad$(_msg_0) {
  return {$: "KChecked", "term": ($atom$("Error")), "typ": ($atom$("Error")), "uses": {$: "Nil"}, "error": _msg_0};
}

function $check_adt_declaration$(_e_0, _d_0) {
  return $kc$(($String$eq$(($tg$(run_loop($tele_tip$(($cb$(_e_0)), ($dt$(_d_0)))))), "Typ")), run_clo((_x_0) => {
  return $check_ctors$(_e_0, _d_0, ($dc$(_d_0)), ($dt$(_d_0)));
}), run_clo((_x_1) => {
  return "datatype declaration must return a kind";
}));
}

function $check_foreign$(_book_0, _d_0) {
  const _x_0 = ($dx$(_d_0));
  return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$((_x_0 === 0), ($String$eq$(($tg$(run_loop($foreign_head$(run_loop($foreign_tip$(($dt$(_d_0)))))))), "Ref")))), ($String$eq$(($nm$(run_loop($foreign_head$(run_loop($foreign_tip$(($dt$(_d_0)))))))), "IO")))), ($String$eq$(($dk$(run_loop($lookup$(_book_0, "IO")))), "Def")))), ($db$(run_loop($lookup$(_book_0, "IO")))))), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  return "foreign definition must return base IO directly";
}));
}

function $check_template_definition$(_book_0, _d_0, _ty_0, _body_0, _lhs_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return $check$({$: "KEnv", "book": _book_0, "name": ($dn$(_d_0)), "lhs": _lhs_0, "pending": run_loop($self_pending$(_d_0, _body_0)), "quantities": run_loop($tele_quantities$(_book_0, ($dt$(_d_0)), ($da$(_d_0)))), "unsafe": ($du$(_d_0))}, {$: "Nil"}, _body_0, 1, _ty_0);
}), run_clo((_x_1) => {
  return $check_template_binder$(_book_0, _d_0, run_loop($wnf$(_book_0, _ty_0)), _body_0, _lhs_0, _n_0);
}));
}

function $check_node$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0) {
  return $kc$(run_loop($core_nat$(_t_0)), run_clo((_x_0) => {
  return $kc$(($core_nat_type$(($cb$(_e_0)), run_loop($wnf$(($cb$(_e_0)), _ty_0)))), run_clo((_x_1) => {
  return $ok$(_t_0, _ty_0, {$: "Nil"});
}), run_clo((_x_2) => {
  return $check$(_e_0, _ctx_0, run_loop($core_nat_step$(_t_0)), _dem_0, _ty_0);
}));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_4) => {
  return $check_lam$(_e_0, _ctx_0, _t_0, _dem_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)));
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_6) => {
  return $check_ctr$(_e_0, _ctx_0, _t_0, _dem_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)));
}), run_clo((_x_7) => {
  const _x_8 = ($String$eq$(($tg$(_t_0)), "Mat"));
  const _x_9 = ($String$eq$(($tg$(_t_0)), "Efq"));
  return $kc$((_x_8 || _x_9), run_clo((_x_10) => {
  return $check_mat$(_e_0, _ctx_0, _t_0, _dem_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)));
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rfl")), run_clo((_x_12) => {
  return $check_rfl$(_e_0, _t_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)));
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Hol")), run_clo((_x_14) => {
  return $bad$("unresolved hole");
}), run_clo((_x_15) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Let")), run_clo((_x_16) => {
  return $check_let$(_e_0, _ctx_0, _ctx_0, ($ks$(_t_0)), _dem_0, _ty_0, {$: "Nil"}, {$: "Nil"});
}), run_clo((_x_17) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_18) => {
  return $check_rwt$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, run_loop($infer$(_e_0, _ctx_0, run_loop($kid$(_t_0, 0)), _dem_0, {$: "Nil"})));
}), run_clo((_x_19) => {
  return $check_fits$(_e_0, run_loop($infer$(_e_0, _ctx_0, _t_0, _dem_0, {$: "Nil"})), _ty_0);
}));
}));
}));
}));
}));
}));
}));
}));
}

function $qua$(_q_0) {
  return $kt$("Qua", "", 0, _q_0, {$: "Nil"});
}

function $norm_cmp_quick$(_a_0, _b_0) {
  const _x_0 = ($String$eq$(($tg$(_a_0)), "App"));
  const _x_1 = ($String$eq$(($tg$(_a_0)), "Ref"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(($tg$(_a_0)), "Var"));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $norm_exact$(_a_0, _b_0);
}), run_clo((_x_5) => {
  return false;
}));
}

function $norm_cmp_heads$(_book_0, _a_0, _b_0, _le_0, _fresh_0, _rest_0, _alts_0) {
  const _x_0 = ($String$eq$(($tg$(_a_0)), "Lam"));
  const _x_1 = ($String$eq$(($tg$(_b_0)), "Lam"));
  return $kc$((_x_0 || _x_1), run_clo((_x_2) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": ($app$(_a_0, ($var$("_", _fresh_0)))), "b": ($app$(_b_0, ($var$("_", _fresh_0)))), "le": _le_0, "fresh": ((_fresh_0 + 1) >>> 0)}, "tail": _rest_0}, _alts_0);
}), run_clo((_x_3) => {
  return $kc$(($Bool$and$(run_loop($core_nat$(_a_0)), ($String$eq$(($tg$(_b_0)), "Ctr")))), run_clo((_x_4) => {
  return $norm_cmp_heads$(_book_0, run_loop($core_nat_step$(_a_0)), _b_0, _le_0, _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_5) => {
  return $kc$(($Bool$and$(run_loop($core_nat$(_b_0)), ($String$eq$(($tg$(_a_0)), "Ctr")))), run_clo((_x_6) => {
  return $norm_cmp_heads$(_book_0, _a_0, run_loop($core_nat_step$(_b_0)), _le_0, _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_a_0)), ($tg$(_b_0)))), run_clo((_x_8) => {
  return $norm_cmp_same$(_book_0, _a_0, _b_0, _le_0, _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_9) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}));
}));
}));
}

function $dg_snippet_lines$(_lines_0, _at_0, _end_0, _line_0) {
  if (_lines_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _lines_0["head"];
    const _rest_0 = _lines_0["tail"];
    return $kc$((_line_0 > _end_0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = ((_line_0 + 1) >>> 0);
  const _x_11 = run_loop($kc$((_x_2 < _at_0), run_clo((_x_3) => {
  return "";
}), run_clo((_x_4) => {
  const _x_7 = run_loop($kc$((_line_0 === _at_0), run_clo((_x_5) => {
  return ">| ";
}), run_clo((_x_6) => {
  return " | ";
})));
  const _x_8 = ($dg_lpad$(($U32$show$(_line_0)), ($dg_width$(($U32$show$(_end_0))))));
  const _x_9 = (_x_7 + _h_0);
  const _x_10 = (_x_8 + _x_9);
  return ("\n" + _x_10);
})));
  const _x_12 = run_loop($dg_snippet_lines$(_rest_0, _at_0, _end_0, ((_line_0 + 1) >>> 0)));
  return (_x_11 + _x_12);
}));
  }
}

function $dg_lines_count$(_lines_0) {
  if (_lines_0.$ === "Nil") {
    return 0;
  } else {
    const _rest_0 = _lines_0["tail"];
    const _x_0 = ($dg_lines_count$(_rest_0));
    return ((1 + _x_0) >>> 0);
  }
}

function $norm_exact_names$(_as_0, _bs_0) {
  if (_as_0.$ === "Nil") {
    if (_bs_0.$ === "Nil") {
      return true;
    } else {
      return false;
    }
  } else {
    const _a_0 = _as_0["head"];
    const _ar_0 = _as_0["tail"];
    if (_bs_0.$ === "Con") {
      const _b_0 = _bs_0["head"];
      const _br_0 = _bs_0["tail"];
      return $kc$(($String$eq$(_a_0, _b_0)), run_clo((_x_0) => {
  return $norm_exact_names$(_ar_0, _br_0);
}), run_clo((_x_1) => {
  return false;
}));
    } else {
      return false;
    }
  }
}

function $fp_term$(_t_0, _definition_0, _source_0, _route_0) {
  return $List$append$(run_loop($fp_origin$(_t_0, _definition_0, _source_0, _route_0)), ($fp_children$(($ks$(_t_0)), _definition_0, _source_0, _route_0, 0)));
}

function $fp_ctors$(_ctors_0, _definition_0, _source_0, _index_0) {
  if (_ctors_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _ctor_0 = _ctors_0["head"];
    const _rest_0 = _ctors_0["tail"];
    return $List$append$(($fp_term$(($dt$(_ctor_0)), _definition_0, _source_0, {$: "Con", "head": 2, "tail": {$: "Con", "head": _index_0, "tail": {$: "Con", "head": 0, "tail": {$: "Nil"}}}})), ($fp_ctors$(_rest_0, _definition_0, _source_0, ((_index_0 + 1) >>> 0))));
  }
}

function $j_l_children$(_book_0, _env_0, _t_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "Lam")), run_clo((_x_0) => {
  return $j_l_lam$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)));
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Mat")), run_clo((_x_2) => {
  return $j_l_mat$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, _ty_0)));
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_4) => {
  return $j_l_app$(_book_0, _env_0, _t_0, run_loop($wnf$(_book_0, run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_t_0, 0)))))));
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Let")), run_clo((_x_6) => {
  const _x_7 = ($j_l_bindings$(_book_0, _env_0, ($ks$(_t_0))));
  const _x_8 = run_loop($j_l_walk$(_book_0, ($j_context$(_book_0, _env_0, ($ks$(_t_0)))), ($j_body$(($ks$(_t_0)))), _ty_0));
  return (_x_7 + _x_8);
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Ctr")), run_clo((_x_10) => {
  return $kc$(($String$eq$(run_loop($j_literal_typed$(_book_0, _t_0, _ty_0)), "")), run_clo((_x_11) => {
  return $j_l_fields$(_book_0, _env_0, ($ks$(_t_0)), ($j_specialize$(_book_0, ($dt$(run_loop($j_find_ctor$(_book_0, ($nm$(_t_0)))))), ($ks$(run_loop($wnf$(_book_0, _ty_0)))))));
}), run_clo((_x_12) => {
  return "";
}));
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Rwt")), run_clo((_x_14) => {
  return $j_l_walk$(_book_0, _env_0, run_loop($kid$(_t_0, 2)), _ty_0);
}), run_clo((_x_15) => {
  return "";
}));
}));
}));
}));
}));
}));
}

function $j_projection_match$(_book_0, _t_0, _ty_0) {
  const _x_0 = ($qt$(_ty_0));
  const _x_1 = ($j_constructor_count$(_book_0, run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0))))));
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "All")), ($Bool$not$((_x_0 === 0))))), (_x_1 === 1))), run_clo((_x_2) => {
  return $j_projection_code$(($nm$(_t_0)), run_loop($j_projection_arm$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), ($j_specialize$(_book_0, ($dt$(run_loop($j_find_ctor$(_book_0, ($nm$(_t_0)))))), ($ks$(run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0)))))))), {$: "Nil"}, 0)));
}), run_clo((_x_3) => {
  return "";
}));
}

function $fpe_pad$(_text_0, _width_0) {
  const _x_0 = [..._text_0].length;
  const _x_1 = (_x_0 >>> 0);
  return $f_choose$((_x_1 < _width_0), run_clo((_x_2) => {
  return $fpe_pad$((" " + _text_0), _width_0);
}), run_clo((_x_3) => {
  return _text_0;
}));
}

function $f_alias_valid$(_s_0) {
  const _x_0 = ($Char$is_alpha$(($f_head$(_s_0))));
  const _x_1 = ($Char$is_eq$(($f_head$(_s_0)), "_"));
  return $Bool$and$(($Bool$and$((_x_0 || _x_1), run_loop($f_alias_chars$(_s_0)))), ($Bool$not$(($f_reserved$(_s_0)))));
}

function $f_import_used$(_name_0, _imports_0) {
  if (_imports_0.$ === "Nil") {
    return false;
  } else {
    const _im_0 = _imports_0["head"];
    const _rest_0 = _imports_0["tail"];
    const _x_0 = ($String$eq$(_name_0, ($nm$(run_loop($kid$(_im_0, 0))))));
    const _x_1 = ($f_import_used$(_name_0, _rest_0));
    return (_x_0 || _x_1);
  }
}

function $f_law_where$(_name_0, _binder_0, _ty_0, _p_0, _book_0, _imports_0, _clauses_0) {
  const _predicate_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_law_type$(_name_0, _binder_0, {$: "FParsed", "term": ($f_app$(($ref$("Exists")), {$: "Con", "head": _ty_0, "tail": {$: "Con", "head": ($kt$("Lam", ($nm$(_binder_0)), ($ix$(_binder_0)), 1, {$: "Con", "head": _predicate_0, "tail": {$: "Nil"}})), "tail": {$: "Nil"}}})), "rest": _ts_0}, _book_0, _imports_0, _clauses_0);
}

function $f_app$($0, $1) {
  for (;;) {
    {
      const _f_0 = $0;
      const _xs_0 = $1;
      if (_xs_0.$ === "Nil") {
        return _f_0;
      } else {
        const _x_0 = _xs_0["head"];
        const _xt_0 = _xs_0["tail"];
        $0 = ($kt$("App", "", 0, 1, {$: "Con", "head": _f_0, "tail": {$: "Con", "head": _x_0, "tail": {$: "Nil"}}}));
        $1 = _xt_0;
        continue;
      }
    }
  }
}

function $f_prec$(_s_0) {
  const _x_0 = ($f_eq$(_s_0, "=>"));
  const _x_1 = ($f_eq$(_s_0, "->"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return 1;
}), run_clo((_x_3) => {
  const _x_4 = ($f_eq$(_s_0, "&"));
  const _x_5 = ($f_eq$(_s_0, "|"));
  return $f_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  return 2;
}), run_clo((_x_7) => {
  return $f_choose$(($f_eq$(_s_0, "||")), run_clo((_x_8) => {
  return 3;
}), run_clo((_x_9) => {
  return $f_choose$(($f_eq$(_s_0, "&&")), run_clo((_x_10) => {
  return 4;
}), run_clo((_x_11) => {
  const _x_12 = ($f_eq$(_s_0, "<"));
  const _x_13 = ($f_eq$(_s_0, ">op"));
  const _x_14 = (_x_12 || _x_13);
  const _x_15 = ($f_eq$(_s_0, "<="));
  const _x_16 = (_x_14 || _x_15);
  const _x_17 = ($f_eq$(_s_0, ">="));
  return $f_choose$((_x_16 || _x_17), run_clo((_x_18) => {
  return 5;
}), run_clo((_x_19) => {
  const _x_20 = ($f_eq$(_s_0, "<>"));
  const _x_21 = ($f_eq$(_s_0, "++"));
  const _x_22 = (_x_20 || _x_21);
  const _x_23 = ($f_eq$(_s_0, "<&>"));
  return $f_choose$((_x_22 || _x_23), run_clo((_x_24) => {
  return 6;
}), run_clo((_x_25) => {
  return $f_choose$(($f_eq$(_s_0, ".|.")), run_clo((_x_26) => {
  return 7;
}), run_clo((_x_27) => {
  return $f_choose$(($f_eq$(_s_0, ".^.")), run_clo((_x_28) => {
  return 8;
}), run_clo((_x_29) => {
  return $f_choose$(($f_eq$(_s_0, ".&.")), run_clo((_x_30) => {
  return 9;
}), run_clo((_x_31) => {
  const _x_32 = ($f_eq$(_s_0, "<<"));
  const _x_33 = ($f_eq$(_s_0, ">>op"));
  return $f_choose$((_x_32 || _x_33), run_clo((_x_34) => {
  return 10;
}), run_clo((_x_35) => {
  const _x_36 = ($f_eq$(_s_0, "+"));
  const _x_37 = ($f_eq$(_s_0, "-"));
  return $f_choose$((_x_36 || _x_37), run_clo((_x_38) => {
  return 11;
}), run_clo((_x_39) => {
  const _x_40 = ($f_eq$(_s_0, "*"));
  const _x_41 = ($f_eq$(_s_0, "/"));
  const _x_42 = (_x_40 || _x_41);
  const _x_43 = ($f_eq$(_s_0, "%"));
  return $f_choose$((_x_42 || _x_43), run_clo((_x_44) => {
  return 12;
}), run_clo((_x_45) => {
  return 0;
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $f_grow_base$(_p_0, _min_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  const _x_2 = ($f_eq$(($f_tx$(_ts_0)), "("));
  const _x_3 = ($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "<")), ($Char$is_upper$(($f_head$(($nm$(_n_0))))))));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $f_grow_args$(_n_0, ($f_tx$(_ts_0)), _min_0, run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), "(")), run_clo((_x_5) => {
  return $f_args$(($f_tl$(_ts_0)), ")", {$: "Nil"});
}), run_clo((_x_6) => {
  return $f_family_first$(run_loop($f_space$(($f_tl$(_ts_0)))));
}))));
}), run_clo((_x_7) => {
  const _x_8 = run_loop($f_prec$(($f_tx$(_ts_0))));
  const _x_9 = ($f_eq$(($f_tx$(_ts_0)), "%"));
  const _x_10 = ($f_eq$(($f_tx$(_ts_0)), "-"));
  const _x_11 = ($f_col$(_ts_0));
  const _x_12 = ($f_col$(($f_tl$(_ts_0))));
  const _x_13 = ((_x_11 + 1) >>> 0);
  const _x_14 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), ")"));
  const _x_15 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "}"));
  const _x_16 = (_x_14 || _x_15);
  const _x_17 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), ","));
  const _x_18 = (_x_16 || _x_17);
  const _x_19 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), ":"));
  const _x_20 = (_x_18 || _x_19);
  const _x_21 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), ">"));
  const _x_22 = (_x_20 || _x_21);
  const _x_23 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "\n"));
  const _x_24 = (_x_22 || _x_23);
  const _x_25 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "->"));
  const _x_26 = (_x_24 || _x_25);
  const _x_27 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "<eof>"));
  const _x_28 = (_x_26 || _x_27);
  const _x_29 = ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "]"));
  return $f_choose$(($Bool$and$(($Bool$and$(($Bool$and$((_x_8 > _min_0), ($Bool$not$(($Bool$and$(($Bool$and$((_x_9 || _x_10), (_x_12 === _x_13))), ($Char$is_alpha$(($f_head$(($f_tx$(($f_tl$(_ts_0)))))))))))))), ($Bool$not$(($f_eq$(($f_tx$(_ts_0)), ">")))))), ($Bool$not$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), ">>")), (_x_28 || _x_29))))))), run_clo((_x_30) => {
  const _x_31 = ($f_eq$(($f_tx$(_ts_0)), "=>"));
  const _x_32 = ($f_eq$(($f_tx$(_ts_0)), "->"));
  const _x_33 = (_x_31 || _x_32);
  const _x_34 = ($f_eq$(($f_tx$(_ts_0)), "<>"));
  const _x_35 = (_x_33 || _x_34);
  const _x_36 = ($f_eq$(($f_tx$(_ts_0)), "&"));
  const _x_37 = (_x_35 || _x_36);
  const _x_38 = ($f_eq$(($f_tx$(_ts_0)), "|"));
  return $f_binary$(_n_0, ($f_tx$(_ts_0)), _min_0, run_loop($f_rhs$(($f_tl$(_ts_0)), ($f_tx$(_ts_0)), run_loop($f_choose$((_x_37 || _x_38), run_clo((_x_39) => {
  const _x_40 = run_loop($f_prec$(($f_tx$(_ts_0))));
  return ((_x_40 - 1) >>> 0);
}), run_clo((_x_41) => {
  return $f_prec$(($f_tx$(_ts_0)));
}))))));
}), run_clo((_x_42) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}));
}));
}));
}

function $f_bang$(_n_0, _ts_0, _min_0) {
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_n_0)), "Ref")), ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "(")))), run_clo((_x_0) => {
  return $f_grow$({$: "FParsed", "term": ($kt$("Ref", ($nm$(_n_0)), ($ix$(_n_0)), 3, ($ks$(_n_0)))), "rest": ($f_tl$(_ts_0))}, _min_0);
}), run_clo((_x_1) => {
  return $f_err$(_ts_0, "! must follow a named definition and precede call parentheses");
}));
}

function $f_index$(_n_0, _p_0, _min_0) {
  const _idx_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "<-")), run_clo((_x_0) => {
  return $f_index_value$(_n_0, _idx_0, run_loop($f_expr$(($f_tl$(_ts_0)), 2)), _min_0);
}), run_clo((_x_1) => {
  return $f_grow$({$: "FParsed", "term": ($f_app$(($ref$("Array.get")), {$: "Con", "head": ($ref$("U32")), "tail": {$: "Con", "head": _n_0, "tail": {$: "Con", "head": run_loop($f_namespace$(_idx_0, ($ref$("U32")))), "tail": {$: "Nil"}}}})), "rest": _ts_0}, _min_0);
}));
}

function $f_template_expr$(_p_0) {
  const _t_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("TemplateArg", "", 0, 0, {$: "Con", "head": _t_0, "tail": {$: "Nil"}})), "rest": _ts_0};
}

function $f_do_start$(_ts_0) {
  return $f_do_named$(run_loop($f_space$(_ts_0)));
}

function $f_rewrite$(_ts_0) {
  return $f_rewrite_head$(run_loop($f_expr$(_ts_0, 0)));
}

function $f_atom_base$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "++")), run_clo((_x_0) => {
  const _x_1 = ($f_col$(_ts_0));
  return $f_atom_base$({$: "Con", "head": {$: "FToken", "text": "+", "f_line": ($f_line$(_ts_0)), "f_col": ($f_col$(_ts_0)), "f_kind": 0}, "tail": {$: "Con", "head": {$: "FToken", "text": "+", "f_line": ($f_line$(_ts_0)), "f_col": ((_x_1 + 1) >>> 0), "f_kind": 0}, "tail": ($f_tl$(_ts_0))}});
}), run_clo((_x_2) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "(")), run_clo((_x_3) => {
  return $f_group$(run_loop($f_body$(($f_tl$(_ts_0)))));
}), run_clo((_x_4) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "{")), run_clo((_x_5) => {
  return $f_brace$(($f_tl$(_ts_0)));
}), run_clo((_x_6) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "[")), run_clo((_x_7) => {
  return $f_array$(($f_tl$(_ts_0)));
}), run_clo((_x_8) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "@")), run_clo((_x_9) => {
  return $f_all$(($f_tl$(_ts_0)), false);
}), run_clo((_x_10) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "&")), run_clo((_x_11) => {
  return $f_grade$(($f_tl$(_ts_0)));
}), run_clo((_x_12) => {
  const _x_13 = ($f_eq$(($f_tx$(_ts_0)), "+"));
  const _x_14 = ($f_eq$(($f_tx$(_ts_0)), "+bind"));
  return $f_choose$((_x_13 || _x_14), run_clo((_x_15) => {
  return $f_mark$(run_loop($f_expr$(($f_tl$(_ts_0)), 12)), 2);
}), run_clo((_x_16) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "?")), run_clo((_x_17) => {
  return {$: "FParsed", "term": ($kt$("Hol", ($f_tx$(($f_tl$(_ts_0)))), 0, 0, {$: "Nil"})), "rest": ($f_tl$(($f_tl$(_ts_0))))};
}), run_clo((_x_18) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "\\")), run_clo((_x_19) => {
  return $f_matcher$(($f_tl$(($f_tl$(_ts_0)))));
}), run_clo((_x_20) => {
  const _x_21 = ($f_eq$(($f_tx$(_ts_0)), "Type"));
  const _x_22 = ($f_eq$(($f_tx$(_ts_0)), "Data"));
  return $f_choose$((_x_21 || _x_22), run_clo((_x_23) => {
  return {$: "FParsed", "term": ($kt$("Typ", "", 0, 0, {$: "Con", "head": ($kt$("Qua", "", 0, run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), "Data")), run_clo((_x_24) => {
  return 2;
}), run_clo((_x_25) => {
  return 1;
}))), {$: "Nil"})), "tail": {$: "Nil"}})), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_26) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "Quant")), run_clo((_x_27) => {
  return {$: "FParsed", "term": ($kt$("Qnt", "", 0, 0, {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_28) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "Kind")), run_clo((_x_29) => {
  return $f_kind_wrap$(run_loop($f_expect$(run_loop($f_expr$(($f_tl$(($f_tl$(_ts_0)))), 0)), ")")));
}), run_clo((_x_30) => {
  const _x_31 = ($f_kind_token$(_ts_0));
  return $f_choose$((_x_31 === 2), run_clo((_x_32) => {
  return {$: "FParsed", "term": ($kt$("Literal", ($f_tx$(_ts_0)), 0, 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_33) => {
  const _x_34 = ($f_kind_token$(_ts_0));
  return $f_choose$(($Bool$and$((_x_34 === 1), ($Bool$not$(($f_reserved$(($f_tx$(_ts_0)))))))), run_clo((_x_35) => {
  return $f_atom_name$(_ts_0);
}), run_clo((_x_36) => {
  return $f_choose$(($f_reserved$(($f_tx$(_ts_0)))), run_clo((_x_37) => {
  return $f_err$(_ts_0, "expected term");
}), run_clo((_x_38) => {
  return $fpe_error$(_ts_0, "expected term", "a term");
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $f_def_type$(_name_0, _pars_0, _p_0, _book_0, _imports_0, _unsafe_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _ty_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Absent")), run_clo((_x_2) => {
  return $f_result$(_book_0, ($kt$("Error", ("definition without return type needs a law: " + _name_0), 0, 0, {$: "Nil"})), _imports_0);
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($f_tx$(run_loop($f_skip$(($f_tl$(_ts_0)))))), "import")), run_clo((_x_4) => {
  return $f_foreign$(_name_0, _pars_0, run_loop($f_def_signature$(_name_0, _pars_0, _ty_0, _book_0)), run_loop($f_skip$(($f_tl$(_ts_0)))), _book_0, _imports_0, _unsafe_0, {$: "Nil"});
}), run_clo((_x_5) => {
  return $f_def_body$(_name_0, _pars_0, run_loop($f_def_signature$(_name_0, _pars_0, _ty_0, _book_0)), run_loop($f_body$(($f_pr$(run_loop($f_expect$({$: "FParsed", "term": _ty_0, "rest": _ts_0}, ":")))))), _book_0, _imports_0, _unsafe_0);
}));
}));
}));
}

function $f_named_field$(_name_0, _fields_0) {
  if (_fields_0.$ === "Nil") {
    return false;
  } else {
    const _field_0 = _fields_0["head"];
    const _rest_0 = _fields_0["tail"];
    const _x_0 = ($f_eq$(_name_0, ($nm$(_field_0))));
    const _x_1 = ($f_named_field$(_name_0, _rest_0));
    return (_x_0 || _x_1);
  }
}

function $f_tele_binder$(_name_0, _id_0, _q_0, _temp_0, _ts_0, _end_0, _acc_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_0) => {
  return $f_tele_type$(_name_0, _id_0, _q_0, _temp_0, run_loop($f_expr$(($f_tl$(_ts_0)), 0)), _end_0, _acc_0);
}), run_clo((_x_1) => {
  return $f_choose$(($Bool$and$((_q_0 === 1), ($Bool$not$(_temp_0)))), run_clo((_x_2) => {
  return $f_tele_type$(_name_0, _id_0, 0, _temp_0, {$: "FParsed", "term": ($atom$("Qnt")), "rest": _ts_0}, _end_0, _acc_0);
}), run_clo((_x_3) => {
  return $f_err$(_ts_0, "expected : (a marked parameter requires its type)");
}));
}));
}

function $f_type_ctors$(_name_0, _pars_0, _ty_0, _ts_0, _book_0, _imports_0, _ctors_0) {
  const _x_0 = ($f_col$(_ts_0));
  return $f_choose$(($Bool$and$((_x_0 > 0), ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "{")))), run_clo((_x_1) => {
  const _x_2 = ($Bool$not$(($f_eq$(($dk$(run_loop($f_find$(($f_tx$(_ts_0)), _ctors_0)))), "Missing"))));
  const _x_3 = ($Bool$not$(($f_eq$(($dk$(run_loop($f_ctor_lookup$(($f_tx$(_ts_0)), _book_0)))), "Missing"))));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  const _x_5 = ($f_tx$(_ts_0));
  const _x_6 = (_x_5 + ")");
  const _x_7 = ($f_tx$(_ts_0));
  const _x_8 = (_x_7 + ")");
  return $f_result$(_book_0, ($f_pn$(run_loop($fpe_fresh$(_ts_0, ("expected a fresh constructor name (duplicate declaration: " + _x_6), ("a fresh constructor name (duplicate declaration: " + _x_8))))), _imports_0);
}), run_clo((_x_9) => {
  return $f_type_ctor$(_name_0, _pars_0, _ty_0, ($f_tx$(_ts_0)), run_loop($f_tele$(($f_tl$(($f_tl$(_ts_0)))), "}", {$: "Nil"})), _book_0, _imports_0, _ctors_0);
}));
}), run_clo((_x_10) => {
  return $f_tops$(_ts_0, {$: "Con", "head": {$: "KDef", "name": _name_0, "kind": "ADT", "arity": ($terms_len$(_pars_0)), "templates": 0, "typ": ($f_tbind$(_pars_0, _ty_0)), "value": ($atom$("Absent")), "ctors": ($List$reverse$(_ctors_0)), "native": false, "unsafe": false}, "tail": _book_0}, _imports_0, false);
}));
}

function $ffw_walk$(_term_0, _env_0, _next_0, _stack_0) {
  return $f_choose$(($String$eq$(($tg$(_term_0)), "FUnboundVar")), run_clo((_x_0) => {
  return $ffw_done$(($kt$("Var", ($nm$(_term_0)), _next_0, 1, {$: "Nil"})), ((_next_0 + 1) >>> 0), _stack_0);
}), run_clo((_x_1) => {
  return $f_choose$(($String$eq$(($tg$(_term_0)), "Var")), run_clo((_x_2) => {
  return $ffw_done$(run_loop($f_rename_var$(_term_0, _env_0)), _next_0, _stack_0);
}), run_clo((_x_3) => {
  return $f_choose$(($String$eq$(($tg$(_term_0)), "All")), run_clo((_x_4) => {
  return $ffw_walk$(run_loop($kid$(_term_0, 0)), _env_0, ((_next_0 + 1) >>> 0), {$: "Con", "head": {$: "FFAllA", "term": _term_0, "env": _env_0, "id": _next_0}, "tail": _stack_0});
}), run_clo((_x_5) => {
  return $f_choose$(($String$eq$(($tg$(_term_0)), "Lam")), run_clo((_x_6) => {
  return $ffw_walk$(run_loop($kid$(_term_0, 0)), {$: "Con", "head": ($kt$("Map", "", ($ix$(_term_0)), 0, {$: "Con", "head": ($var$(($nm$(_term_0)), _next_0)), "tail": {$: "Nil"}})), "tail": _env_0}, ((_next_0 + 1) >>> 0), {$: "Con", "head": {$: "FFLambda", "term": _term_0, "id": _next_0}, "tail": _stack_0});
}), run_clo((_x_7) => {
  return $f_choose$(($String$eq$(($tg$(_term_0)), "Let")), run_clo((_x_8) => {
  return $ffw_let$(_env_0, _env_0, ($ks$(_term_0)), {$: "Nil"}, _next_0, _stack_0);
}), run_clo((_x_9) => {
  return $ffw_kids$(_term_0, _env_0, ($ks$(_term_0)), {$: "Nil"}, _next_0, _stack_0);
}));
}));
}));
}));
}));
}

function $f_qual_name$(_name_0, _ns_0) {
  return $f_choose$(($String$is_empty$(_ns_0)), run_clo((_x_0) => {
  return _name_0;
}), run_clo((_x_1) => {
  const _x_2 = ("." + _name_0);
  return (_ns_0 + _x_2);
}));
}

function $f_qual_term$(_t_0, _book_0, _ns_0, _imports_0) {
  const _x_0 = ($f_eq$(($tg$(_t_0)), "Ref"));
  const _x_1 = ($f_eq$(($tg$(_t_0)), "ADT"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(($tg$(_t_0)), "Ctr"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(($tg$(_t_0)), "Mat"));
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": run_loop($f_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  return $f_resolve_name$(($nm$(_t_0)), _book_0, _ns_0, _imports_0);
}), run_clo((_x_7) => {
  return $nm$(_t_0);
}))), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($f_qual_terms$(($ks$(_t_0)), _book_0, _ns_0, _imports_0)), "removed": ($rm$(_t_0))};
}

function $f_scope_do$(_t_0, _env_0, _book_0) {
  return $f_scope_do_args$(_t_0, _env_0, _book_0, ($f_scope_terms$(($ks$(run_loop($f_choose$(($f_eq$(($dk$(run_loop($f_find$(($nm$(_t_0)), _book_0)))), "ADT")), run_clo((_x_0) => {
  return $f_adt$(run_loop($kid$(_t_0, 0)), ($ks$(run_loop($kid$(_t_0, 0)))), run_loop($f_find$(($nm$(_t_0)), _book_0)));
}), run_clo((_x_1) => {
  return $kid$(_t_0, 0);
}))))), _env_0, _book_0)));
}

function $f_scope_call$(_t_0, _env_0, _book_0) {
  const _x_0 = ($qt$(_t_0));
  return $f_choose$((_x_0 === 2), run_clo((_x_1) => {
  return $f_scope_marked_call$(run_loop($kid$(_t_0, 0)), _env_0, _book_0);
}), run_clo((_x_2) => {
  return $f_scope_call_head$(_t_0, _env_0, _book_0, run_loop($f_scope$(run_loop($kid$(_t_0, 0)), _env_0, _book_0)));
}));
}

function $f_scope_lower$(_t_0, _env_0, _book_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Write")), run_clo((_x_0) => {
  return $f_scope$(run_loop($kid$(_t_0, 0)), _env_0, _book_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "ADT")), run_clo((_x_2) => {
  return $f_adt$(_t_0, ($f_scope_terms$(($ks$(_t_0)), _env_0, _book_0)), run_loop($f_find$(($nm$(_t_0)), _book_0)));
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "App")), run_clo((_x_4) => {
  return $f_scope_app$(run_loop($f_scope$(run_loop($kid$(_t_0, 0)), _env_0, _book_0)), run_loop($f_scope$(run_loop($kid$(_t_0, 1)), _env_0, _book_0)));
}), run_clo((_x_5) => {
  return $f_scope_base$(_t_0, _env_0, _book_0);
}));
}));
}));
}

function $ka_spine_step$(_e_0, _ctx_0, _arg_0, _node_0, _fty_0) {
  return {$: "KAnnotatedSpine", "node": ($ka_app_spine_root$(_e_0, _ctx_0, _arg_0, _node_0, _fty_0)), "typ": run_loop($subst$(run_loop($kid$(_fty_0, 1)), ($ix$(_fty_0)), _arg_0))};
}

function $core_subst_stable$(_t_0) {
  const _tag_0 = _t_0["tag"];
  const _name_0 = _t_0["name"];
  const _id_0 = _t_0["id"];
  const _quant_0 = _t_0["quant"];
  const _kids_0 = _t_0["kids"];
  const _removed_0 = _t_0["removed"];
  return $kc$(($String$eq$(_tag_0, "Var")), run_clo((_x_0) => {
  return false;
}), run_clo((_x_1) => {
  return $kc$(run_loop($core_subst_stable_terms$(_kids_0)), run_clo((_x_2) => {
  return $kc$(($String$eq$(_tag_0, "App")), run_clo((_x_3) => {
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(_name_0, "")), (_id_0 === 0))), (_quant_0 === 0))), run_clo((_x_4) => {
  return $core_subst_stable_app$(_kids_0, _removed_0);
}), run_clo((_x_5) => {
  return false;
}));
}), run_clo((_x_6) => {
  return true;
}));
}), run_clo((_x_7) => {
  return false;
}));
}));
}

function $ka_args_static$(_e_0, _ctx_0, _tel_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return {$: "Con", "head": ($annotate$(_e_0, _ctx_0, _h_0, run_loop($kid$(_tel_0, 0)))), "tail": run_loop($ka_args_static$(_e_0, _ctx_0, run_loop($kid$(_tel_0, 1)), _rest_0))};
}), run_clo((_x_1) => {
  return $ka_args_cached$(_e_0, _ctx_0, _tel_0, {$: "Con", "head": _h_0, "tail": _rest_0});
}));
  }
}

function $ka_args$(_e_0, _ctx_0, _tel_0, _xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $ka_args_head$(_e_0, _ctx_0, run_loop($wnf$(($cb$(_e_0)), _tel_0)), _h_0, _rest_0);
  }
}

function $mat_goal_head$(_book_0, _goal_0, _tel_0, _n_0, _name_0, _xs_0) {
  const _x_0 = ($qt$(_tel_0));
  return $all$(run_loop($kc$((_x_0 === 0), run_clo((_x_1) => {
  return 0;
}), run_clo((_x_2) => {
  const _x_3 = ($qt$(_tel_0));
  return $kc$((_x_3 === 1), run_clo((_x_4) => {
  return $qt$(_goal_0);
}), run_clo((_x_5) => {
  return $qadd$(($qt$(_goal_0)), ($qt$(_goal_0)));
}));
}))), ($nm$(_tel_0)), ($ix$(_tel_0)), run_loop($kid$(_tel_0, 0)), run_loop($mat_goal$(_book_0, _goal_0, run_loop($kid$(_tel_0, 1)), ((_n_0 - 1) >>> 0), _name_0, ($norm_join$(_xs_0, {$: "Con", "head": ($var$(($nm$(_tel_0)), ($ix$(_tel_0)))), "tail": {$: "Nil"}})))));
}

function $remaining$(_cs_0, _removed_0) {
  if (_cs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _cs_0["head"];
    const _t_0 = _cs_0["tail"];
    return $kc$(run_loop($has_name$(_removed_0, ($dn$(_h_0)))), run_clo((_x_0) => {
  return $remaining$(_t_0, _removed_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": _h_0, "tail": run_loop($remaining$(_t_0, _removed_0))};
}));
  }
}

function $j_choice_leaf$(_t_0, _binder_0) {
  const _x_0 = ($ix$(run_loop($j_strip$(run_loop($kid$(_t_0, 0))))));
  const _x_1 = ($terms_len$(($ks$(run_loop($j_strip$(run_loop($kid$(_t_0, 1))))))));
  return $Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_t_0)), "App")), ($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))))), "Var")))), (_x_0 === _binder_0))), ($String$eq$(($tg$(run_loop($j_strip$(run_loop($kid$(_t_0, 1)))))), "Ctr")))), ($String$eq$(($nm$(run_loop($j_strip$(run_loop($kid$(_t_0, 1)))))), "Unit")))), (_x_1 === 0));
}

function $j_word_bit$(_bit_0, _rest_0, _at_0, _acc_0) {
  const _x_0 = ($String$eq$(($nm$(_bit_0)), "True"));
  const _x_1 = ($String$eq$(($nm$(_bit_0)), "False"));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_bit_0)), "Ctr")), (_x_0 || _x_1))), run_clo((_x_2) => {
  const _x_5 = run_loop($kc$(($String$eq$(($nm$(_bit_0)), "True")), run_clo((_x_3) => {
  return (_at_0 >= 32 ? 0 : (1 << _at_0) >>> 0);
}), run_clo((_x_4) => {
  return 0;
})));
  return $j_word$(_rest_0, ((_at_0 + 1) >>> 0), ((_acc_0 | _x_5) >>> 0));
}), run_clo((_x_6) => {
  return {$: "None"};
}));
}

function $j_u32_node$(_t_0) {
  return $kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(($nm$(_t_0)), "U32")))), run_clo((_x_0) => {
  return $j_word$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), 0, 0);
}), run_clo((_x_1) => {
  return {$: "None"};
}));
}

function $Nat$show$(_n_0) {
  const _m_0 = _n_0;
  return $Nat$show$fin$(_m_0, "", ($Nat$show$put$(nat_divmod(_m_0, 10))));
}

function $j_string_head$(_head_0, _tail_0, _acc_0) {
  return $kc$(($Bool$and$(($String$eq$(($tg$(_head_0)), "Ctr")), ($String$eq$(($nm$(_head_0)), "Chr")))), run_clo((_x_0) => {
  return $j_string_char$(run_loop($j_u32$(run_loop($kid$(_head_0, 0)))), _tail_0, _acc_0);
}), run_clo((_x_1) => {
  return {$: "None"};
}));
}

function $kp_float_point$(_s_0) {
  if (_s_0 === "") {
    return ".0";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    const _x_0 = ($Char$to_u32$(_h_0));
    return $kc$((_x_0 === 101), run_clo((_x_1) => {
  return (".0e" + _t_0);
}), run_clo((_x_2) => {
  const _x_3 = ($Char$show$(_h_0));
  const _x_4 = run_loop($kp_float_point$(_t_0));
  return (_x_3 + _x_4);
}));
  }
}

function $Nat$is_le$(_a_0, _b_0) {
  return $Cmp$is_le$(cmp_new(_a_0, _b_0));
}

function $kp_ctor_string$(_s_0, _t_0, _p_0, _env_0) {
  if (_s_0.$ === "Some") {
    const _x_0 = _s_0["value"];
    const _x_1 = (_x_0 + "\"");
    return ("\"" + _x_1);
  } else {
    const _x_2 = ($kp_eq$(($nm$(_t_0)), "Con"));
    const _x_3 = ($kp_eq$(($nm$(_t_0)), "Nil"));
    return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $kp_list$(run_loop($kp_chain$(_t_0, "Con", 2, {$: "Nil"})), _p_0, _env_0);
}), run_clo((_x_5) => {
  return $kc$(($kp_eq$(($nm$(_t_0)), "Tuple")), run_clo((_x_6) => {
  return $kp_tuple$(run_loop($kp_chain$(_t_0, "Tuple", 2, {$: "Nil"})), _env_0);
}), run_clo((_x_7) => {
  return $kp_ctor_array$(run_loop($kp_array$(_t_0)), _t_0, _env_0);
}));
}));
  }
}

function $kp_string$(_t_0) {
  return $kc$(($kp_is$(_t_0, "Ctr", "SNil")), run_clo((_x_0) => {
  return {$: "Some", "value": ""};
}), run_clo((_x_1) => {
  const _x_2 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($kp_is$(_t_0, "Ctr", "SCon")), (_x_2 === 2))), run_clo((_x_3) => {
  return $kp_append$(run_loop($kp_char$(run_loop($kid$(_t_0, 0)), 34)), run_loop($kp_string$(run_loop($kid$(_t_0, 1)))));
}), run_clo((_x_4) => {
  return {$: "None"};
}));
}));
}

function $kp_char_num$(_n_0, _quote_0) {
  if (_n_0.$ === "None") {
    return {$: "None"};
  } else {
    const _x_0 = _n_0["value"];
    return {$: "Some", "value": run_loop($kp_escape$(_x_0, _quote_0))};
  }
}

function $g_snf_return$($0, $1, $2, $3, $4, $5, $6) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _parent_0 = $2;
      const _done_0 = $3;
      const _todo_0 = $4;
      const _stack_0 = $5;
      const _fresh_0 = $6;
      if (_todo_0.$ === "Nil") {
        $0 = _book_0;
        $1 = _st_0;
        $2 = {$: "KTerm", "tag": ($tg$(_parent_0)), "name": ($nm$(_parent_0)), "id": ($ix$(_parent_0)), "quant": ($qt$(_parent_0)), "kids": ($List$reverse$(_done_0)), "removed": ($rm$(_parent_0))};
        $3 = _stack_0;
        $4 = _fresh_0;
        $pc = 1; continue;
      } else {
        const _h_0 = _todo_0["head"];
        const _rest_0 = _todo_0["tail"];
        return $g_snf_go$(_book_0, _st_0, _h_0, {$: "Con", "head": {$: "KNormFrame", "parent": _parent_0, "done": _done_0, "todo": _rest_0}, "tail": _stack_0}, _fresh_0);
      }
    }
    case 1: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _t_0 = $2;
      const _stack_0 = $3;
      const _fresh_0 = $4;
      if (_stack_0.$ === "Nil") {
        return _t_0;
      } else {
        const _t_1 = _stack_0["head"];
        const _parent_0 = _t_1["parent"];
        const _done_0 = _t_1["done"];
        const _todo_0 = _t_1["todo"];
        const _rest_0 = _stack_0["tail"];
        $0 = _book_0;
        $1 = _st_0;
        $2 = _parent_0;
        $3 = {$: "Con", "head": _t_0, "tail": _done_0};
        $4 = _todo_0;
        $5 = _rest_0;
        $6 = _fresh_0;
        $pc = 0; continue;
      }
    }
  }
}

function $g_put$(_heap_0, _id_0, _value_0) {
  if (_heap_0.$ === "GEmpty") {
    return $g_put_node$(($atom$("Absent")), {$: "GEmpty"}, {$: "GEmpty"}, _id_0, _value_0);
  } else {
    const _old_0 = _heap_0["value"];
    const _left_0 = _heap_0["left"];
    const _right_0 = _heap_0["right"];
    return $g_put_node$(_old_0, _left_0, _right_0, _id_0, _value_0);
  }
}

function $g_next$(_st_0) {
  const _next_0 = _st_0["next"];
  return _next_0;
}

function $g_return$($0, $1, $2, $3, $4) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _t_0 = $2;
      const _stack_0 = $3;
      if (_stack_0.$ === "Nil") {
        return {$: "GResult", "state": _st_0, "term": _t_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _book_0;
        $1 = _st_0;
        $2 = _t_0;
        $3 = _frame_0;
        $4 = _rest_0;
        $pc = 1; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _t_0 = $2;
      const _frame_0 = $3;
      const _stack_0 = $4;
      if (_frame_0.$ === "GFill") {
        const _id_0 = _frame_0["id"];
        const _args_0 = _frame_0["args"];
        const _pending_0 = _frame_0["pending"];
        const _fallback_0 = _frame_0["fallback"];
        return $g_filled$(_book_0, _id_0, _args_0, _pending_0, _fallback_0, _stack_0, run_loop($g_share_head$(_st_0, _t_0)));
      } else if (_frame_0.$ === "GMatch") {
        const _arm_0 = _frame_0["arm"];
        const _raw_0 = _frame_0["raw"];
        const _args_1 = _frame_0["args"];
        const _pending_1 = _frame_0["pending"];
        const _fallback_1 = _frame_0["fallback"];
        return $g_match$(_book_0, _st_0, _arm_0, _arm_0, _raw_0, _t_0, _args_1, _pending_1, _fallback_1, _stack_0);
      } else if (_frame_0.$ === "GMinA") {
        const _other_0 = _frame_0["other"];
        const _args_2 = _frame_0["args"];
        return $g_min_left$(_book_0, _st_0, _t_0, _other_0, _args_2, _stack_0);
      } else if (_frame_0.$ === "GMinB") {
        const _other_1 = _frame_0["other"];
        const _args_3 = _frame_0["args"];
        $0 = _book_0;
        $1 = _st_0;
        $2 = ($norm_apply$(run_loop($norm_min_right$(_other_1, _t_0)), _args_3));
        $3 = _stack_0;
        $pc = 0; continue;
      } else {
        const _original_0 = _frame_0["original"];
        const _args_4 = _frame_0["args"];
        const _pending_2 = _frame_0["pending"];
        const _fallback_2 = _frame_0["fallback"];
        return $kc$(($String$eq$(($tg$(_t_0)), "Rfl")), run_clo((_x_0) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_original_0, 2)), _args_4, _pending_2, _fallback_2, _stack_0);
}), run_clo((_x_1) => {
  return $g_return$(_book_0, _st_0, ($norm_apply$(_original_0, _args_4)), _stack_0);
}));
      }
    }
  }
}

function $g_let_shared$(_book_0, _h_0, _rest_0, _bindings_0, _args_0, _pending_0, _fallback_0, _stack_0, _r_0) {
  return $g_let$(_book_0, ($g_state$(_r_0)), _rest_0, {$: "Con", "head": ($kt$("Bind", ($nm$(_h_0)), ($ix$(_h_0)), ($qt$(_h_0)), {$: "Con", "head": ($g_term$(_r_0)), "tail": {$: "Nil"}})), "tail": _bindings_0}, _args_0, _pending_0, _fallback_0, _stack_0);
}

function $g_let_sub$($0, $1) {
  for (;;) {
    {
      const _t_0 = $0;
      const _bindings_0 = $1;
      if (_bindings_0.$ === "Nil") {
        return _t_0;
      } else {
        const _h_0 = _bindings_0["head"];
        const _rest_0 = _bindings_0["tail"];
        $0 = run_loop($subst$(_t_0, ($ix$(_h_0)), run_loop($kid$(_h_0, 0))));
        $1 = _rest_0;
        continue;
      }
    }
  }
}

function $sp_template_checked$(_st_0, _d_0, _closed_0, _rest_0, _ctx_0, _owner_0, _depth_0, _checked_0) {
  return $kc$(($good$(_checked_0)), run_clo((_x_0) => {
  return $sp_template_key$(_st_0, _d_0, _closed_0, _rest_0, _ctx_0, _owner_0, _depth_0, ($sp_keys$(_closed_0)));
}), run_clo((_x_1) => {
  return {$: "KSpecTerm", "state": ($sp_fail$(_st_0, ($ce$(_checked_0)))), "term": ($norm_apply$(($ref$(($dn$(_d_0)))), ($norm_join$(_closed_0, _rest_0))))};
}));
}

function $template_args$(_e_0, _ty_0, _sp_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return $ok$(($atom$("Args")), _ty_0, {$: "Nil"});
}), run_clo((_x_1) => {
  return $template_arg_head$(_e_0, run_loop($wnf$(($cb$(_e_0)), _ty_0)), _sp_0, _n_0);
}));
}

function $sp_take_next$(_ts_0, _n_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": _h_0, "tail": run_loop($sp_take$(_rest_0, ((_n_0 - 1) >>> 0)))};
  }
}

function $sp_drop_next$(_ts_0, _n_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _rest_0 = _ts_0["tail"];
    return $sp_drop$(_rest_0, ((_n_0 - 1) >>> 0));
  }
}

function $sp_apply_result$(_head_0, _r_0) {
  return {$: "KSpecTerm", "state": ($sp_states$(_r_0)), "term": ($norm_apply$(_head_0, ($sp_values$(_r_0))))};
}

function $sp_pair$(_t_0, _h_0, _r_0) {
  return {$: "KSpecTerm", "state": ($sp_state$(_r_0)), "term": {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": {$: "Con", "head": _h_0, "tail": {$: "Con", "head": ($sp_value$(_r_0)), "tail": {$: "Nil"}}}, "removed": ($rm$(_t_0))}};
}

function $cs$(_r_0) {
  const _uses_0 = _r_0["uses"];
  return _uses_0;
}

function $dg_trace_detail$(_e_0, _ctx_0, _t_0, _r_0, _detail_0) {
  return {$: "KChecked", "term": ($kt$("DTrace", ($cn$(_e_0)), 0, ($qt$(_detail_0)), {$: "Con", "head": run_loop($kid$(_detail_0, 0)), "tail": {$: "Con", "head": run_loop($kid$(_detail_0, 1)), "tail": {$: "Con", "head": ($kt$("DCtx", "", 0, 0, _ctx_0)), "tail": {$: "Con", "head": _t_0, "tail": {$: "Con", "head": ($kt$("DTrail", "", 0, 0, {$: "Con", "head": _t_0, "tail": {$: "Nil"}})), "tail": {$: "Nil"}}}}}})), "typ": ($cy$(_r_0)), "uses": ($cs$(_r_0)), "error": ($ce$(_r_0))};
}

function $dg_reason$(_e_0, _ctx_0, _t_0, _ty_0, _code_0) {
  return $kc$(($String$eq$(_code_0, "undefined name")), run_clo((_x_0) => {
  return $dg_pair$(($dg_text$("a defined name")), _t_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(_code_0, "unbound variable")), run_clo((_x_2) => {
  return $dg_pair$(($dg_text$("a bound variable")), _t_0);
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(_code_0, "nondecreasing self-call")), run_clo((_x_4) => {
  return $dg_pair$(($dg_text$("a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)")), _t_0);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(_code_0, "live use of an unfilled law")), run_clo((_x_6) => {
  return $dg_pair$(($dg_text$("a filled definition (an unfilled law is a dead claim: live code cannot use it)")), _t_0);
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(_code_0, "a family requires angle-bracket parameters")), run_clo((_x_8) => {
  const _x_9 = ($nm$(_t_0));
  const _x_10 = (_x_9 + "<..>)");
  return $dg_pair$(($dg_text$(("a family instance (write " + _x_10))), _t_0);
}), run_clo((_x_11) => {
  return $kc$(($String$eq$(_code_0, "unresolved hole")), run_clo((_x_12) => {
  return $dg_pair$(_ty_0, _t_0);
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(_code_0, "cannot infer: annotation required")), run_clo((_x_14) => {
  return $dg_pair$(($dg_text$(run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(run_loop($dg_family$(($cb$(_e_0)), ($nm$(_t_0)))), "")))), run_clo((_x_15) => {
  return "a declared constructor";
}), run_clo((_x_16) => {
  return "an annotated term (cannot infer)";
}))))), _t_0);
}), run_clo((_x_17) => {
  const _x_18 = ($String$eq$(_code_0, "lambda requires a function type"));
  const _x_19 = ($String$eq$(_code_0, "matcher requires a function type"));
  const _x_20 = (_x_18 || _x_19);
  const _x_21 = ($String$eq$(_code_0, "reflexivity requires equality goal"));
  return $kc$((_x_20 || _x_21), run_clo((_x_22) => {
  return $dg_pair$(_ty_0, ($dg_typeless$(($cb$(_e_0)), _ctx_0, _t_0)));
}), run_clo((_x_23) => {
  return $kc$(($String$eq$(_code_0, "constructor requires a datatype goal")), run_clo((_x_24) => {
  return $dg_pair$(_ty_0, run_loop($kc$(($String$eq$(run_loop($dg_family$(($cb$(_e_0)), ($nm$(_t_0)))), "")), run_clo((_x_25) => {
  return $dg_typeless$(($cb$(_e_0)), _ctx_0, _t_0);
}), run_clo((_x_26) => {
  return $ref$(run_loop($dg_family$(($cb$(_e_0)), ($nm$(_t_0)))));
}))));
}), run_clo((_x_27) => {
  return $kt$("DDetail", "", 0, 0, {$: "Con", "head": ($dg_text$(_code_0)), "tail": {$: "Con", "head": ($atom$("Absent")), "tail": {$: "Nil"}}});
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $infer_var$(_ctx_0, _t_0, _dem_0) {
  const _bound_0 = run_loop($ctx_get$(_ctx_0, ($ix$(_t_0))));
  return $kc$(($String$eq$(($tg$(_bound_0)), "Absent")), run_clo((_x_0) => {
  return $bad$("unbound variable");
}), run_clo((_x_1) => {
  return $ok$(_t_0, run_loop($kid$(_bound_0, 0)), {$: "Con", "head": ($kt$("Use", "", ($ix$(_t_0)), _dem_0, {$: "Nil"})), "tail": {$: "Nil"}});
}));
}

function $infer_ref$(_e_0, _t_0, _dem_0, _sp_0, _d_0) {
  return $kc$(($String$eq$(($dk$(_d_0)), "Absent")), run_clo((_x_0) => {
  return $bad$("undefined name");
}), run_clo((_x_1) => {
  const _x_2 = ($da$(_d_0));
  return $kc$(($Bool$and$(($String$eq$(($dk$(_d_0)), "ADT")), (_x_2 > 0))), run_clo((_x_3) => {
  return $bad$("a family requires angle-bracket parameters");
}), run_clo((_x_4) => {
  return $kc$((_dem_0 === 0), run_clo((_x_5) => {
  return $ok$(_t_0, ($dt$(_d_0)), {$: "Nil"});
}), run_clo((_x_6) => {
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($nm$(_t_0)), ($cn$(_e_0)))), ($Bool$not$(($cu$(_e_0)))))), ($Bool$not$(run_loop($descend_spine$(($cq$(_e_0)), _sp_0, run_loop($unargs$(($cl$(_e_0)), {$: "Nil"})))))))), run_clo((_x_7) => {
  return $bad$("nondecreasing self-call");
}), run_clo((_x_8) => {
  return $kc$(($Bool$and$(($Bool$and$(($Bool$and$(($Bool$and$(($String$eq$(($dk$(_d_0)), "Def")), ($String$eq$(($tg$(($dv$(_d_0)))), "Absent")))), ($Bool$not$(($db$(_d_0)))))), ($Bool$not$(($cu$(_e_0)))))), ($Bool$not$(($String$eq$(($nm$(_t_0)), ($cn$(_e_0)))))))), run_clo((_x_9) => {
  return $bad$("live use of an unfilled law");
}), run_clo((_x_10) => {
  return $infer_template$(_e_0, _t_0, _dem_0, _sp_0, _d_0);
}));
}));
}));
}));
}));
}

function $checked$(_r_0, _t_0, _ty_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $ok$(_t_0, _ty_0, ($cs$(_r_0)));
}), run_clo((_x_1) => {
  return _r_0;
}));
}

function $ok$(_t_0, _ty_0, _us_0) {
  return {$: "KChecked", "term": _t_0, "typ": _ty_0, "uses": _us_0, "error": ""};
}

function $both$(_a_0, _b_0, _t_0, _ty_0, _join_0) {
  return $kc$(($good$(_a_0)), run_clo((_x_0) => {
  return $kc$(($good$(_b_0)), run_clo((_x_1) => {
  return $ok$(_t_0, _ty_0, ($uses_merge$(($cs$(_a_0)), ($cs$(_b_0)), _join_0)));
}), run_clo((_x_2) => {
  return _b_0;
}));
}), run_clo((_x_3) => {
  return _a_0;
}));
}

function $kindq$(_e_0, _q_0) {
  return $kc$(($Bool$and$(($cu$(_e_0)), (_q_0 === 2))), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  return _q_0;
}));
}

function $infer_app$(_e_0, _ctx_0, _t_0, _dem_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $infer_app_type$(_e_0, _ctx_0, _t_0, _dem_0, _r_0, run_loop($wnf$(($cb$(_e_0)), ($cy$(_r_0)))));
}), run_clo((_x_1) => {
  return _r_0;
}));
}

function $infer_adt$(_e_0, _ctx_0, _t_0, _dem_0, _d_0) {
  const _x_0 = ($terms_len$(($ks$(_t_0))));
  const _x_1 = ($da$(_d_0));
  return $kc$(($Bool$and$(($String$eq$(($dk$(_d_0)), "ADT")), (_x_0 === _x_1))), run_clo((_x_2) => {
  return $infer_adt_done$(_t_0, run_loop($tele_check$(_e_0, _ctx_0, ($dt$(_d_0)), ($ks$(_t_0)), _dem_0)));
}), run_clo((_x_3) => {
  return $dg_adt_error$(_t_0, _d_0);
}));
}

function $nb_max$(_a_0, _b_0) {
  return $nt_choose$((_a_0 > _b_0), run_clo((_x_0) => {
  return _a_0;
}), run_clo((_x_1) => {
  return _b_0;
}));
}

function $ne_take_params$(_ps_0, _slots_0, _i_0) {
  if (_ps_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _ps_0["head"];
    const _name_0 = _t_0["name"];
    const _kind_0 = _t_0["kind"];
    const _t_1 = _ps_0["tail"];
    if (_slots_0.$ === "Nil") {
      const _x_0 = ($ne_take_params$(_t_1, {$: "Nil"}, ((_i_0 + 1) >>> 0)));
      const _x_1 = ($U32$show$(_i_0));
      const _x_2 = (";\n" + _x_0);
      const _x_3 = (_x_1 + _x_2);
      const _x_4 = (" = r" + _x_3);
      const _x_5 = (_name_0 + _x_4);
      const _x_6 = ($nl_c_type$(_kind_0));
      const _x_7 = (" " + _x_5);
      const _x_8 = (_x_6 + _x_7);
      return ("    " + _x_8);
    } else {
      const _at_0 = _slots_0["head"];
      const _rest_0 = _slots_0["tail"];
      const _x_9 = ($ne_take_params$(_t_1, _rest_0, _i_0));
      const _x_10 = (");\n" + _x_9);
      const _x_11 = (_at_0 + _x_10);
      const _x_12 = (" = STK(" + _x_11);
      const _x_13 = (_name_0 + _x_12);
      const _x_14 = ($nl_c_type$(_kind_0));
      const _x_15 = (" " + _x_13);
      const _x_16 = (_x_14 + _x_15);
      return ("    " + _x_16);
    }
  }
}

function $nt_lines$(_s_0) {
  return $nt_lines_go$(_s_0, "");
}

function $nc_desc_join$(_a_0, _b_0) {
  return {$: "NC_Desc", "cells": ($List$append$(($nc_desc_cells$(_a_0)), ($nc_desc_cells$(_b_0)))), "types": ($nc_desc_types$(_b_0)), "error": run_loop($nt_choose$(($String$eq$(($nc_desc_error$(_a_0)), "")), run_clo((_x_0) => {
  return $nc_desc_error$(_b_0);
}), run_clo((_x_1) => {
  return $nc_desc_error$(_a_0);
})))};
}

function $nc_show_field$(_book_0, _tel_0, _left_0, _i_0, _d_0) {
  return $nc_desc_join$({$: "NC_Desc", "cells": {$: "Con", "head": ($U32$show$(_i_0)), "tail": ($nc_desc_cells$(_d_0))}, "types": ($nc_desc_types$(_d_0)), "error": ($nc_desc_error$(_d_0))}, run_loop($nc_show_fields$(_book_0, run_loop($kid$(_tel_0, 1)), ((_left_0 - 1) >>> 0), ((_i_0 + 1) >>> 0), ($nc_desc_types$(_d_0)))));
}

function $nt_local$(_k_0, _n_0) {
  const _x_0 = ($U32$show$(_n_0));
  const _x_1 = ($nt_clean$(_k_0));
  const _x_2 = ("_" + _x_0);
  return (_x_1 + _x_2);
}

function $ne_stores$(_base_0, _ws_0, _i_0, _seal_0) {
  if (_ws_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ws_0["head"];
    const _t_0 = _ws_0["tail"];
    const _x_3 = ($ne_stores$(_base_0, _t_0, ((_i_0 + 1) >>> 0), _seal_0));
    const _x_4 = run_loop($nt_choose$(_seal_0, run_clo((_x_0) => {
  const _x_1 = (_h_0 + ")");
  return ("rfc_seal(e, " + _x_1);
}), run_clo((_x_2) => {
  return _h_0;
})));
    const _x_5 = (";\n" + _x_3);
    const _x_6 = (_x_4 + _x_5);
    const _x_7 = ($U32$show$(_i_0));
    const _x_8 = ("] = " + _x_6);
    const _x_9 = (_x_7 + _x_8);
    const _x_10 = (" + " + _x_9);
    const _x_11 = (_base_0 + _x_10);
    return ("e.mem[" + _x_11);
  }
}

function $nc_parallel_share$(_env_0, _xs_0) {
  if (_env_0.$ === "Nil") {
    return "";
  } else {
    const _t_0 = _env_0["head"];
    const _id_0 = _t_0["id"];
    const _word_0 = _t_0["word"];
    const _rest_0 = _env_0["tail"];
    const _x_0 = run_loop($nc_keeps$(_word_0, ($nc_parallel_uses$(_xs_0, _id_0))));
    const _x_1 = ($nc_parallel_share$(_rest_0, _xs_0));
    return (_x_0 + _x_1);
  }
}

function $nc_local_calls$(_book_0, _refs_0) {
  if (_refs_0.$ === "Nil") {
    return {$: "Con", "head": "$local", "tail": {$: "Nil"}};
  } else {
    const _h_0 = _refs_0["head"];
    const _rest_0 = _refs_0["tail"];
    return {$: "Con", "head": run_loop($nc_ref_name$(_book_0, _h_0)), "tail": ($nc_local_calls$(_book_0, _rest_0))};
  }
}

function $nc_child_task$(_fid_0, _join_0, _idx_0, _em_0) {
  const _code_0 = _em_0["code"];
  const _word_0 = _em_0["value"];
  const _x_0 = (_word_0 + ");\n");
  const _x_1 = ($nt_fid$(_fid_0));
  const _x_2 = (", " + _x_0);
  const _x_3 = (_x_1 + _x_2);
  const _x_4 = ($U32$show$(_idx_0));
  const _x_5 = ("] = term_tsk(" + _x_3);
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = (" + " + _x_6);
  const _x_8 = (_join_0 + _x_7);
  const _x_9 = ("e.mem[" + _x_8);
  return (_code_0 + _x_9);
}

function $nc_local_segments$($0, $1, $2, $3) {
  for (;;) {
    {
      const _ss_0 = $0;
      const _calls_0 = $1;
      const _forked_0 = $2;
      const _acc_0 = $3;
      if (_ss_0.$ === "Nil") {
        return $nt_reverse$(_acc_0, {$: "Nil"});
      } else {
        const _t_0 = _ss_0["head"];
        const _k_0 = _t_0["name"];
        const _ps_0 = _t_0["params"];
        const _r_0 = _t_0["result"];
        const _f_0 = _t_0["frame"];
        const _b_0 = _t_0["body"];
        const _refs_0 = _t_0["refs"];
        const _host_0 = _t_0["host"];
        const _spin_0 = _t_0["spin"];
        const _fork_0 = _t_0["fork"];
        const _bang_0 = _t_0["bang"];
        const _rest_0 = _ss_0["tail"];
        $0 = _rest_0;
        $1 = _calls_0;
        $2 = _forked_0;
        $3 = {$: "Con", "head": {$: "N_Segment", "name": _k_0, "params": _ps_0, "result": _r_0, "frame": _f_0, "body": _b_0, "refs": run_loop($nt_choose$(($nb_contains$(_refs_0, "$local")), run_clo((_x_0) => {
  return _refs_0;
}), run_clo((_x_1) => {
  return _calls_0;
}))), "host": _host_0, "spin": _spin_0, "fork": run_loop($nt_choose$(($nb_contains$(_refs_0, "$local")), run_clo((_x_2) => {
  return _fork_0;
}), run_clo((_x_3) => {
  return _forked_0;
}))), "bang": _bang_0}, "tail": _acc_0};
        continue;
      }
    }
  }
}

function $ne_frame$(_ws_0, _next_0) {
  const _x_0 = ($nt_count$(_ws_0));
  const _n_0 = ((_x_0 + 1) >>> 0);
  const _x_1 = ($U32$show$(_n_0));
  const _x_2 = (_x_1 + ");\n");
  const _x_3 = ($ne_frame_stores$(($List$append$(_ws_0, {$: "Con", "head": ($nt_fid$(_next_0)), "tail": {$: "Nil"}})), 0));
  const _x_4 = ("WL_PUSHN(" + _x_2);
  const _x_5 = (_x_3 + _x_4);
  const _x_6 = ($U32$show$(_n_0));
  const _x_7 = (");\n" + _x_5);
  const _x_8 = (_x_6 + _x_7);
  return ("WL_ROOM(" + _x_8);
}

function $nc_cut_task$(_next_0, _ws_0, _emitted_0) {
  const _code_0 = _emitted_0["code"];
  const _word_0 = _emitted_0["value"];
  const _x_0 = ($U32$show$(($nt_count$(_ws_0))));
  const _x_1 = (_x_0 + ";\n");
  const _x_2 = (");\nWL_IDX = " + _x_1);
  const _x_3 = (_word_0 + _x_2);
  const _x_4 = ($nt_fid$(_next_0));
  const _x_5 = (", " + _x_3);
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ("WL_CONT = term_tsk(" + _x_6);
  return (_code_0 + _x_7);
}

function $np_level_mat$(_term_0, _zero_0, _successor_0, _hasZero_0, _hasSucc_0) {
  return $nt_choose$(($Bool$and$(($Bool$and$(($np_supported$(_term_0)), ($String$eq$(($nm$(_term_0)), "Zero")))), ($Bool$not$(_hasZero_0)))), run_clo((_x_0) => {
  return $np_level$(run_loop($kid$(_term_0, 1)), run_loop($kid$(_term_0, 0)), _successor_0, true, _hasSucc_0);
}), run_clo((_x_1) => {
  return $nt_choose$(($Bool$and$(($Bool$and$(($np_supported$(_term_0)), ($String$eq$(($nm$(_term_0)), "Succ")))), ($Bool$not$(_hasSucc_0)))), run_clo((_x_2) => {
  return $np_level$(run_loop($kid$(_term_0, 1)), _zero_0, run_loop($kid$(_term_0, 0)), _hasZero_0, true);
}), run_clo((_x_3) => {
  return {$: "NPLevel", "zero": _zero_0, "successor": _successor_0, "fallback": _term_0, "hasZero": _hasZero_0, "hasSucc": _hasSucc_0, "valid": false};
}));
}));
}

function $np_emit_row$(_book_0, _row_0, _rest_0, _word_0, _env_0, _next_0) {
  const _index_0 = _row_0["index"];
  const _body_0 = _row_0["body"];
  const _residual_0 = _row_0["residual"];
  const _apply_0 = _row_0["apply"];
  const _last_0 = _row_0["last"];
  return $np_emit_done$(_book_0, _index_0, _last_0, _rest_0, _word_0, _env_0, run_loop($np_row_code$(_book_0, _body_0, _residual_0, _apply_0, _word_0, _env_0, _next_0)));
}

function $np_collect_level$(_term_0, _depth_0, _built_0, _level_0) {
  const _zero_0 = _level_0["zero"];
  const _successor_0 = _level_0["successor"];
  const _fallback_0 = _level_0["fallback"];
  const _hasZero_0 = _level_0["hasZero"];
  const _hasSucc_0 = _level_0["hasSucc"];
  const _valid_0 = _level_0["valid"];
  return $nt_choose$(($Bool$and$(_valid_0, (_hasZero_0 || _hasSucc_0))), run_clo((_x_0) => {
  return $np_collect$(run_loop($nt_choose$(_hasSucc_0, run_clo((_x_1) => {
  return _successor_0;
}), run_clo((_x_2) => {
  return _fallback_0;
}))), run_loop($nt_choose$(_hasSucc_0, run_clo((_x_3) => {
  return ((_depth_0 + 1) >>> 0);
}), run_clo((_x_4) => {
  return _depth_0;
}))), {$: "Con", "head": {$: "NPRow", "index": _depth_0, "body": run_loop($nt_choose$(_hasZero_0, run_clo((_x_5) => {
  return _zero_0;
}), run_clo((_x_6) => {
  return _fallback_0;
}))), "residual": _depth_0, "apply": ($Bool$not$(_hasZero_0)), "last": false}, "tail": _built_0});
}), run_clo((_x_7) => {
  return $nt_reverse$({$: "Con", "head": {$: "NPRow", "index": _depth_0, "body": _term_0, "residual": _depth_0, "apply": true, "last": true}, "tail": _built_0}, {$: "Nil"});
}));
}

function $nc_find_ctor$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return $missing$();
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $nt_choose$(($Bool$and$(($String$eq$(($dn$(_d_0)), _name_0)), ($String$eq$(($dk$(_d_0)), "Ctr")))), run_clo((_x_0) => {
  return _d_0;
}), run_clo((_x_1) => {
  return $nt_choose$(($String$eq$(($dk$(run_loop($nc_find_ctor$(($dc$(_d_0)), _name_0)))), "Absent")), run_clo((_x_2) => {
  return $nc_find_ctor$(_rest_0, _name_0);
}), run_clo((_x_3) => {
  return $nc_find_ctor$(($dc$(_d_0)), _name_0);
}));
}));
  }
}

function $nc_field_decls$(_name_0, _word_0, _count_0, _i_0, _n_0, _boxed_0) {
  return $nt_choose$((_i_0 === _count_0), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_6 = run_loop($nc_field_decls$(_name_0, _word_0, _count_0, ((_i_0 + 1) >>> 0), _n_0, _boxed_0));
  const _x_7 = run_loop($nt_choose$(_boxed_0, run_clo((_x_2) => {
  const _x_3 = ($U32$show$(_i_0));
  const _x_4 = (_x_3 + "]");
  return ("fields[" + _x_4);
}), run_clo((_x_5) => {
  return $nc_field_word$(_name_0, _word_0, _i_0);
})));
  const _x_8 = (";\n" + _x_6);
  const _x_9 = (_x_7 + _x_8);
  const _x_10 = ($U32$show$(($nc_id$(((_n_0 + _i_0) >>> 0)))));
  const _x_11 = (" = " + _x_9);
  const _x_12 = (_x_10 + _x_11);
  return ("Term v_" + _x_12);
}));
}

function $ni_replace_all$(_s_0, _key_0, _value_0) {
  if (_s_0 === "") {
    return "";
  } else {
    const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
    const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
    return $nt_choose$(($String$starts_with$((_h_0 + _t_0), _key_0)), run_clo((_x_0) => {
  const _x_1 = run_loop($ni_replace_all$(($String$drop$((_h_0 + _t_0), [..._key_0].length)), _key_0, _value_0));
  return (_value_0 + _x_1);
}), run_clo((_x_2) => {
  return (_h_0 + run_loop($ni_replace_all$(_t_0, _key_0, _value_0)));
}));
  }
}

function $f_module_defs$(_todo_0, _visible_0, _scope_0, _ns_0, _imports_0) {
  if (_todo_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _d_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    const _x_0 = ($dx$(_d_0));
    const _x_1 = ($f_eq$(($dk$(_d_0)), "ADT"));
    const _x_2 = (_x_0 > 0);
    return $f_module_def$(_d_0, _rest_0, _visible_0, run_loop($f_choose$((_x_1 || _x_2), run_clo((_x_3) => {
  return {$: "Con", "head": _d_0, "tail": _scope_0};
}), run_clo((_x_4) => {
  return _scope_0;
}))), _ns_0, _imports_0);
  }
}

function $f_alias_term$(_t_0, _imports_0, _scope_0) {
  const _x_0 = ($f_eq$(($tg$(_t_0)), "Ref"));
  const _x_1 = ($f_eq$(($tg$(_t_0)), "ADT"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(($tg$(_t_0)), "Ctr"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(($tg$(_t_0)), "Mat"));
  return $f_alias_named$(_t_0, _imports_0, _scope_0, run_loop($f_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  return $f_alias$(($nm$(_t_0)), _imports_0);
}), run_clo((_x_7) => {
  return $nm$(_t_0);
}))));
}

function $f_path_parts$(_s_0, _part_0, _parts_0, _abs_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return $f_path_join_parts$(($List$reverse$(run_loop($f_path_push$(_part_0, _parts_0)))), run_loop($f_choose$(_abs_0, run_clo((_x_1) => {
  return "/";
}), run_clo((_x_2) => {
  return "";
}))));
}), run_clo((_x_3) => {
  return $f_choose$(($Char$is_eq$(($f_head$(_s_0)), "/")), run_clo((_x_4) => {
  return $f_path_parts$(($f_tail$(_s_0)), "", run_loop($f_path_push$(_part_0, _parts_0)), _abs_0);
}), run_clo((_x_5) => {
  const _x_6 = (($f_head$(_s_0)) + "");
  return $f_path_parts$(($f_tail$(_s_0)), (_part_0 + _x_6), _parts_0, _abs_0);
}));
}));
}

function $f_drop_chars$(_s_0, _n_0) {
  return $f_choose$((_n_0 === 0), run_clo((_x_0) => {
  return _s_0;
}), run_clo((_x_1) => {
  return $f_drop_chars$(($f_tail$(_s_0)), ((_n_0 - 1) >>> 0));
}));
}

function $f_relative_parents$(_root_0) {
  if (_root_0.$ === "Nil") {
    return "";
  } else {
    const _rest_0 = _root_0["tail"];
    const _x_0 = ($f_relative_parents$(_rest_0));
    return ("../" + _x_0);
  }
}

function $f_path_join_parts$($0, $1) {
  for (;;) {
    {
      const _parts_0 = $0;
      const _acc_0 = $1;
      if (_parts_0.$ === "Nil") {
        return _acc_0;
      } else {
        const _part_0 = _parts_0["head"];
        const _rest_0 = _parts_0["tail"];
        const _x_0 = ($String$is_empty$(_acc_0));
        const _x_1 = ($f_eq$(_acc_0, "/"));
        const _x_4 = run_loop($f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return "";
}), run_clo((_x_3) => {
  return "/";
})));
        const _x_5 = (_x_4 + _part_0);
        $0 = _rest_0;
        $1 = (_acc_0 + _x_5);
        continue;
      }
    }
  }
}

function $f_path_nonempty$(_parts_0) {
  if (_parts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _part_0 = _parts_0["head"];
    const _rest_0 = _parts_0["tail"];
    return $f_choose$(($String$is_empty$(_part_0)), run_clo((_x_0) => {
  return $f_path_nonempty$(_rest_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": _part_0, "tail": run_loop($f_path_nonempty$(_rest_0))};
}));
  }
}

function $tele_tip$(_book_0, _t_0) {
  return $tele_tip_head$(_book_0, run_loop($wnf$(_book_0, _t_0)));
}

function $check_ctors$(_e_0, _d_0, _ctrs_0, _kind_0) {
  if (_ctrs_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ctrs_0["head"];
    const _t_0 = _ctrs_0["tail"];
    return $check_ctors_next$(_e_0, _d_0, _t_0, _kind_0, run_loop($check_ctor_tel$(_e_0, _d_0, ($dt$(_h_0)), _kind_0, ($da$(_d_0)), ($da$(_h_0)), {$: "Nil"}, {$: "Nil"})));
  }
}

function $foreign_head$(_t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $foreign_head$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $foreign_tip$(_t_0) {
  return $kc$(($String$eq$(($tg$(run_loop($strip$(_t_0)))), "All")), run_clo((_x_0) => {
  return $foreign_tip$(run_loop($kid$(run_loop($strip$(_t_0)), 1)));
}), run_clo((_x_1) => {
  return $strip$(_t_0);
}));
}

function $self_pending$(_d_0, _body_0) {
  return $kc$(($Bool$and$(($Bool$not$(($du$(_d_0)))), run_loop($contains_self$({$: "Con", "head": _body_0, "tail": {$: "Nil"}}, ($dn$(_d_0)))))), run_clo((_x_0) => {
  const _x_1 = ($da$(_d_0));
  const _x_2 = ($dx$(_d_0));
  return ((_x_1 - _x_2) >>> 0);
}), run_clo((_x_3) => {
  return 0;
}));
}

function $tele_quantities$(_book_0, _ty_0, _n_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return $tele_quantities_head$(_book_0, run_loop($wnf$(_book_0, _ty_0)), _n_0);
}));
}

function $check_template_binder$(_book_0, _d_0, _ty_0, _body_0, _lhs_0, _n_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($nm$(_ty_0));
  const _x_2 = ($U32$show$(($ix$(_ty_0))));
  const _x_3 = (_x_1 + _x_2);
  const _x_4 = ($dn$(_d_0));
  const _x_5 = ("~" + _x_3);
  return $check_template_open$(_book_0, _d_0, _ty_0, _body_0, _lhs_0, _n_0, (_x_4 + _x_5));
}), run_clo((_x_6) => {
  return $bad$("template telescope is too short");
}));
}

function $check_lam$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_t_0));
  const _x_2 = ($qt$(_ty_0));
  return $check_lam_q$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, run_loop($kc$(($Bool$and$((_x_1 === 2), (_x_2 === 1))), run_clo((_x_3) => {
  return 2;
}), run_clo((_x_4) => {
  return $qt$(_ty_0);
}))));
}), run_clo((_x_5) => {
  return $bad$("lambda requires a function type");
}));
}

function $check_ctr$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "ADT")), run_clo((_x_0) => {
  return $check_ctr_found$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, run_loop($lookup$(($dc$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_ty_0)))))), ($nm$(_t_0)))));
}), run_clo((_x_1) => {
  return $bad$("constructor requires a datatype goal");
}));
}

function $check_mat$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_ty_0));
  return $kc$(($Bool$and$(($Bool$not$((_dem_0 === 0))), (_x_1 === 0))), run_clo((_x_2) => {
  return $dg_bad_message$("erased scrutinee in live match", ($dg_text$("a live scrutinee (a - scrutinee matches only in a dead region)")));
}), run_clo((_x_3) => {
  return $check_mat_type$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, run_loop($wnf$(($cb$(_e_0)), run_loop($kid$(_ty_0, 0)))));
}));
}), run_clo((_x_4) => {
  return $bad$("matcher requires a function type");
}));
}

function $check_rfl$(_e_0, _t_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "Eql")), run_clo((_x_0) => {
  return $kc$(run_loop($compare$(($cb$(_e_0)), run_loop($kid$(_ty_0, 0)), run_loop($kid$(_ty_0, 1)), false)), run_clo((_x_1) => {
  return $ok$(_t_0, _ty_0, {$: "Nil"});
}), run_clo((_x_2) => {
  return $dg_bad_detail$("reflexivity endpoints differ", run_loop($kid$(_ty_0, 0)), run_loop($kid$(_ty_0, 1)));
}));
}), run_clo((_x_3) => {
  return $bad$("reflexivity requires equality goal");
}));
}

function $check_let$(_e_0, _outer_0, _ctx_0, _xs_0, _dem_0, _ty_0, _bindings_0, _us_0) {
  if (_xs_0.$ === "Nil") {
    return $bad$("let has no body");
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    return $kc$(($String$eq$(($tg$(_h_0)), "Bind")), run_clo((_x_0) => {
  return $check_let_value$(_e_0, _outer_0, _ctx_0, _h_0, _rest_0, _dem_0, _ty_0, _bindings_0, _us_0, run_loop($infer$(_e_0, _outer_0, run_loop($kid$(_h_0, 0)), run_loop($qdem$(($qt$(_h_0)), _dem_0)), {$: "Nil"})));
}), run_clo((_x_1) => {
  return $check_let_done$(run_loop($check$(_e_0, _ctx_0, ($let_cells$(_h_0, _bindings_0)), _dem_0, _ty_0)), _bindings_0, _us_0);
}));
  }
}

function $check_rwt$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $check_rwt_type$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _r_0, run_loop($wnf$(($cb$(_e_0)), ($cy$(_r_0)))));
}), run_clo((_x_1) => {
  return _r_0;
}));
}

function $check_fits$(_e_0, _r_0, _ty_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $kc$(run_loop($compare$(($cb$(_e_0)), ($cy$(_r_0)), _ty_0, true)), run_clo((_x_1) => {
  return $checked$(_r_0, ($ct$(_r_0)), _ty_0);
}), run_clo((_x_2) => {
  return $dg_bad_detail$("type mismatch", _ty_0, ($cy$(_r_0)));
}));
}), run_clo((_x_3) => {
  return _r_0;
}));
}

function $norm_cmp_same$(_book_0, _a_0, _b_0, _le_0, _fresh_0, _rest_0, _alts_0) {
  return $kc$(($String$eq$(($tg$(_a_0)), "Var")), run_clo((_x_0) => {
  const _x_1 = ($ix$(_a_0));
  const _x_2 = ($ix$(_b_0));
  return $norm_cmp_test$(_book_0, (_x_1 === _x_2), _rest_0, _alts_0);
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_a_0)), "Typ")), run_clo((_x_4) => {
  return $kc$(_le_0, run_clo((_x_5) => {
  return $norm_cmp_kind$(_book_0, _a_0, _b_0, run_loop($wnf$(_book_0, run_loop($kid$(_a_0, 0)))), run_loop($wnf$(_book_0, run_loop($kid$(_b_0, 0)))), _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_6) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": run_loop($kid$(_a_0, 0)), "b": run_loop($kid$(_b_0, 0)), "le": false, "fresh": _fresh_0}, "tail": _rest_0}, _alts_0);
}));
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_a_0)), "All")), run_clo((_x_8) => {
  const _x_9 = ($qt$(_a_0));
  const _x_10 = ($qt$(_b_0));
  return $kc$((_x_9 === _x_10), run_clo((_x_11) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": run_loop($kid$(_b_0, 0)), "b": run_loop($kid$(_a_0, 0)), "le": _le_0, "fresh": _fresh_0}, "tail": {$: "Con", "head": {$: "KNormCmp", "a": run_loop($subst$(run_loop($kid$(_a_0, 1)), ($ix$(_a_0)), ($var$("_", _fresh_0)))), "b": run_loop($subst$(run_loop($kid$(_b_0, 1)), ($ix$(_b_0)), ($var$("_", _fresh_0)))), "le": _le_0, "fresh": ((_fresh_0 + 1) >>> 0)}, "tail": _rest_0}}, _alts_0);
}), run_clo((_x_12) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}), run_clo((_x_13) => {
  return $kc$(($String$eq$(($tg$(_a_0)), "ADT")), run_clo((_x_14) => {
  return $kc$(($Bool$and$(($String$eq$(($nm$(_a_0)), ($nm$(_b_0)))), run_loop($norm_removed$(($rm$(_a_0)), ($rm$(_b_0)), _le_0)))), run_clo((_x_15) => {
  return $norm_cmp_fields$(_book_0, ($ks$(_a_0)), ($ks$(_b_0)), _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_16) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}), run_clo((_x_17) => {
  return $kc$(($String$eq$(($tg$(_a_0)), "Qua")), run_clo((_x_18) => {
  const _x_19 = ($qt$(_a_0));
  const _x_20 = ($qt$(_b_0));
  return $norm_cmp_test$(_book_0, (_x_19 === _x_20), _rest_0, _alts_0);
}), run_clo((_x_21) => {
  return $norm_cmp_plain$(_book_0, _a_0, _b_0, _le_0, _fresh_0, _rest_0, _alts_0);
}));
}));
}));
}));
}));
}

function $norm_cmp_fail$(_book_0, _alts_0) {
  if (_alts_0.$ === "Nil") {
    return false;
  } else {
    const _t_0 = _alts_0["head"];
    const _todo_0 = _t_0["todo"];
    const _rest_0 = _alts_0["tail"];
    return $norm_cmp_loop$(_book_0, _todo_0, _rest_0);
  }
}

function $dg_lpad$(_s_0, _width_0) {
  const _x_0 = ($dg_width$(_s_0));
  const _x_4 = run_loop($dg_padding$(run_loop($kc$((_width_0 > _x_0), run_clo((_x_1) => {
  const _x_2 = ($dg_width$(_s_0));
  return ((_width_0 - _x_2) >>> 0);
}), run_clo((_x_3) => {
  return 0;
})))));
  return (_x_4 + _s_0);
}

function $fp_origin$(_t_0, _definition_0, _source_0, _route_0) {
  const _text_0 = _source_0["source"];
  const _tokens_0 = _source_0["tokens"];
  const _x_0 = ($String$eq$(($tg$(_t_0)), "Ref"));
  const _x_1 = ($String$eq$(($tg$(_t_0)), "ADT"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Ctr"));
  const _x_4 = ($ix$(_t_0));
  return $f_choose$(($Bool$and$((_x_2 || _x_3), (_x_4 >= 65536))), run_clo((_x_5) => {
  const _x_6 = ($ix$(_t_0));
  const _x_7 = ($ix$(_t_0));
  return $fp_at_token$(_t_0, _definition_0, _text_0, run_loop($fp_find_token$(_tokens_0, (65536 === 0 ? 0 : (_x_6 / 65536) >>> 0), (65536 === 0 ? _x_7 : _x_7 % 65536))), _route_0);
}), run_clo((_x_8) => {
  return {$: "Nil"};
}));
}

function $fp_children$(_terms_0, _definition_0, _source_0, _route_0, _index_0) {
  if (_terms_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _term_0 = _terms_0["head"];
    const _rest_0 = _terms_0["tail"];
    return $List$append$(($fp_term$(_term_0, _definition_0, _source_0, ($List$append$(_route_0, {$: "Con", "head": _index_0, "tail": {$: "Nil"}})))), ($fp_children$(_rest_0, _definition_0, _source_0, _route_0, ((_index_0 + 1) >>> 0))));
  }
}

function $j_l_lam$(_book_0, _env_0, _t_0, _ty_0) {
  return $j_l_walk$(_book_0, {$: "Con", "head": ($kt$("Env", "", ($ix$(_t_0)), 0, {$: "Con", "head": run_loop($kid$(_ty_0, 0)), "tail": {$: "Nil"}})), "tail": _env_0}, run_loop($kid$(_t_0, 0)), run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))));
}

function $j_l_mat$(_book_0, _env_0, _t_0, _ty_0) {
  const _x_0 = ($j_constructor_count$(_book_0, run_loop($wnf$(_book_0, run_loop($kid$(_ty_0, 0))))));
  const _x_3 = run_loop($j_l_walk$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), run_loop($j_arm_type$(_book_0, _ty_0, ($nm$(_t_0))))));
  const _x_4 = run_loop($kc$((_x_0 === 1), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  return $j_l_walk$(_book_0, _env_0, run_loop($kid$(_t_0, 1)), _ty_0);
})));
  return (_x_3 + _x_4);
}

function $j_l_app$(_book_0, _env_0, _t_0, _ty_0) {
  const _x_0 = ($qt$(_ty_0));
  const _x_3 = run_loop($j_l_walk$(_book_0, _env_0, run_loop($kid$(_t_0, 0)), _ty_0));
  const _x_4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  return $j_l_walk$(_book_0, _env_0, run_loop($kid$(_t_0, 1)), run_loop($kid$(_ty_0, 0)));
})));
  return (_x_3 + _x_4);
}

function $j_l_bindings$(_book_0, _env_0, _ts_0) {
  if (_ts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ts_0["head"];
    const _t_0 = _ts_0["tail"];
    if (_t_0.$ === "Nil") {
      return "";
    } else {
      const _x_0 = ($qt$(_h_0));
      const _x_3 = run_loop($kc$((_x_0 === 0), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  return $j_l_walk$(_book_0, _env_0, run_loop($kid$(_h_0, 0)), run_loop($j_type$(_book_0, _env_0, run_loop($kid$(_h_0, 0)))));
})));
      const _x_4 = ($j_l_bindings$(_book_0, _env_0, _t_0));
      return (_x_3 + _x_4);
    }
  }
}

function $j_l_fields$(_book_0, _env_0, _ts_0, _ty_0) {
  if (_ts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($qt$(_ty_0));
    const _x_3 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "All")), (_x_0 === 0))), run_clo((_x_1) => {
  return "";
}), run_clo((_x_2) => {
  return $j_l_walk$(_book_0, _env_0, _h_0, run_loop($kid$(_ty_0, 0)));
})));
    const _x_4 = ($j_l_fields$(_book_0, _env_0, _rest_0, run_loop($j_app_type$(_ty_0, _h_0))));
    return (_x_3 + _x_4);
  }
}

function $j_projection_code$(_name_0, _slot_0) {
  return $kc$(($String$eq$(_slot_0, "")), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = (_slot_0 + "];})");
  const _x_3 = ($j_quote$(_name_0));
  const _x_4 = (",a[0]).slice()[" + _x_2);
  const _x_5 = (_x_3 + _x_4);
  return ("fn(1,function(a){return project(" + _x_5);
}));
}

function $j_projection_arm$(_t_0, _tel_0, _slots_0, _at_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_tel_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Lam")), ($Bool$not$((_x_1 === 0))))), run_clo((_x_2) => {
  return $j_projection_arm$(run_loop($j_strip$(run_loop($kid$(_t_0, 0)))), run_loop($kid$(_tel_0, 1)), {$: "Con", "head": ($kt$("Slot", "", ($ix$(_t_0)), _at_0, {$: "Nil"})), "tail": _slots_0}, ((_at_0 + 1) >>> 0));
}), run_clo((_x_3) => {
  return "";
}));
}), run_clo((_x_4) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Var")), run_clo((_x_5) => {
  return $j_projection_slot$(($ix$(_t_0)), _slots_0);
}), run_clo((_x_6) => {
  return "";
}));
}));
}

function $f_alias_chars$(_s_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  const _x_2 = ($Char$is_alpha$(($f_head$(_s_0))));
  const _x_3 = ($Char$is_digit$(($f_head$(_s_0))));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($Char$is_eq$(($f_head$(_s_0)), "_"));
  return $Bool$and$((_x_4 || _x_5), run_loop($f_alias_chars$(($f_tail$(_s_0)))));
}));
}

function $f_grow_args$(_n_0, _op_0, _min_0, _p_0) {
  const _args_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_args_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _args_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_grow$({$: "FParsed", "term": run_loop($f_choose$(($f_eq$(_op_0, "(")), run_clo((_x_2) => {
  return $kt$("Call", "", 0, 1, {$: "Con", "head": _n_0, "tail": ($ks$(_args_0))});
}), run_clo((_x_3) => {
  return $kt$("ADT", ($nm$(_n_0)), ($ix$(_n_0)), ($qt$(_n_0)), ($ks$(_args_0)));
}))), "rest": _ts_0}, _min_0);
}));
}

function $f_args$(_ts_0, _end_0, _acc_0) {
  return $f_choose$(($Bool$and$(($f_eq$(_end_0, ">")), ($f_eq$(($f_tx$(_ts_0)), ">>")))), run_clo((_x_0) => {
  const _x_1 = ($f_col$(_ts_0));
  return {$: "FParsed", "term": ($kt$("Args", "", 0, 1, ($List$reverse$(_acc_0)))), "rest": {$: "Con", "head": {$: "FToken", "text": ">", "f_line": ($f_line$(_ts_0)), "f_col": ((_x_1 + 1) >>> 0), "f_kind": 0}, "tail": ($f_tl$(_ts_0))}};
}), run_clo((_x_2) => {
  return $f_args_base$(_ts_0, _end_0, _acc_0);
}));
}

function $f_family_first$(_ts_0) {
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), ">"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), ">>"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_args$(_ts_0, ">", {$: "Nil"});
}), run_clo((_x_3) => {
  return $f_family_first_done$(run_loop($f_expr$(_ts_0, 5)));
}));
}

function $f_binary$(_a_0, _op_0, _min_0, _p_0) {
  const _b_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_grow$({$: "FParsed", "term": run_loop($f_binary_plain$(_a_0, _op_0, _b_0)), "rest": _ts_0}, _min_0);
}

function $f_rhs$(_ts_0, _op_0, _min_0) {
  return $f_choose$(($f_eq$(_op_0, "=>")), run_clo((_x_0) => {
  return $f_body$(_ts_0);
}), run_clo((_x_1) => {
  return $f_expr$(_ts_0, _min_0);
}));
}

function $f_index_value$(_n_0, _idx_0, _p_0, _min_0) {
  const _v_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_grow$({$: "FParsed", "term": run_loop($f_choose$(($f_eq$(($tg$(_n_0)), "Ref")), run_clo((_x_0) => {
  return $kt$("Write", ($nm$(_n_0)), ($ix$(_n_0)), 1, {$: "Con", "head": ($f_app$(($ref$("Array.set")), {$: "Con", "head": ($ref$("U32")), "tail": {$: "Con", "head": _n_0, "tail": {$: "Con", "head": run_loop($f_namespace$(_idx_0, ($ref$("U32")))), "tail": {$: "Con", "head": _v_0, "tail": {$: "Nil"}}}}})), "tail": {$: "Nil"}});
}), run_clo((_x_1) => {
  return $f_app$(($ref$("Array.set")), {$: "Con", "head": ($ref$("U32")), "tail": {$: "Con", "head": _n_0, "tail": {$: "Con", "head": run_loop($f_namespace$(_idx_0, ($ref$("U32")))), "tail": {$: "Con", "head": _v_0, "tail": {$: "Nil"}}}}});
}))), "rest": _ts_0}, _min_0);
}

function $f_namespace$(_t_0, _ty_0) {
  const _x_0 = ($f_eq$(($tg$(_t_0)), "Local"));
  const _x_1 = ($f_eq$(($tg$(_t_0)), "Parallel"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $kt$(($tg$(_t_0)), ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Con", "head": run_loop($f_namespace$(run_loop($kid$(_t_0, 2)), _ty_0)), "tail": {$: "Nil"}}}});
}), run_clo((_x_3) => {
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_t_0)), "Ref")), ($Char$is_eq$(($f_head$(($nm$(_t_0)))), ".")))), run_clo((_x_4) => {
  const _x_5 = ($nm$(run_loop($f_namespace_head$(_ty_0))));
  const _x_6 = ($nm$(_t_0));
  return $ref$((_x_5 + _x_6));
}), run_clo((_x_7) => {
  const _x_8 = ($f_eq$(($tg$(_t_0)), "App"));
  const _x_9 = ($f_eq$(($tg$(_t_0)), "Call"));
  return $f_choose$(($Bool$and$((_x_8 || _x_9), ($f_namespace_operator$(run_loop($f_namespace_head$(_t_0)))))), run_clo((_x_10) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($f_namespace_terms$(($ks$(_t_0)), _ty_0)), "removed": ($rm$(_t_0))};
}), run_clo((_x_11) => {
  return _t_0;
}));
}));
}));
}

function $f_do_named$(_ts_0) {
  return $f_choose$(($f_valid_name$(($f_tx$(_ts_0)))), run_clo((_x_0) => {
  return $f_do_parameters$(($f_tx$(_ts_0)), run_loop($f_space$(($f_tl$(_ts_0)))));
}), run_clo((_x_1) => {
  return $f_err$(_ts_0, "expected a name");
}));
}

function $f_rewrite_head$(_p_0) {
  const _e_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "@")), run_clo((_x_0) => {
  return $f_rewrite_proof$(($nm$(_e_0)), ($ix$(_e_0)), run_loop($f_expect$(run_loop($f_expr$(($f_tl$(_ts_0)), 0)), ":")));
}), run_clo((_x_1) => {
  return $f_rewrite_proof$("", ($ix$(_e_0)), run_loop($f_expect$({$: "FParsed", "term": _e_0, "rest": _ts_0}, ":")));
}));
}

function $f_group$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ",")), run_clo((_x_0) => {
  return $f_tuple$(_n_0, run_loop($f_group$(run_loop($f_body$(($f_tl$(_ts_0)))))));
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_2) => {
  return $f_group_namespace$(_n_0, run_loop($f_expect$(run_loop($f_expr$(($f_tl$(_ts_0)), 0)), ")")));
}), run_clo((_x_3) => {
  return $f_expect$({$: "FParsed", "term": _n_0, "rest": _ts_0}, ")");
}));
}));
}

function $f_body$(_ts_0) {
  return $f_body_context$(_ts_0, 0);
}

function $f_brace$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "==")), run_clo((_x_0) => {
  return $f_expect$({$: "FParsed", "term": ($kt$("Rfl", "", 0, 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))}, "}");
}), run_clo((_x_1) => {
  return $f_brace_left$(run_loop($f_expr$(_ts_0, 0)));
}));
}

function $f_array$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ";")), run_clo((_x_0) => {
  return $f_err$(_ts_0, "expected term; a list does not use semicolon separators");
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "]")), run_clo((_x_2) => {
  return {$: "FParsed", "term": ($kt$("Ctr", "Nil", 0, 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_3) => {
  return $f_array_first$(run_loop($f_expr$(_ts_0, 0)));
}));
}));
}

function $f_all$(_ts_0, _exi_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "~")), run_clo((_x_0) => {
  return $f_err$(_ts_0, "~ is only allowed on leading def or law template parameters");
}), run_clo((_x_1) => {
  return $f_all_domain$(($f_tx$(run_loop($f_unmark$(_ts_0)))), ($f_atid$(_ts_0)), run_loop($f_quant$(_ts_0)), _exi_0, run_loop($f_expect$(run_loop($f_expr$(($f_tl$(($f_tl$(run_loop($f_unmark$(_ts_0)))))), 1)), "->")));
}));
}

function $f_grade$(_ts_0) {
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), "0"));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), "1"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(($f_tx$(_ts_0)), "2"));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return {$: "FParsed", "term": ($kt$("Qua", "", 0, run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), "0")), run_clo((_x_5) => {
  return 0;
}), run_clo((_x_6) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "1")), run_clo((_x_7) => {
  return 1;
}), run_clo((_x_8) => {
  return 2;
}));
}))), {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_9) => {
  return $f_all$(_ts_0, true);
}));
}

function $f_mark$(_p_0, _q_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  const _x_2 = ($qt$(_n_0));
  const _x_3 = ($Bool$and$(($f_eq$(($tg$(_n_0)), "Ref")), ($Bool$not$((_x_2 === 3)))));
  const _x_4 = ($f_eq$(($tg$(_n_0)), "ADT"));
  const _x_5 = ($terms_len$(($ks$(_n_0))));
  const _x_6 = (_x_3 || _x_4);
  const _x_7 = ($Bool$and$(($f_eq$(($tg$(_n_0)), "Call")), (_x_5 === 1)));
  return $f_choose$((_x_6 || _x_7), run_clo((_x_8) => {
  return {$: "FParsed", "term": {$: "KTerm", "tag": ($tg$(_n_0)), "name": ($nm$(_n_0)), "id": ($ix$(_n_0)), "quant": _q_0, "kids": ($ks$(_n_0)), "removed": ($rm$(_n_0))}, "rest": _ts_0};
}), run_clo((_x_9) => {
  return $fpe_error$(run_loop($f_space$(_ts_0)), "+ requires a binder or quantified datatype", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)");
}));
}));
}

function $f_matcher$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "}")), run_clo((_x_0) => {
  return {$: "FParsed", "term": ($kt$("Efq", "", 0, 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}), run_clo((_x_1) => {
  return $f_matcher_head$(run_loop($f_expr$(_ts_0, 0)));
}));
}

function $f_kind_wrap$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Typ", "", 0, 0, {$: "Con", "head": _n_0, "tail": {$: "Nil"}})), "rest": _ts_0};
}

function $f_kind_token$(_ts_0) {
  return $f_kind$(_ts_0);
}

function $f_atom_name$(_ts_0) {
  return $f_choose$(($Char$is_digit$(($f_head$(($f_tx$(_ts_0)))))), run_clo((_x_0) => {
  const _x_1 = ($f_line$(_ts_0));
  const _x_2 = ($f_line$(($f_tl$(_ts_0))));
  const _x_3 = ($f_tx$(_ts_0));
  const _x_4 = [..._x_3].length;
  const _x_5 = ($f_col$(_ts_0));
  const _x_6 = (_x_4 >>> 0);
  const _x_7 = ($f_col$(($f_tl$(_ts_0))));
  const _x_8 = ((_x_5 + _x_6) >>> 0);
  return $f_choose$(($Bool$and$(($Bool$and$(($Bool$and$(($String$ends_with$(($f_tx$(_ts_0)), "n")), ($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "+")))), (_x_1 === _x_2))), (_x_7 === _x_8))), run_clo((_x_9) => {
  return $f_atom_nat_start$(_ts_0, run_loop($f_literal$(($f_tx$(_ts_0)))));
}), run_clo((_x_10) => {
  return {$: "FParsed", "term": ($kt$("Literal", ($f_tx$(_ts_0)), ($f_atid$(_ts_0)), 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}));
}), run_clo((_x_11) => {
  return $f_choose$(($Bool$not$(($f_valid_name$(($f_tx$(_ts_0)))))), run_clo((_x_12) => {
  const _x_13 = ($f_tx$(_ts_0));
  const _x_14 = (_x_13 + "')");
  return $fpe_error$(_ts_0, "invalid name", ("a name (words joined by dots, got '" + _x_14));
}), run_clo((_x_15) => {
  const _x_16 = ($f_line$(_ts_0));
  const _x_17 = ($f_line$(($f_tl$(_ts_0))));
  const _x_18 = ($f_tx$(_ts_0));
  const _x_19 = [..._x_18].length;
  const _x_20 = ($f_col$(_ts_0));
  const _x_21 = (_x_19 >>> 0);
  const _x_22 = ($f_col$(($f_tl$(_ts_0))));
  const _x_23 = ((_x_20 + _x_21) >>> 0);
  return $f_choose$(($Bool$and$(($Bool$and$(($f_eq$(($f_tx$(($f_tl$(_ts_0)))), "{")), (_x_16 === _x_17))), (_x_22 === _x_23))), run_clo((_x_24) => {
  return $f_atom_constructor$(($f_tx$(_ts_0)), ($f_atid$(_ts_0)), run_loop($f_args$(($f_tl$(($f_tl$(_ts_0)))), "}", {$: "Nil"})));
}), run_clo((_x_25) => {
  return {$: "FParsed", "term": ($kt$("Ref", ($f_tx$(_ts_0)), ($f_atid$(_ts_0)), 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))};
}));
}));
}));
}

function $f_foreign$(_name_0, _pars_0, _ty_0, _ts_0, _book_0, _imports_0, _unsafe_0, _paths_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "import")), run_clo((_x_0) => {
  return $f_choose$(($f_foreign_path_valid$(_ts_0)), run_clo((_x_1) => {
  return $f_foreign$(_name_0, _pars_0, _ty_0, run_loop($f_skip$(($f_tl$(($f_tl$(_ts_0)))))), _book_0, _imports_0, _unsafe_0, {$: "Con", "head": ($kt$("Path", run_loop($f_unquote$(($f_tx$(($f_tl$(_ts_0)))))), 0, 0, {$: "Nil"})), "tail": _paths_0});
}), run_clo((_x_2) => {
  return $f_result$(_book_0, run_loop($fpe_foreign$(run_loop($f_space$(($f_tl$(_ts_0)))))), _imports_0);
}));
}), run_clo((_x_3) => {
  return $f_tops$(_ts_0, ($f_put$({$: "KDef", "name": _name_0, "kind": "Def", "arity": ($terms_len$(_pars_0)), "templates": 0, "typ": _ty_0, "value": ($kt$("Foreign", _name_0, 0, 0, ($List$reverse$(_paths_0)))), "ctors": {$: "Nil"}, "native": false, "unsafe": _unsafe_0}, _book_0)), _imports_0, false);
}));
}

function $f_def_signature$(_name_0, _pars_0, _ty_0, _book_0) {
  return $f_choose$(($f_eq$(($dk$(run_loop($f_find$(_name_0, _book_0)))), "Missing")), run_clo((_x_0) => {
  return $f_tbind$(_pars_0, _ty_0);
}), run_clo((_x_1) => {
  return _ty_0;
}));
}

function $f_def_body$(_name_0, _pars_0, _ty_0, _p_0, _book_0, _imports_0, _unsafe_0) {
  const _body_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_body_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _body_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_tops$(_ts_0, ($f_put$({$: "KDef", "name": _name_0, "kind": "Def", "arity": ($terms_len$(_pars_0)), "templates": run_loop($f_choose$(($f_eq$(($dk$(run_loop($f_find$(_name_0, _book_0)))), "Missing")), run_clo((_x_2) => {
  return $f_templates$(_pars_0);
}), run_clo((_x_3) => {
  return $dx$(run_loop($f_find$(_name_0, _book_0)));
}))), "typ": _ty_0, "value": ($kt$("Body", "", ($fc_start$(_pars_0, _ty_0, _body_0, ($Bool$not$(($f_eq$(($dk$(run_loop($f_find$(_name_0, _book_0)))), "Missing")))))), 0, {$: "Con", "head": ($kt$("Params", "", 0, 0, _pars_0)), "tail": {$: "Con", "head": _body_0, "tail": {$: "Nil"}}})), "ctors": {$: "Nil"}, "native": false, "unsafe": _unsafe_0}, _book_0)), _imports_0, false);
}));
}

function $f_tele_type$(_name_0, _id_0, _q_0, _temp_0, _p_0, _end_0, _acc_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _ty_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_tele$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), ",")), run_clo((_x_2) => {
  return $f_tl$(_ts_0);
}), run_clo((_x_3) => {
  return _ts_0;
}))), _end_0, {$: "Con", "head": ($kt$(run_loop($f_choose$(_temp_0, run_clo((_x_4) => {
  return "Template";
}), run_clo((_x_5) => {
  return "Bind";
}))), _name_0, _id_0, _q_0, {$: "Con", "head": _ty_0, "tail": {$: "Nil"}})), "tail": _acc_0});
}));
}

function $f_ctor_lookup$(_name_0, _book_0) {
  if (_book_0.$ === "Nil") {
    return $f_find$(_name_0, {$: "Nil"});
  } else {
    const _d_0 = _book_0["head"];
    const _ds_0 = _book_0["tail"];
    return $f_choose$(($Bool$and$(($f_eq$(($dk$(_d_0)), "Ctr")), ($f_eq$(($dn$(_d_0)), _name_0)))), run_clo((_x_0) => {
  return _d_0;
}), run_clo((_x_1) => {
  return $f_ctor_more$(_name_0, run_loop($f_ctor_lookup$(_name_0, ($dc$(_d_0)))), _ds_0);
}));
  }
}

function $fpe_fresh$(_ts_0, _legacy_0, _expected_0) {
  const _x_0 = ($f_line$(_ts_0));
  const _x_1 = ($f_line$(($f_tl$(_ts_0))));
  const _x_2 = ($f_tx$(_ts_0));
  const _x_3 = [..._x_2].length;
  const _x_4 = ($f_col$(_ts_0));
  const _x_5 = (_x_3 >>> 0);
  const _x_6 = ($f_col$(($f_tl$(_ts_0))));
  const _x_7 = ((_x_4 + _x_5) >>> 0);
  return $f_choose$(($Bool$and$((_x_0 === _x_1), (_x_6 === _x_7))), run_clo((_x_8) => {
  return $fpe_error$(($f_tl$(_ts_0)), _legacy_0, _expected_0);
}), run_clo((_x_9) => {
  return $f_err$(($f_tl$(_ts_0)), _legacy_0);
}));
}

function $f_type_ctor$(_name_0, _pars_0, _ty_0, _ctor_0, _p_0, _book_0, _imports_0, _ctors_0) {
  const _fields_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_fields_0)), "Error")), run_clo((_x_0) => {
  return $f_result$(_book_0, _fields_0, _imports_0);
}), run_clo((_x_1) => {
  return $f_type_ctors$(_name_0, _pars_0, _ty_0, run_loop($f_skip$(_ts_0)), _book_0, _imports_0, {$: "Con", "head": {$: "KDef", "name": _ctor_0, "kind": "Ctr", "arity": ($terms_len$(($ks$(_fields_0)))), "templates": 0, "typ": ($f_tbind$(_pars_0, ($f_tbind$(($ks$(_fields_0)), ($kt$("ADT", _name_0, 0, 1, ($f_param_refs$(_pars_0)))))))), "value": ($kt$("Absent", _ctor_0, 0, 0, {$: "Nil"})), "ctors": {$: "Nil"}, "native": false, "unsafe": false}, "tail": _ctors_0});
}));
}

function $f_tbind$(_pars_0, _result_0) {
  if (_pars_0.$ === "Nil") {
    return _result_0;
  } else {
    const _p_0 = _pars_0["head"];
    const _ps_0 = _pars_0["tail"];
    return $kt$("All", ($nm$(_p_0)), ($ix$(_p_0)), ($qt$(_p_0)), {$: "Con", "head": run_loop($kid$(_p_0, 0)), "tail": {$: "Con", "head": ($f_tbind$(_ps_0, _result_0)), "tail": {$: "Nil"}}});
  }
}

function $ffw_done$($0, $1, $2, $3, $4, $5) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _term_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFresh", "term": _term_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _term_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 1; continue;
      }
    }
    case 1: {
      const _frame_0 = $0;
      const _value_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      if (_frame_0.$ === "FFAllA") {
        const _term_0 = _frame_0["term"];
        const _env_0 = _frame_0["env"];
        const _id_0 = _frame_0["id"];
        return $ffw_walk$(run_loop($kid$(_term_0, 1)), {$: "Con", "head": ($kt$("Map", "", ($ix$(_term_0)), 0, {$: "Con", "head": ($var$(($nm$(_term_0)), _id_0)), "tail": {$: "Nil"}})), "tail": _env_0}, _next_0, {$: "Con", "head": {$: "FFAllB", "term": _term_0, "id": _id_0, "typ": _value_0}, "tail": _stack_0});
      } else if (_frame_0.$ === "FFAllB") {
        const _term_1 = _frame_0["term"];
        const _id_1 = _frame_0["id"];
        const _typ_0 = _frame_0["typ"];
        $0 = ($kt$("All", ($nm$(_term_1)), _id_1, ($qt$(_term_1)), {$: "Con", "head": _typ_0, "tail": {$: "Con", "head": _value_0, "tail": {$: "Nil"}}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFLambda") {
        const _term_2 = _frame_0["term"];
        const _id_2 = _frame_0["id"];
        $0 = ($kt$("Lam", ($nm$(_term_2)), _id_2, ($qt$(_term_2)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFKids") {
        const _term_3 = _frame_0["term"];
        const _env_1 = _frame_0["env"];
        const _pending_0 = _frame_0["pending"];
        const _built_0 = _frame_0["built"];
        $0 = _term_3;
        $1 = _env_1;
        $2 = _pending_0;
        $3 = {$: "Con", "head": _value_0, "tail": _built_0};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 2; continue;
      } else if (_frame_0.$ === "FFLetValue") {
        const _env_2 = _frame_0["env"];
        const _bodyenv_0 = _frame_0["bodyenv"];
        const _id_3 = _frame_0["id"];
        const _binding_0 = _frame_0["binding"];
        const _pending_1 = _frame_0["pending"];
        const _built_1 = _frame_0["built"];
        $0 = _env_2;
        $1 = {$: "Con", "head": ($kt$("Map", "", ($ix$(_binding_0)), 0, {$: "Con", "head": ($var$(($nm$(_binding_0)), _id_3)), "tail": {$: "Nil"}})), "tail": _bodyenv_0};
        $2 = _pending_1;
        $3 = {$: "Con", "head": ($kt$("Bind", ($nm$(_binding_0)), _id_3, ($qt$(_binding_0)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}})), "tail": _built_1};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 3; continue;
      } else {
        const _built_2 = _frame_0["built"];
        $0 = ($kt$("Let", "", 0, 1, ($ffw_reverse_onto$(_built_2, {$: "Con", "head": _value_0, "tail": {$: "Nil"}}))));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      }
    }
    case 2: {
      const _term_0 = $0;
      const _env_0 = $1;
      const _pending_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_pending_0.$ === "Nil") {
        $0 = {$: "KTerm", "tag": ($tg$(_term_0)), "name": ($nm$(_term_0)), "id": ($ix$(_term_0)), "quant": ($qt$(_term_0)), "kids": ($List$reverse$(_built_0)), "removed": ($rm$(_term_0))};
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _head_0 = _pending_0["head"];
        const _rest_0 = _pending_0["tail"];
        return $ffw_walk$(_head_0, _env_0, _next_0, {$: "Con", "head": {$: "FFKids", "term": _term_0, "env": _env_0, "pending": _rest_0, "built": _built_0}, "tail": _stack_0});
      }
    }
    case 3: {
      const _env_0 = $0;
      const _bodyenv_0 = $1;
      const _items_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_items_0.$ === "Nil") {
        $0 = ($kt$("Error", "empty core let", 0, 0, {$: "Nil"}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _term_0 = _items_0["head"];
        const _tail_0 = _items_0["tail"];
        return $ffw_let_tail$(_env_0, _bodyenv_0, _term_0, _tail_0, _built_0, _next_0, _stack_0);
      }
    }
  }
}

function $f_rename_var$(_t_0, _env_0) {
  if (_env_0.$ === "Nil") {
    return _t_0;
  } else {
    const _m_0 = _env_0["head"];
    const _ms_0 = _env_0["tail"];
    const _x_0 = ($ix$(_t_0));
    const _x_1 = ($ix$(_m_0));
    return $f_choose$((_x_0 === _x_1), run_clo((_x_2) => {
  return $kt$("Var", ($nm$(_t_0)), ($ix$(run_loop($kid$(_m_0, 0)))), ($qt$(_t_0)), {$: "Nil"});
}), run_clo((_x_3) => {
  return $f_rename_var$(_t_0, _ms_0);
}));
  }
}

function $ffw_let$($0, $1, $2, $3, $4, $5) {
  let $pc = 3;
  for (;;) switch ($pc) {
    case 0: {
      const _term_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFresh", "term": _term_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _term_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 1; continue;
      }
    }
    case 1: {
      const _frame_0 = $0;
      const _value_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      if (_frame_0.$ === "FFAllA") {
        const _term_0 = _frame_0["term"];
        const _env_0 = _frame_0["env"];
        const _id_0 = _frame_0["id"];
        return $ffw_walk$(run_loop($kid$(_term_0, 1)), {$: "Con", "head": ($kt$("Map", "", ($ix$(_term_0)), 0, {$: "Con", "head": ($var$(($nm$(_term_0)), _id_0)), "tail": {$: "Nil"}})), "tail": _env_0}, _next_0, {$: "Con", "head": {$: "FFAllB", "term": _term_0, "id": _id_0, "typ": _value_0}, "tail": _stack_0});
      } else if (_frame_0.$ === "FFAllB") {
        const _term_1 = _frame_0["term"];
        const _id_1 = _frame_0["id"];
        const _typ_0 = _frame_0["typ"];
        $0 = ($kt$("All", ($nm$(_term_1)), _id_1, ($qt$(_term_1)), {$: "Con", "head": _typ_0, "tail": {$: "Con", "head": _value_0, "tail": {$: "Nil"}}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFLambda") {
        const _term_2 = _frame_0["term"];
        const _id_2 = _frame_0["id"];
        $0 = ($kt$("Lam", ($nm$(_term_2)), _id_2, ($qt$(_term_2)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFKids") {
        const _term_3 = _frame_0["term"];
        const _env_1 = _frame_0["env"];
        const _pending_0 = _frame_0["pending"];
        const _built_0 = _frame_0["built"];
        $0 = _term_3;
        $1 = _env_1;
        $2 = _pending_0;
        $3 = {$: "Con", "head": _value_0, "tail": _built_0};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 2; continue;
      } else if (_frame_0.$ === "FFLetValue") {
        const _env_2 = _frame_0["env"];
        const _bodyenv_0 = _frame_0["bodyenv"];
        const _id_3 = _frame_0["id"];
        const _binding_0 = _frame_0["binding"];
        const _pending_1 = _frame_0["pending"];
        const _built_1 = _frame_0["built"];
        $0 = _env_2;
        $1 = {$: "Con", "head": ($kt$("Map", "", ($ix$(_binding_0)), 0, {$: "Con", "head": ($var$(($nm$(_binding_0)), _id_3)), "tail": {$: "Nil"}})), "tail": _bodyenv_0};
        $2 = _pending_1;
        $3 = {$: "Con", "head": ($kt$("Bind", ($nm$(_binding_0)), _id_3, ($qt$(_binding_0)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}})), "tail": _built_1};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 3; continue;
      } else {
        const _built_2 = _frame_0["built"];
        $0 = ($kt$("Let", "", 0, 1, ($ffw_reverse_onto$(_built_2, {$: "Con", "head": _value_0, "tail": {$: "Nil"}}))));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      }
    }
    case 2: {
      const _term_0 = $0;
      const _env_0 = $1;
      const _pending_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_pending_0.$ === "Nil") {
        $0 = {$: "KTerm", "tag": ($tg$(_term_0)), "name": ($nm$(_term_0)), "id": ($ix$(_term_0)), "quant": ($qt$(_term_0)), "kids": ($List$reverse$(_built_0)), "removed": ($rm$(_term_0))};
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _head_0 = _pending_0["head"];
        const _rest_0 = _pending_0["tail"];
        return $ffw_walk$(_head_0, _env_0, _next_0, {$: "Con", "head": {$: "FFKids", "term": _term_0, "env": _env_0, "pending": _rest_0, "built": _built_0}, "tail": _stack_0});
      }
    }
    case 3: {
      const _env_0 = $0;
      const _bodyenv_0 = $1;
      const _items_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_items_0.$ === "Nil") {
        $0 = ($kt$("Error", "empty core let", 0, 0, {$: "Nil"}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _term_0 = _items_0["head"];
        const _tail_0 = _items_0["tail"];
        return $ffw_let_tail$(_env_0, _bodyenv_0, _term_0, _tail_0, _built_0, _next_0, _stack_0);
      }
    }
  }
}

function $ffw_kids$($0, $1, $2, $3, $4, $5) {
  let $pc = 2;
  for (;;) switch ($pc) {
    case 0: {
      const _term_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFresh", "term": _term_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _term_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 1; continue;
      }
    }
    case 1: {
      const _frame_0 = $0;
      const _value_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      if (_frame_0.$ === "FFAllA") {
        const _term_0 = _frame_0["term"];
        const _env_0 = _frame_0["env"];
        const _id_0 = _frame_0["id"];
        return $ffw_walk$(run_loop($kid$(_term_0, 1)), {$: "Con", "head": ($kt$("Map", "", ($ix$(_term_0)), 0, {$: "Con", "head": ($var$(($nm$(_term_0)), _id_0)), "tail": {$: "Nil"}})), "tail": _env_0}, _next_0, {$: "Con", "head": {$: "FFAllB", "term": _term_0, "id": _id_0, "typ": _value_0}, "tail": _stack_0});
      } else if (_frame_0.$ === "FFAllB") {
        const _term_1 = _frame_0["term"];
        const _id_1 = _frame_0["id"];
        const _typ_0 = _frame_0["typ"];
        $0 = ($kt$("All", ($nm$(_term_1)), _id_1, ($qt$(_term_1)), {$: "Con", "head": _typ_0, "tail": {$: "Con", "head": _value_0, "tail": {$: "Nil"}}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFLambda") {
        const _term_2 = _frame_0["term"];
        const _id_2 = _frame_0["id"];
        $0 = ($kt$("Lam", ($nm$(_term_2)), _id_2, ($qt$(_term_2)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFKids") {
        const _term_3 = _frame_0["term"];
        const _env_1 = _frame_0["env"];
        const _pending_0 = _frame_0["pending"];
        const _built_0 = _frame_0["built"];
        $0 = _term_3;
        $1 = _env_1;
        $2 = _pending_0;
        $3 = {$: "Con", "head": _value_0, "tail": _built_0};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 2; continue;
      } else if (_frame_0.$ === "FFLetValue") {
        const _env_2 = _frame_0["env"];
        const _bodyenv_0 = _frame_0["bodyenv"];
        const _id_3 = _frame_0["id"];
        const _binding_0 = _frame_0["binding"];
        const _pending_1 = _frame_0["pending"];
        const _built_1 = _frame_0["built"];
        $0 = _env_2;
        $1 = {$: "Con", "head": ($kt$("Map", "", ($ix$(_binding_0)), 0, {$: "Con", "head": ($var$(($nm$(_binding_0)), _id_3)), "tail": {$: "Nil"}})), "tail": _bodyenv_0};
        $2 = _pending_1;
        $3 = {$: "Con", "head": ($kt$("Bind", ($nm$(_binding_0)), _id_3, ($qt$(_binding_0)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}})), "tail": _built_1};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 3; continue;
      } else {
        const _built_2 = _frame_0["built"];
        $0 = ($kt$("Let", "", 0, 1, ($ffw_reverse_onto$(_built_2, {$: "Con", "head": _value_0, "tail": {$: "Nil"}}))));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      }
    }
    case 2: {
      const _term_0 = $0;
      const _env_0 = $1;
      const _pending_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_pending_0.$ === "Nil") {
        $0 = {$: "KTerm", "tag": ($tg$(_term_0)), "name": ($nm$(_term_0)), "id": ($ix$(_term_0)), "quant": ($qt$(_term_0)), "kids": ($List$reverse$(_built_0)), "removed": ($rm$(_term_0))};
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _head_0 = _pending_0["head"];
        const _rest_0 = _pending_0["tail"];
        return $ffw_walk$(_head_0, _env_0, _next_0, {$: "Con", "head": {$: "FFKids", "term": _term_0, "env": _env_0, "pending": _rest_0, "built": _built_0}, "tail": _stack_0});
      }
    }
    case 3: {
      const _env_0 = $0;
      const _bodyenv_0 = $1;
      const _items_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_items_0.$ === "Nil") {
        $0 = ($kt$("Error", "empty core let", 0, 0, {$: "Nil"}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _term_0 = _items_0["head"];
        const _tail_0 = _items_0["tail"];
        return $ffw_let_tail$(_env_0, _bodyenv_0, _term_0, _tail_0, _built_0, _next_0, _stack_0);
      }
    }
  }
}

function $f_resolve_name$(_name_0, _book_0, _ns_0, _imports_0) {
  return $f_choose$(($f_declared$(_name_0, _book_0)), run_clo((_x_0) => {
  return $f_qual_name$(_name_0, _ns_0);
}), run_clo((_x_1) => {
  return $f_alias$(_name_0, _imports_0);
}));
}

function $f_qual_terms$(_ts_0, _book_0, _ns_0, _imports_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": ($f_qual_term$(_t_0, _book_0, _ns_0, _imports_0)), "tail": ($f_qual_terms$(_rest_0, _book_0, _ns_0, _imports_0))};
  }
}

function $f_scope_do_args$(_t_0, _env_0, _book_0, _types_0) {
  const _x_0 = ($qt$(_t_0));
  return $f_choose$((_x_0 === 0), run_clo((_x_1) => {
  return $kt$("Ann", "", ($ix$(_t_0)), 1, {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 1)), _env_0, _book_0)), "tail": {$: "Con", "head": run_loop($f_choose$(($f_eq$(($dk$(run_loop($f_find$(($nm$(_t_0)), _book_0)))), "ADT")), run_clo((_x_2) => {
  return $kt$("ADT", ($nm$(_t_0)), ($ix$(_t_0)), 1, _types_0);
}), run_clo((_x_3) => {
  return $norm_apply$(($ref$(($nm$(_t_0)))), _types_0);
}))), "tail": {$: "Nil"}}});
}), run_clo((_x_4) => {
  const _x_5 = ($qt$(_t_0));
  return $f_choose$((_x_5 === 1), run_clo((_x_6) => {
  const _x_7 = ($nm$(_t_0));
  return $norm_apply$(($kt$("Ref", (_x_7 + ".pure"), ($ix$(_t_0)), 1, {$: "Nil"})), ($norm_join$(_types_0, {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 1)), _env_0, _book_0)), "tail": {$: "Nil"}})));
}), run_clo((_x_8) => {
  const _x_9 = ($nm$(_t_0));
  return $norm_apply$(($kt$("Ref", (_x_9 + ".bind"), ($ix$(_t_0)), 1, {$: "Nil"})), ($norm_join$(($f_do_bind_types$(_types_0, run_loop($f_scope$(run_loop($kid$(_t_0, 1)), _env_0, _book_0)))), {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 2)), _env_0, _book_0)), "tail": {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 3)), _env_0, _book_0)), "tail": {$: "Nil"}}})));
}));
}));
}

function $f_scope_terms$(_xs_0, _env_0, _book_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    return {$: "Con", "head": run_loop($f_scope$(_x_0, _env_0, _book_0)), "tail": ($f_scope_terms$(_xt_0, _env_0, _book_0))};
  }
}

function $f_adt$(_t_0, _args_0, _d_0) {
  const _x_0 = ($qt$(_t_0));
  const _x_1 = run_loop($f_leading_quants$(($dt$(_d_0))));
  const _x_2 = ($Bool$not$(($f_eq$(($dk$(_d_0)), "ADT"))));
  const _x_3 = (_x_1 === 0);
  const _x_4 = run_loop($f_leading_quants$(($dt$(_d_0))));
  const _x_5 = ($da$(_d_0));
  const _x_6 = (_x_2 || _x_3);
  const _x_7 = ($Bool$and$(($Bool$not$(($f_eq$(($tg$(_t_0)), "ADT")))), (_x_4 < _x_5)));
  return $f_choose$(($Bool$and$((_x_0 === 2), (_x_6 || _x_7))), run_clo((_x_8) => {
  return $kt$("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ($ix$(_t_0)), 0, {$: "Nil"});
}), run_clo((_x_9) => {
  return $f_adt_fill$(_t_0, _args_0, ($da$(_d_0)), run_loop($f_leading_quants$(($dt$(_d_0)))));
}));
}

function $f_scope_marked_call$(_t_0, _env_0, _book_0) {
  const _x_0 = ($terms_len$(($ks$(_t_0))));
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_t_0)), "Call")), (_x_0 === 1))), run_clo((_x_1) => {
  return $f_scope_marked_call$(run_loop($kid$(_t_0, 0)), _env_0, _book_0);
}), run_clo((_x_2) => {
  const _x_3 = ($qt$(_t_0));
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_t_0)), "Ref")), ($Bool$not$((_x_3 === 3))))), run_clo((_x_4) => {
  return $f_scope_marked$(_t_0, run_loop($f_env$(($nm$(_t_0)), _env_0)), run_loop($f_find$(($nm$(_t_0)), _book_0)), true);
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "ADT")), run_clo((_x_6) => {
  return $f_adt$({$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": 2, "kids": ($ks$(_t_0)), "removed": ($rm$(_t_0))}, ($f_scope_terms$(($ks$(_t_0)), _env_0, _book_0)), run_loop($f_find$(($nm$(_t_0)), _book_0)));
}), run_clo((_x_7) => {
  return $kt$("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ($ix$(_t_0)), 0, {$: "Nil"});
}));
}));
}));
}

function $f_scope_call_head$(_t_0, _env_0, _book_0, _head_0) {
  return $f_choose$(run_loop($f_templates_valid$(($f_tail_terms$(($ks$(_t_0)))), run_loop($f_choose$(($Bool$and$(($f_eq$(($tg$(_head_0)), "Ref")), ($f_eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Ref")))), run_clo((_x_0) => {
  return $dx$(run_loop($f_find$(($nm$(_head_0)), _book_0)));
}), run_clo((_x_1) => {
  return 0;
}))), false)), run_clo((_x_2) => {
  return $f_scope_apply_many$(_head_0, ($f_scope_call_args$(($f_tail_terms$(($ks$(_t_0)))), _env_0, _book_0)));
}), run_clo((_x_3) => {
  return $kt$("Error", "~ arguments require leading template slots on a named template definition", 0, 0, {$: "Nil"});
}));
}

function $f_scope_app$(_f_0, _x_0) {
  return $f_choose$(($f_eq$(($tg$(_f_0)), "Lam")), run_clo((_x_1) => {
  return $f_sub$(run_loop($kid$(_f_0, 0)), ($ix$(_f_0)), _x_0);
}), run_clo((_x_2) => {
  return $app$(_f_0, _x_0);
}));
}

function $f_scope_base$(_t_0, _env_0, _book_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Ref")), run_clo((_x_0) => {
  return $f_scope_ref$(_t_0, run_loop($f_env$(($nm$(_t_0)), _env_0)), _book_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Literal")), run_clo((_x_2) => {
  return $f_literal$(($nm$(_t_0)));
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "All")), run_clo((_x_4) => {
  return $kt$("All", ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 0)), _env_0, _book_0)), "tail": {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 1)), {$: "Con", "head": ($kt$("Var", ($nm$(_t_0)), ($ix$(_t_0)), ($qt$(_t_0)), {$: "Nil"})), "tail": _env_0}, _book_0)), "tail": {$: "Nil"}}});
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Lam")), run_clo((_x_6) => {
  return $f_scope_lambda$(_t_0, _env_0, _book_0);
}), run_clo((_x_7) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Body")), run_clo((_x_8) => {
  return $ff_term$(run_loop($ff_flat$(run_loop($f_scope_body$(run_loop($kid$(_t_0, 1)), ($norm_join$(($f_vars$(($ks$(run_loop($kid$(_t_0, 0)))))), _env_0)), _book_0)), ($f_vars$(($ks$(run_loop($kid$(_t_0, 0)))))), ($ix$(_t_0)))));
}), run_clo((_x_9) => {
  const _x_10 = ($f_eq$(($tg$(_t_0)), "Local"));
  const _x_11 = ($f_eq$(($tg$(_t_0)), "Match"));
  return $f_choose$((_x_10 || _x_11), run_clo((_x_12) => {
  return $f_flat$(run_loop($f_scope_body$(_t_0, _env_0, _book_0)), {$: "Nil"});
}), run_clo((_x_13) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($f_scope_terms$(($ks$(_t_0)), _env_0, _book_0)), "removed": ($rm$(_t_0))};
}));
}));
}));
}));
}));
}));
}

function $core_subst_stable_terms$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return true;
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return $kc$(run_loop($core_subst_stable$(_h_0)), run_clo((_x_0) => {
  return $core_subst_stable_terms$(_rest_0);
}), run_clo((_x_1) => {
  return false;
}));
  }
}

function $core_subst_stable_app$(_kids_0, _removed_0) {
  if (_removed_0.$ === "Con") {
    return false;
  } else {
    return $core_subst_stable_app_kids$(_kids_0);
  }
}

function $qadd$(_a_0, _b_0) {
  return $kc$((_a_0 === 0), run_clo((_x_0) => {
  return _b_0;
}), run_clo((_x_1) => {
  return $kc$((_b_0 === 0), run_clo((_x_2) => {
  return _a_0;
}), run_clo((_x_3) => {
  return 2;
}));
}));
}

function $Nat$show$fin$($0, $1, $2) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _g_0 = $0;
      const _acc_0 = $1;
      const _dq_0 = $2;
      const _d_0 = _dq_0["fst"];
      const _t_0 = _dq_0["snd"];
      if (_t_0 === 0) {
        return (_d_0 + _acc_0);
      } else {
        const _p_0 = (_t_0 - 1);
        $0 = _g_0;
        $1 = nat_chk(_p_0 + 1);
        $2 = (_d_0 + _acc_0);
        $pc = 1; continue;
      }
    }
    case 1: {
      const _f_0 = $0;
      const _n_0 = $1;
      const _acc_0 = $2;
      if (_f_0 === 0) {
        return _acc_0;
      } else {
        const _g_0 = (_f_0 - 1);
        $0 = _g_0;
        $1 = _acc_0;
        $2 = ($Nat$show$put$(nat_divmod(_n_0, 10)));
        $pc = 0; continue;
      }
    }
  }
}

function $Nat$show$put$(_qr_0) {
  const _q_0 = _qr_0["fst"];
  const _r_0 = _qr_0["snd"];
  const _x_0 = nat_chk(48 + _r_0);
  return {$: "Tuple", "fst": char_new((_x_0 >>> 0)), "snd": _q_0};
}

function $j_string_char$(_value_0, _tail_0, _acc_0) {
  if (_value_0.$ === "None") {
    return {$: "None"};
  } else {
    const _n_0 = _value_0["value"];
    const _x_0 = (_n_0 < 55296);
    const _x_1 = (_n_0 > 57343);
    return $kc$(($Bool$and$((_n_0 <= 1114111), (_x_0 || _x_1))), run_clo((_x_2) => {
  return $j_string$(_tail_0, (($Char$from_u32$(_n_0)) + _acc_0));
}), run_clo((_x_3) => {
  return {$: "None"};
}));
  }
}

function $Cmp$is_le$(_c_0) {
  if (_c_0.$ === "LT") {
    return true;
  } else if (_c_0.$ === "EQ") {
    return true;
  } else {
    return false;
  }
}

function $kp_list$(_chain_0, _p_0, _env_0) {
  const _xs_0 = _chain_0["items"];
  const _t_0 = _chain_0["tail"];
  return $kc$(($kp_is$(_t_0, "Ctr", "Nil")), run_clo((_x_0) => {
  const _x_1 = ($kp_join$(($kp_each$(_xs_0, 1, _env_0)), ", "));
  const _x_2 = (_x_1 + "]");
  return ("[" + _x_2);
}), run_clo((_x_3) => {
  const _x_4 = run_loop($kp_go$(_t_0, 2, _env_0));
  const _x_5 = ($kp_join$(($kp_each$(_xs_0, 3, _env_0)), " <> "));
  const _x_6 = (" <> " + _x_4);
  return $kp_par$((_x_5 + _x_6), (_p_0 > 2));
}));
}

function $kp_chain$(_t_0, _name_0, _arity_0, _acc_0) {
  const _x_0 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($kp_is$(_t_0, "Ctr", _name_0)), (_x_0 === _arity_0))), run_clo((_x_1) => {
  return $kp_chain$(run_loop($kid$(_t_0, ((_arity_0 - 1) >>> 0))), _name_0, _arity_0, {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": _acc_0});
}), run_clo((_x_2) => {
  return {$: "KPChain", "items": ($List$reverse$(_acc_0)), "tail": _t_0};
}));
}

function $kp_tuple$(_chain_0, _env_0) {
  const _xs_0 = _chain_0["items"];
  const _t_0 = _chain_0["tail"];
  const _x_0 = run_loop($kp_go$(_t_0, 1, _env_0));
  const _x_1 = (_x_0 + ")");
  const _x_2 = ($kp_join$(($kp_each$(_xs_0, 1, _env_0)), ", "));
  const _x_3 = (", " + _x_1);
  const _x_4 = (_x_2 + _x_3);
  return ("(" + _x_4);
}

function $kp_ctor_array$(_a_0, _t_0, _env_0) {
  if (_a_0.$ === "Some") {
    const _xs_0 = _a_0["value"];
    const _x_0 = ($kp_join$(($kp_each$(_xs_0, 1, _env_0)), ", "));
    const _x_1 = (_x_0 + "]");
    return ("[" + _x_1);
  } else {
    const _x_2 = ($kp_join$(($kp_each$(($ks$(_t_0)), 1, _env_0)), ", "));
    const _x_3 = (_x_2 + "}");
    const _x_4 = ($nm$(_t_0));
    const _x_5 = ("{" + _x_3);
    return (_x_4 + _x_5);
  }
}

function $kp_array$(_t_0) {
  return $kc$(($kp_is$(_t_0, "Ctr", "ALeaf")), run_clo((_x_0) => {
  return {$: "Some", "value": {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}}};
}), run_clo((_x_1) => {
  return $kc$(($kp_is$(_t_0, "Ctr", "ANode")), run_clo((_x_2) => {
  return $kp_array_join$(run_loop($kp_array$(run_loop($kid$(_t_0, 0)))), run_loop($kp_array$(run_loop($kid$(_t_0, 1)))));
}), run_clo((_x_3) => {
  return {$: "None"};
}));
}));
}

function $kp_append$(_a_0, _b_0) {
  if (_a_0.$ === "Some") {
    const _x_0 = _a_0["value"];
    if (_b_0.$ === "Some") {
      const _y_0 = _b_0["value"];
      return {$: "Some", "value": (_x_0 + _y_0)};
    } else {
      return {$: "None"};
    }
  } else {
    return {$: "None"};
  }
}

function $kp_escape$(_n_0, _quote_0) {
  return $kc$((_n_0 === 10), run_clo((_x_0) => {
  return "\\n";
}), run_clo((_x_1) => {
  return $kc$((_n_0 === 9), run_clo((_x_2) => {
  return "\\t";
}), run_clo((_x_3) => {
  return $kc$((_n_0 === 13), run_clo((_x_4) => {
  return "\\r";
}), run_clo((_x_5) => {
  return $kc$((_n_0 === 0), run_clo((_x_6) => {
  return "\\0";
}), run_clo((_x_7) => {
  return $kc$((_n_0 === 92), run_clo((_x_8) => {
  return "\\\\";
}), run_clo((_x_9) => {
  return $kc$((_n_0 === _quote_0), run_clo((_x_10) => {
  const _x_11 = ($Char$show$(($Char$from_u32$(_n_0))));
  return ("\\" + _x_11);
}), run_clo((_x_12) => {
  const _x_13 = (_n_0 < 32);
  const _x_14 = (_n_0 === 127);
  const _x_15 = (_x_13 || _x_14);
  const _x_16 = ($Bool$and$((_n_0 >= 55296), (_n_0 <= 57343)));
  const _x_17 = (_x_15 || _x_16);
  const _x_18 = (_n_0 > 1114111);
  return $kc$((_x_17 || _x_18), run_clo((_x_19) => {
  const _x_20 = run_loop($kp_hex$(_n_0));
  const _x_21 = (_x_20 + "}");
  return ("\\u{" + _x_21);
}), run_clo((_x_22) => {
  return $Char$show$(($Char$from_u32$(_n_0)));
}));
}));
}));
}));
}));
}));
}));
}

function $g_put_node$(_old_0, _left_0, _right_0, _id_0, _value_0) {
  return $kc$((_id_0 === 0), run_clo((_x_0) => {
  return {$: "GNode", "value": _value_0, "left": _left_0, "right": _right_0};
}), run_clo((_x_1) => {
  const _x_2 = ((_id_0 & 1) >>> 0);
  return $kc$((_x_2 === 0), run_clo((_x_3) => {
  return {$: "GNode", "value": _old_0, "left": run_loop($g_put$(_left_0, ((_id_0 >>> 1) >>> 0), _value_0)), "right": _right_0};
}), run_clo((_x_4) => {
  return {$: "GNode", "value": _old_0, "left": _left_0, "right": run_loop($g_put$(_right_0, ((_id_0 >>> 1) >>> 0), _value_0))};
}));
}));
}

function $g_resume$($0, $1, $2, $3, $4) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _t_0 = $2;
      const _stack_0 = $3;
      if (_stack_0.$ === "Nil") {
        return {$: "GResult", "state": _st_0, "term": _t_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _book_0;
        $1 = _st_0;
        $2 = _t_0;
        $3 = _frame_0;
        $4 = _rest_0;
        $pc = 1; continue;
      }
    }
    case 1: {
      const _book_0 = $0;
      const _st_0 = $1;
      const _t_0 = $2;
      const _frame_0 = $3;
      const _stack_0 = $4;
      if (_frame_0.$ === "GFill") {
        const _id_0 = _frame_0["id"];
        const _args_0 = _frame_0["args"];
        const _pending_0 = _frame_0["pending"];
        const _fallback_0 = _frame_0["fallback"];
        return $g_filled$(_book_0, _id_0, _args_0, _pending_0, _fallback_0, _stack_0, run_loop($g_share_head$(_st_0, _t_0)));
      } else if (_frame_0.$ === "GMatch") {
        const _arm_0 = _frame_0["arm"];
        const _raw_0 = _frame_0["raw"];
        const _args_1 = _frame_0["args"];
        const _pending_1 = _frame_0["pending"];
        const _fallback_1 = _frame_0["fallback"];
        return $g_match$(_book_0, _st_0, _arm_0, _arm_0, _raw_0, _t_0, _args_1, _pending_1, _fallback_1, _stack_0);
      } else if (_frame_0.$ === "GMinA") {
        const _other_0 = _frame_0["other"];
        const _args_2 = _frame_0["args"];
        return $g_min_left$(_book_0, _st_0, _t_0, _other_0, _args_2, _stack_0);
      } else if (_frame_0.$ === "GMinB") {
        const _other_1 = _frame_0["other"];
        const _args_3 = _frame_0["args"];
        $0 = _book_0;
        $1 = _st_0;
        $2 = ($norm_apply$(run_loop($norm_min_right$(_other_1, _t_0)), _args_3));
        $3 = _stack_0;
        $pc = 0; continue;
      } else {
        const _original_0 = _frame_0["original"];
        const _args_4 = _frame_0["args"];
        const _pending_2 = _frame_0["pending"];
        const _fallback_2 = _frame_0["fallback"];
        return $kc$(($String$eq$(($tg$(_t_0)), "Rfl")), run_clo((_x_0) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_original_0, 2)), _args_4, _pending_2, _fallback_2, _stack_0);
}), run_clo((_x_1) => {
  return $g_return$(_book_0, _st_0, ($norm_apply$(_original_0, _args_4)), _stack_0);
}));
      }
    }
  }
}

function $sp_template_key$(_st_0, _d_0, _closed_0, _rest_0, _ctx_0, _owner_0, _depth_0, _key_0) {
  const _x_0 = ($sp_len$(_key_0));
  return $kc$((_x_0 > 32768), run_clo((_x_1) => {
  return {$: "KSpecTerm", "state": ($sp_fail$(_st_0, "a comptime argument must stop growing")), "term": ($ref$(($dn$(_d_0))))};
}), run_clo((_x_2) => {
  return $sp_template_inst$(_rest_0, _ctx_0, _owner_0, _depth_0, run_loop($sp_instance$(_st_0, _d_0, _closed_0, _owner_0, _depth_0, _key_0, run_loop($sp_find$(($sp_memo$(_st_0)), ($dn$(_d_0)), _key_0)))));
}));
}

function $sp_keys$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($term_key$(_h_0));
    const _x_1 = ($sp_keys$(_rest_0));
    return (_x_0 + _x_1);
  }
}

function $template_arg_head$(_e_0, _ty_0, _sp_0, _n_0) {
  if (_sp_0.$ === "Nil") {
    return $bad$("template requires all closed comptime arguments");
  } else {
    const _h_0 = _sp_0["head"];
    const _t_0 = _sp_0["tail"];
    return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  return $template_arg_done$(_e_0, _ty_0, _h_0, _t_0, _n_0, run_loop($check$(_e_0, {$: "Nil"}, _h_0, 0, run_loop($kid$(_ty_0, 0)))));
}), run_clo((_x_1) => {
  return $bad$("invalid template telescope");
}));
  }
}

function $cn$(_e_0) {
  const _name_0 = _e_0["name"];
  return _name_0;
}

function $dg_pair$(_expected_0, _observed_0) {
  return $kt$("DDetail", "", 0, 1, {$: "Con", "head": _expected_0, "tail": {$: "Con", "head": _observed_0, "tail": {$: "Nil"}}});
}

function $dg_text$(_s_0) {
  return $kt$("DText", _s_0, 0, 0, {$: "Nil"});
}

function $dg_family$(_book_0, _name_0) {
  if (_book_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _book_0["head"];
    const _rest_0 = _book_0["tail"];
    return $kc$(($Bool$and$(($String$eq$(($dk$(_d_0)), "ADT")), ($Bool$not$(($String$eq$(($dk$(run_loop($lookup$(($dc$(_d_0)), _name_0)))), "Absent")))))), run_clo((_x_0) => {
  return $dn$(_d_0);
}), run_clo((_x_1) => {
  return $dg_family$(_rest_0, _name_0);
}));
  }
}

function $dg_typeless$(_book_0, _ctx_0, _t_0) {
  const _x_4 = run_loop($kc$(($Bool$and$(($String$eq$(($tg$(_t_0)), "Ctr")), ($String$eq$(($dk$(run_loop($lookup$(_book_0, ($nm$(_t_0)))))), "ADT")))), run_clo((_x_0) => {
  const _x_1 = ($nm$(_t_0));
  const _x_2 = (_x_1 + " is a datatype: write its arguments as <>)");
  return (" (" + _x_2);
}), run_clo((_x_3) => {
  return "";
})));
  const _x_5 = run_loop($dg_expr$(_book_0, {$: "DTerm", "term": _t_0}, ($dg_scope$(($List$reverse$(_ctx_0)), {$: "Nil"}))));
  const _x_6 = ("'" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  return $dg_text$(("non-inferrable term '" + _x_7));
}

function $cu$(_e_0) {
  const _unsafe_0 = _e_0["unsafe"];
  return _unsafe_0;
}

function $descend_spine$(_qs_0, _args_0, _cols_0) {
  if (_cols_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _cols_0["head"];
    const _t_0 = _cols_0["tail"];
    return $descend_step$(run_loop($descend$(($qt$(run_loop($terms_at$(_qs_0, 0)))), run_loop($terms_at$(_args_0, 0)), _h_0)), ($terms_tail$(_qs_0)), ($terms_tail$(_args_0)), _t_0);
  }
}

function $cq$(_e_0) {
  const _quantities_0 = _e_0["quantities"];
  return _quantities_0;
}

function $unargs$(_t_0, _acc_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "App")), run_clo((_x_0) => {
  return $unargs$(run_loop($kid$(_t_0, 0)), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": _acc_0});
}), run_clo((_x_1) => {
  return _acc_0;
}));
}

function $cl$(_e_0) {
  const _lhs_0 = _e_0["lhs"];
  return _lhs_0;
}

function $infer_template$(_e_0, _t_0, _dem_0, _sp_0, _d_0) {
  const _x_0 = ($dx$(_d_0));
  const _x_1 = ($dx$(run_loop($lookup$(($cb$(_e_0)), ($cn$(_e_0))))));
  const _x_2 = (_x_0 === 0);
  const _x_3 = (_x_1 > 0);
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $ok$(_t_0, ($dt$(_d_0)), {$: "Nil"});
}), run_clo((_x_5) => {
  return $checked$(run_loop($template_args$(_e_0, ($dt$(_d_0)), _sp_0, ($dx$(_d_0)))), _t_0, ($dt$(_d_0)));
}));
}

function $uses_merge$(_a_0, _b_0, _join_0) {
  if (_a_0.$ === "Nil") {
    return _b_0;
  } else {
    const _h_0 = _a_0["head"];
    const _t_0 = _a_0["tail"];
    return {$: "Con", "head": ($kt$("Use", "", ($ix$(_h_0)), run_loop($kc$(_join_0, run_clo((_x_0) => {
  return $qjoin$(($qt$(_h_0)), run_loop($uses_get$(_b_0, ($ix$(_h_0)))));
}), run_clo((_x_1) => {
  return $qadd$(($qt$(_h_0)), run_loop($uses_get$(_b_0, ($ix$(_h_0)))));
}))), {$: "Nil"})), "tail": ($uses_merge$(_t_0, run_loop($uses_del$(_b_0, ($ix$(_h_0)))), _join_0))};
  }
}

function $infer_app_type$(_e_0, _ctx_0, _t_0, _dem_0, _r_0, _ty_0) {
  return $kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  return $both$(_r_0, run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), run_loop($qdem$(($qt$(_ty_0)), _dem_0)), run_loop($kid$(_ty_0, 0)))), _t_0, run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), run_loop($kid$(_t_0, 1)))), false);
}), run_clo((_x_1) => {
  return $dg_bad_detail$("application requires a function type", ($dg_text$("a function type")), ($cy$(_r_0)));
}));
}

function $infer_adt_done$(_t_0, _r_0) {
  return $checked$(_r_0, _t_0, ($cy$(_r_0)));
}

function $tele_check$(_e_0, _ctx_0, _tel_0, _args_0, _dem_0) {
  if (_args_0.$ === "Nil") {
    return $ok$(($atom$("Args")), _tel_0, {$: "Nil"});
  } else {
    const _h_0 = _args_0["head"];
    const _t_0 = _args_0["tail"];
    return $tele_check_cached_head$(_e_0, _ctx_0, run_loop($wnf$(($cb$(_e_0)), _tel_0)), _h_0, _t_0, _dem_0);
  }
}

function $dg_adt_error$(_t_0, _d_0) {
  return $kc$(($String$eq$(($dk$(_d_0)), "ADT")), run_clo((_x_0) => {
  const _x_1 = ($da$(_d_0));
  const _x_4 = ($U32$show$(($da$(_d_0))));
  const _x_5 = run_loop($kc$((_x_1 === 1), run_clo((_x_2) => {
  return " parameter";
}), run_clo((_x_3) => {
  return " parameters";
})));
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ($nm$(_t_0));
  const _x_8 = (" with " + _x_6);
  return $dg_bad_detail$("unknown family or wrong parameter count", ($dg_text$((_x_7 + _x_8))), _t_0);
}), run_clo((_x_9) => {
  const _x_10 = ($nm$(_t_0));
  const _x_11 = (_x_10 + ")");
  return $dg_bad_message$("unknown family or wrong parameter count", ($dg_text$(("a declared datatype (unknown: " + _x_11))));
}));
}

function $nl_c_type$(_k_0) {
  if (_k_0.$ === "N_W32") {
    return "u32";
  } else if (_k_0.$ === "N_W64") {
    return "Term";
  } else {
    return "Term";
  }
}

function $nt_lines_go$($0, $1) {
  for (;;) {
    {
      const _s_0 = $0;
      const _acc_0 = $1;
      if (_s_0 === "") {
        return _acc_0;
      } else {
        const _h_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(0, 2) : _s_0[0]);
        const _t_0 = (_s_0.codePointAt(0) > 0xFFFF ? _s_0.slice(2) : _s_0.slice(1));
        const _x_2 = run_loop($nt_choose$(($Char$is_eq$(_h_0, "\n")), run_clo((_x_0) => {
  return "\n    ";
}), run_clo((_x_1) => {
  return (_h_0 + "");
})));
        $0 = _t_0;
        $1 = (_acc_0 + _x_2);
        continue;
      }
    }
  }
}

function $nc_keeps$(_word_0, _n_0) {
  return $nt_choose$((_n_0 <= 1), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = run_loop($nc_keeps$(_word_0, ((_n_0 - 1) >>> 0)));
  const _x_3 = (");\n" + _x_2);
  const _x_4 = (_word_0 + _x_3);
  const _x_5 = (" = term_keep(e, " + _x_4);
  return (_word_0 + _x_5);
}));
}

function $nc_parallel_uses$(_xs_0, _id_0) {
  if (_xs_0.$ === "Nil") {
    return 0;
  } else {
    const _h_0 = _xs_0["head"];
    const _rest_0 = _xs_0["tail"];
    const _x_0 = ($nt_bool$(run_loop($nc_occurs$(_h_0, _id_0))));
    const _x_1 = ($nc_parallel_uses$(_rest_0, _id_0));
    return ((_x_0 + _x_1) >>> 0);
  }
}

function $ne_frame_stores$(_ws_0, _i_0) {
  if (_ws_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ws_0["head"];
    const _t_0 = _ws_0["tail"];
    const _x_0 = ($ne_frame_stores$(_t_0, ((_i_0 + 1) >>> 0)));
    const _x_1 = (";\n" + _x_0);
    const _x_2 = (_h_0 + _x_1);
    const _x_3 = ($U32$show$(_i_0));
    const _x_4 = (") = " + _x_2);
    const _x_5 = (_x_3 + _x_4);
    return ("STK(" + _x_5);
  }
}

function $np_emit_done$(_book_0, _index_0, _last_0, _rest_0, _word_0, _env_0, _code_0) {
  return $nt_choose$(_last_0, run_clo((_x_0) => {
  const _x_1 = ($nc_body$(_code_0));
  const _x_2 = (_x_1 + "}\n");
  return {$: "NC_Code", "body": ("{\n" + _x_2), "segments": ($nc_segs$(_code_0)), "fresh": ($nc_fresh$(_code_0)), "error": ($nc_error$(_code_0))};
}), run_clo((_x_3) => {
  return $np_emit_join$(_index_0, _last_0, _word_0, _code_0, run_loop($np_emit$(_book_0, _rest_0, _word_0, _env_0, ($nc_fresh$(_code_0)))));
}));
}

function $np_row_code$(_book_0, _body_0, _residual_0, _apply_0, _word_0, _env_0, _next_0) {
  return $nt_choose$(_apply_0, run_clo((_x_0) => {
  const _x_1 = ($U32$show$(_residual_0));
  const _x_2 = (_x_1 + "ull);\n");
  const _x_3 = (" - " + _x_2);
  const _x_4 = (_word_0 + _x_3);
  const _x_5 = ($U32$show$(($nc_id$(_next_0))));
  const _x_6 = (" = (" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  return $nc_prepend$(("Term v_" + _x_7), ($nc_lower$(_book_0, ($app$(_body_0, ($var$("", ($nc_id$(_next_0)))))), {$: "Con", "head": ($nc_binding$(($nc_id$(_next_0)))), "tail": _env_0}, ((_next_0 + 1) >>> 0))));
}), run_clo((_x_8) => {
  return $nc_lower$(_book_0, _body_0, _env_0, _next_0);
}));
}

function $nc_field_word$(_name_0, _word_0, _i_0) {
  return $nt_choose$(($String$eq$(_name_0, "Succ")), run_clo((_x_0) => {
  const _x_1 = (_word_0 + " - 1)");
  return ("(" + _x_1);
}), run_clo((_x_2) => {
  return $nt_choose$(($String$eq$(_name_0, "Chr")), run_clo((_x_3) => {
  return _word_0;
}), run_clo((_x_4) => {
  const _x_5 = ($String$eq$(_name_0, "U32"));
  const _x_6 = ($String$eq$(_name_0, "F32"));
  return $nt_choose$((_x_5 || _x_6), run_clo((_x_7) => {
  const _x_8 = (_word_0 + ")");
  return ("native_word(e, (u32)" + _x_8);
}), run_clo((_x_9) => {
  return $nt_choose$(($String$eq$(_name_0, "ALeaf")), run_clo((_x_10) => {
  const _x_11 = (_word_0 + "), 0)");
  return ("blk_read(e.mem, 1, term_loc(" + _x_11);
}), run_clo((_x_12) => {
  return $nt_choose$(($String$eq$(_name_0, "ANode")), run_clo((_x_13) => {
  const _x_14 = ($U32$show$(_i_0));
  const _x_15 = (_x_14 + ")");
  const _x_16 = (", " + _x_15);
  const _x_17 = (_word_0 + _x_16);
  return ("blk_half(e, " + _x_17);
}), run_clo((_x_18) => {
  const _x_19 = ($U32$show$(_i_0));
  const _x_20 = (_x_19 + "]");
  const _x_21 = (") + " + _x_20);
  const _x_22 = (_word_0 + _x_21);
  return ("e.mem[term_peek(e, " + _x_22);
}));
}));
}));
}));
}));
}

function $f_module_def$(_d_0, _rest_0, _visible_0, _scope_0, _ns_0, _imports_0) {
  return {$: "Con", "head": run_loop($f_choose$(($String$is_empty$(_ns_0)), run_clo((_x_0) => {
  return $f_elab_def$(_d_0, _scope_0);
}), run_clo((_x_1) => {
  return $f_qual_def$(($f_elab_def$(_d_0, _scope_0)), _visible_0, _ns_0, _imports_0);
}))), "tail": ($f_module_defs$(_rest_0, _visible_0, _scope_0, _ns_0, _imports_0))};
}

function $f_alias_named$(_t_0, _imports_0, _scope_0, _name_0) {
  return $f_choose$(($Bool$and$(($Bool$and$(($Bool$not$(($String$eq$(_name_0, ($nm$(_t_0)))))), ($f_declared$(_name_0, _scope_0)))), ($f_declared$(($nm$(_t_0)), _scope_0)))), run_clo((_x_0) => {
  const _x_1 = ($nm$(_t_0));
  const _x_2 = (_x_1 + ")");
  return $kt$("Error", ("expected an unambiguous name (an import alias shadows " + _x_2), 0, 0, {$: "Nil"});
}), run_clo((_x_3) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": _name_0, "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($f_alias_terms$(($ks$(_t_0)), _imports_0, _scope_0)), "removed": ($rm$(_t_0))};
}));
}

function $f_alias$(_name_0, _imports_0) {
  if (_imports_0.$ === "Nil") {
    return _name_0;
  } else {
    const _im_0 = _imports_0["head"];
    const _rest_0 = _imports_0["tail"];
    const _x_0 = ($terms_len$(($ks$(_im_0))));
    const _x_1 = ($nm$(run_loop($kid$(_im_0, 0))));
    return $f_choose$(($Bool$and$((_x_0 > 0), run_loop($f_prefix$(_name_0, (_x_1 + "."))))), run_clo((_x_2) => {
  const _x_3 = ($nm$(run_loop($kid$(_im_0, 0))));
  const _x_4 = run_loop($f_drop_prefix$(_name_0, (_x_3 + ".")));
  const _x_5 = ($nm$(_im_0));
  const _x_6 = ("." + _x_4);
  return (_x_5 + _x_6);
}), run_clo((_x_7) => {
  return $f_alias$(_name_0, _rest_0);
}));
  }
}

function $f_path_push$(_part_0, _parts_0) {
  const _x_0 = ($String$is_empty$(_part_0));
  const _x_1 = ($f_eq$(_part_0, "."));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return _parts_0;
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(_part_0, "..")), run_clo((_x_4) => {
  return $f_path_parent$(_parts_0);
}), run_clo((_x_5) => {
  return {$: "Con", "head": _part_0, "tail": _parts_0};
}));
}));
}

function $tele_tip_head$(_book_0, _t_0) {
  return $kc$(($String$eq$(($tg$(_t_0)), "All")), run_clo((_x_0) => {
  return $tele_tip$(_book_0, run_loop($kid$(_t_0, 1)));
}), run_clo((_x_1) => {
  return _t_0;
}));
}

function $check_ctors_next$(_e_0, _d_0, _rest_0, _kind_0, _err_0) {
  return $kc$(($String$eq$(_err_0, "")), run_clo((_x_0) => {
  return $check_ctors$(_e_0, _d_0, _rest_0, _kind_0);
}), run_clo((_x_1) => {
  return _err_0;
}));
}

function $check_ctor_tel$(_e_0, _d_0, _tel_0, _kind_0, _params_0, _fields_0, _ctx_0, _args_0) {
  const _x_0 = ((_params_0 + _fields_0) >>> 0);
  return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return $kc$(run_loop($compare$(($cb$(_e_0)), _tel_0, ($kt$("ADT", ($dn$(_d_0)), 0, 0, _args_0)), false)), run_clo((_x_2) => {
  return "";
}), run_clo((_x_3) => {
  return "constructor result must apply family to its parameters";
}));
}), run_clo((_x_4) => {
  return $check_ctor_head$(_e_0, _d_0, run_loop($wnf$(($cb$(_e_0)), _tel_0)), _kind_0, _params_0, _fields_0, _ctx_0, _args_0);
}));
}

function $contains_self$(_todo_0, _name_0) {
  if (_todo_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _todo_0["head"];
    const _rest_0 = _todo_0["tail"];
    return $kc$(($Bool$and$(($String$eq$(($tg$(_h_0)), "Ref")), ($String$eq$(($nm$(_h_0)), _name_0)))), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $contains_self$(($norm_join$(($ks$(_h_0)), _rest_0)), _name_0);
}));
  }
}

function $tele_quantities_head$(_book_0, _ty_0, _n_0) {
  return {$: "Con", "head": ($qua$(run_loop($kc$(($String$eq$(($tg$(_ty_0)), "All")), run_clo((_x_0) => {
  return $qt$(_ty_0);
}), run_clo((_x_1) => {
  return 1;
}))))), "tail": run_loop($tele_quantities$(_book_0, run_loop($kid$(_ty_0, 1)), ((_n_0 - 1) >>> 0)))};
}

function $check_template_open$(_book_0, _d_0, _ty_0, _body_0, _lhs_0, _n_0, _name_0) {
  return $check_template_definition$(run_loop($book_put$(_book_0, {$: "KDef", "name": _name_0, "kind": "Def", "arity": 0, "templates": 0, "typ": run_loop($kid$(_ty_0, 0)), "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": true, "unsafe": false})), _d_0, run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($ref$(_name_0)))), run_loop($kapply$(_body_0, ($ref$(_name_0)))), ($app$(_lhs_0, ($ref$(_name_0)))), ((_n_0 - 1) >>> 0));
}

function $check_lam_q$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _q_0) {
  const _x_0 = ($qt$(_t_0));
  const _x_1 = ($qt$(_ty_0));
  return $check_lam_done$(_t_0, _ty_0, _q_0, run_loop($both$(run_loop($kc$(($Bool$and$((_x_0 === 2), (_x_1 === 1))), run_clo((_x_2) => {
  return $check$(_e_0, _ctx_0, run_loop($kid$(_ty_0, 0)), 0, ($typ$(run_loop($kindq$(_e_0, _q_0)))));
}), run_clo((_x_3) => {
  return $ok$(_t_0, _ty_0, {$: "Nil"});
}))), run_loop($check$(run_loop($lhs_step$(_e_0, ($var$(($nm$(_t_0)), ($ix$(_t_0)))))), ($ctx_bind$(_ctx_0, ($ix$(_t_0)), _q_0, ($nm$(_t_0)), run_loop($kid$(_ty_0, 0)))), run_loop($kid$(_t_0, 0)), _dem_0, run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), ($var$(($nm$(_t_0)), ($ix$(_t_0)))))))), _t_0, _ty_0, false)));
}

function $check_ctr_found$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _ctr_0) {
  const _x_0 = ($da$(_ctr_0));
  const _x_1 = ($terms_len$(($ks$(_t_0))));
  return $kc$(($Bool$and$(($Bool$and$(($Bool$not$(($String$eq$(($dk$(_ctr_0)), "Absent")))), ($Bool$not$(run_loop($has_name$(($rm$(_ty_0)), ($nm$(_t_0)))))))), (_x_0 === _x_1))), run_clo((_x_2) => {
  return $checked$(run_loop($tele_check$(_e_0, _ctx_0, run_loop($tele_fill$(($cb$(_e_0)), ($dt$(_ctr_0)), ($ks$(_ty_0)))), ($ks$(_t_0)), _dem_0)), _t_0, _ty_0);
}), run_clo((_x_3) => {
  return $dg_ctor_error$(_e_0, _t_0, _ty_0, _ctr_0);
}));
}

function $dg_bad_message$(_message_0, _expected_0) {
  return {$: "KChecked", "term": ($kt$("DDetail", "", 0, 0, {$: "Con", "head": _expected_0, "tail": {$: "Con", "head": ($atom$("Absent")), "tail": {$: "Nil"}}})), "typ": ($atom$("Error")), "uses": {$: "Nil"}, "error": _message_0};
}

function $check_mat_type$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _a_0) {
  return $kc$(($Bool$and$(($String$eq$(($tg$(_a_0)), "ADT")), ($String$eq$(($dk$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_a_0)))))), "ADT")))), run_clo((_x_0) => {
  return $kc$(($String$eq$(($tg$(_t_0)), "Efq")), run_clo((_x_1) => {
  const _x_2 = ($dead_type$(($cb$(_e_0)), _a_0));
  const _x_3 = run_loop($ctx_dead$(($cb$(_e_0)), _ctx_0));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $ok$(_t_0, _ty_0, {$: "Nil"});
}), run_clo((_x_5) => {
  const _x_6 = ($dg_constructor_names$(run_loop($remaining$(($dc$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_a_0)))))), ($rm$(_a_0))))));
  return $dg_bad_detail$("nonexhaustive match", ($dg_text$(("cases for " + _x_6))), _t_0);
}));
}), run_clo((_x_7) => {
  return $check_mat_ctr$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _a_0, run_loop($lookup$(run_loop($remaining$(($dc$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_a_0)))))), ($rm$(_a_0)))), ($nm$(_t_0)))));
}));
}), run_clo((_x_8) => {
  return $dg_bad_detail$("match scrutinee requires a datatype", ($dg_text$("a datatype")), run_loop($kid$(_ty_0, 0)));
}));
}

function $dg_bad_detail$(_message_0, _expected_0, _observed_0) {
  return {$: "KChecked", "term": ($kt$("DDetail", "", 0, 1, {$: "Con", "head": _expected_0, "tail": {$: "Con", "head": _observed_0, "tail": {$: "Nil"}}})), "typ": ($atom$("Error")), "uses": {$: "Nil"}, "error": _message_0};
}

function $check_let_value$(_e_0, _outer_0, _ctx_0, _h_0, _rest_0, _dem_0, _ty_0, _bindings_0, _us_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $check_let_kind$(_e_0, _outer_0, _ctx_0, _h_0, _rest_0, _dem_0, _ty_0, _bindings_0, _us_0, _r_0, run_loop($check$(_e_0, _outer_0, ($cy$(_r_0)), 0, ($typ$(run_loop($kindq$(_e_0, ($qt$(_h_0)))))))));
}), run_clo((_x_1) => {
  return _r_0;
}));
}

function $qdem$(_q_0, _d_0) {
  return $kc$((_q_0 === 0), run_clo((_x_0) => {
  return 0;
}), run_clo((_x_1) => {
  return _d_0;
}));
}

function $check_let_done$(_r_0, _bs_0, _us_0) {
  if (_bs_0.$ === "Nil") {
    return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $ok$(($ct$(_r_0)), ($cy$(_r_0)), ($uses_merge$(_us_0, ($cs$(_r_0)), false)));
}), run_clo((_x_1) => {
  return _r_0;
}));
  } else {
    const _h_0 = _bs_0["head"];
    const _t_0 = _bs_0["tail"];
    const _x_2 = run_loop($uses_get$(($cs$(_r_0)), ($ix$(_h_0))));
    const _x_3 = ($qt$(_h_0));
    return $kc$((_x_2 > _x_3), run_clo((_x_4) => {
  return $dg_quant_error$("let binder consumed more than allowed", ($nm$(_h_0)), ($qt$(_h_0)), run_loop($uses_get$(($cs$(_r_0)), ($ix$(_h_0)))));
}), run_clo((_x_5) => {
  return $kc$(($good$(_r_0)), run_clo((_x_6) => {
  return $check_let_done$(($ok$(($ct$(_r_0)), ($cy$(_r_0)), run_loop($uses_del$(($cs$(_r_0)), ($ix$(_h_0)))))), _t_0, _us_0);
}), run_clo((_x_7) => {
  return _r_0;
}));
}));
  }
}

function $let_cells$($0, $1) {
  for (;;) {
    {
      const _body_0 = $0;
      const _bs_0 = $1;
      if (_bs_0.$ === "Nil") {
        return _body_0;
      } else {
        const _h_0 = _bs_0["head"];
        const _t_0 = _bs_0["tail"];
        $0 = run_loop($subst$(_body_0, ($ix$(_h_0)), ($kt$("Var", ($nm$(_h_0)), ($ix$(_h_0)), 0, {$: "Con", "head": run_loop($kid$(_h_0, 0)), "tail": {$: "Nil"}}))));
        $1 = _t_0;
        continue;
      }
    }
  }
}

function $check_rwt_type$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _r_0, _eq_0) {
  return $kc$(($String$eq$(($tg$(_eq_0)), "Eql")), run_clo((_x_0) => {
  const _x_1 = ($norm_max_term$(_t_0));
  const _x_2 = run_loop($norm_book_bound$(($cb$(_e_0))));
  const _x_3 = ((_x_1 + 1) >>> 0);
  return $check_rwt_goal$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _r_0, _eq_0, ((_x_2 + _x_3) >>> 0));
}), run_clo((_x_4) => {
  return $dg_bad_detail$("rewrite requires equality evidence", ($dg_text$("an equation {a == b : T}")), ($cy$(_r_0)));
}));
}

function $norm_cmp_test$(_book_0, _yes_0, _rest_0, _alts_0) {
  return $kc$(_yes_0, run_clo((_x_0) => {
  return $norm_cmp_loop$(_book_0, _rest_0, _alts_0);
}), run_clo((_x_1) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}

function $norm_cmp_kind$(_book_0, _a_0, _b_0, _g_0, _h_0, _fresh_0, _rest_0, _alts_0) {
  const _x_0 = ($qt$(_g_0));
  const _x_1 = ($qt$(_h_0));
  const _x_2 = ($Bool$and$(($String$eq$(($tg$(_g_0)), "Qua")), (_x_0 === 2)));
  const _x_3 = ($Bool$and$(($String$eq$(($tg$(_h_0)), "Qua")), ($Bool$not$((_x_1 === 2)))));
  return $kc$((_x_2 || _x_3), run_clo((_x_4) => {
  return $norm_cmp_loop$(_book_0, _rest_0, _alts_0);
}), run_clo((_x_5) => {
  return $kc$(($String$eq$(($tg$(_g_0)), "Min")), run_clo((_x_6) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": ($kt$("Typ", "", 0, 0, {$: "Con", "head": run_loop($kid$(_g_0, 0)), "tail": {$: "Nil"}})), "b": _b_0, "le": true, "fresh": _fresh_0}, "tail": {$: "Con", "head": {$: "KNormCmp", "a": ($kt$("Typ", "", 0, 0, {$: "Con", "head": run_loop($kid$(_g_0, 1)), "tail": {$: "Nil"}})), "b": _b_0, "le": true, "fresh": _fresh_0}, "tail": _rest_0}}, _alts_0);
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_h_0)), "Min")), run_clo((_x_8) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": _a_0, "b": ($kt$("Typ", "", 0, 0, {$: "Con", "head": run_loop($kid$(_h_0, 0)), "tail": {$: "Nil"}})), "le": true, "fresh": _fresh_0}, "tail": _rest_0}, {$: "Con", "head": {$: "KNormAlt", "todo": {$: "Con", "head": {$: "KNormCmp", "a": _a_0, "b": ($kt$("Typ", "", 0, 0, {$: "Con", "head": run_loop($kid$(_h_0, 1)), "tail": {$: "Nil"}})), "le": true, "fresh": _fresh_0}, "tail": _rest_0}}, "tail": _alts_0});
}), run_clo((_x_9) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": _g_0, "b": _h_0, "le": true, "fresh": _fresh_0}, "tail": _rest_0}, _alts_0);
}));
}));
}));
}

function $norm_removed$(_as_0, _bs_0, _le_0) {
  return $kc$(_le_0, run_clo((_x_0) => {
  return $norm_subset$(_as_0, _bs_0);
}), run_clo((_x_1) => {
  const _x_2 = ($norm_names_len$(_as_0));
  const _x_3 = ($norm_names_len$(_bs_0));
  return $Bool$and$((_x_2 === _x_3), ($norm_subset$(_as_0, _bs_0)));
}));
}

function $norm_cmp_fields$(_book_0, _as_0, _bs_0, _fresh_0, _rest_0, _alts_0) {
  const _x_0 = ($terms_len$(_as_0));
  const _x_1 = ($terms_len$(_bs_0));
  return $kc$((_x_0 === _x_1), run_clo((_x_2) => {
  return $norm_cmp_loop$(_book_0, ($norm_cmp_zip$(_as_0, _bs_0, _fresh_0, _rest_0)), _alts_0);
}), run_clo((_x_3) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}

function $norm_cmp_plain$(_book_0, _a_0, _b_0, _le_0, _fresh_0, _rest_0, _alts_0) {
  return $kc$(($Bool$and$(run_loop($core_nat$(_a_0)), run_loop($core_nat$(_b_0)))), run_clo((_x_0) => {
  const _x_1 = ($qt$(_a_0));
  const _x_2 = ($qt$(_b_0));
  return $norm_cmp_test$(_book_0, (_x_1 === _x_2), _rest_0, _alts_0);
}), run_clo((_x_3) => {
  return $kc$(($String$eq$(($tg$(_a_0)), "Ref")), run_clo((_x_4) => {
  return $kc$(($String$eq$(($nm$(_a_0)), ($nm$(_b_0)))), run_clo((_x_5) => {
  return $norm_cmp_loop$(_book_0, _rest_0, _alts_0);
}), run_clo((_x_6) => {
  return $norm_cmp_ref$(_book_0, _a_0, _b_0, _le_0, run_loop($norm_max$(($da$(run_loop($lookup$(_book_0, ($nm$(_a_0)))))), ($da$(run_loop($lookup$(_book_0, ($nm$(_b_0)))))))), _fresh_0, _rest_0, _alts_0);
}));
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_a_0)), "Hol")), run_clo((_x_8) => {
  return $norm_cmp_test$(_book_0, ($String$eq$(($nm$(_a_0)), ($nm$(_b_0)))), _rest_0, _alts_0);
}), run_clo((_x_9) => {
  const _x_10 = ($String$eq$(($tg$(_a_0)), "Ctr"));
  const _x_11 = ($String$eq$(($tg$(_a_0)), "Mat"));
  return $kc$((_x_10 || _x_11), run_clo((_x_12) => {
  return $kc$(($String$eq$(($nm$(_a_0)), ($nm$(_b_0)))), run_clo((_x_13) => {
  return $norm_cmp_fields$(_book_0, ($ks$(_a_0)), ($ks$(_b_0)), _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_14) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}), run_clo((_x_15) => {
  return $kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_a_0)), "App")), ($String$eq$(($tg$(run_loop($kid$(_a_0, 0)))), "Ref")))), ($String$eq$(($tg$(run_loop($kid$(_b_0, 0)))), "Ref")))), run_clo((_x_16) => {
  return $kc$(($String$eq$(($nm$(run_loop($kid$(_a_0, 0)))), ($nm$(run_loop($kid$(_b_0, 0)))))), run_clo((_x_17) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": run_loop($kid$(_a_0, 1)), "b": run_loop($kid$(_b_0, 1)), "le": false, "fresh": _fresh_0}, "tail": _rest_0}, _alts_0);
}), run_clo((_x_18) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}));
}), run_clo((_x_19) => {
  const _x_20 = ($String$eq$(($tg$(_a_0)), "App"));
  const _x_21 = ($String$eq$(($tg$(_a_0)), "Min"));
  const _x_22 = (_x_20 || _x_21);
  const _x_23 = ($String$eq$(($tg$(_a_0)), "Eql"));
  const _x_24 = (_x_22 || _x_23);
  const _x_25 = ($String$eq$(($tg$(_a_0)), "Rwt"));
  return $kc$((_x_24 || _x_25), run_clo((_x_26) => {
  return $norm_cmp_fields$(_book_0, ($ks$(_a_0)), ($ks$(_b_0)), _fresh_0, _rest_0, _alts_0);
}), run_clo((_x_27) => {
  const _x_28 = ($String$eq$(($tg$(_a_0)), "Qnt"));
  const _x_29 = ($String$eq$(($tg$(_a_0)), "Rfl"));
  const _x_30 = (_x_28 || _x_29);
  const _x_31 = ($String$eq$(($tg$(_a_0)), "Efq"));
  return $norm_cmp_test$(_book_0, (_x_30 || _x_31), _rest_0, _alts_0);
}));
}));
}));
}));
}));
}));
}

function $fp_at_token$(_t_0, _definition_0, _text_0, _tokens_0, _route_0) {
  if (_tokens_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _token_0 = _tokens_0["head"];
    return $fp_token_origin$(_t_0, _definition_0, _text_0, _token_0, _route_0);
  }
}

function $fp_find_token$(_tokens_0, _line_0, _column_0) {
  if (_tokens_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _token_0 = _tokens_0["head"];
    const _rest_0 = _tokens_0["tail"];
    const _x_0 = ($f_line$({$: "Con", "head": _token_0, "tail": _rest_0}));
    const _x_1 = ($f_col$({$: "Con", "head": _token_0, "tail": _rest_0}));
    return $f_choose$(($Bool$and$((_x_0 === _line_0), (_x_1 === _column_0))), run_clo((_x_2) => {
  return {$: "Con", "head": _token_0, "tail": _rest_0};
}), run_clo((_x_3) => {
  return $fp_find_token$(_rest_0, _line_0, _column_0);
}));
  }
}

function $j_projection_slot$(_id_0, _slots_0) {
  if (_slots_0.$ === "Nil") {
    return "";
  } else {
    const _s_0 = _slots_0["head"];
    const _rest_0 = _slots_0["tail"];
    const _x_0 = ($ix$(_s_0));
    return $kc$((_id_0 === _x_0), run_clo((_x_1) => {
  return $U32$show$(($qt$(_s_0)));
}), run_clo((_x_2) => {
  return $j_projection_slot$(_id_0, _rest_0);
}));
  }
}

function $f_args_base$(_ts_0, _end_0, _acc_0) {
  const _spaced_0 = run_loop($f_space$(_ts_0));
  return $f_choose$(($f_eq$(($f_tx$(_spaced_0)), ";")), run_clo((_x_0) => {
  return $fpe_error$(_spaced_0, run_loop($f_choose$(($f_eq$(_end_0, "]")), run_clo((_x_1) => {
  return "expected term; a list does not use semicolon separators";
}), run_clo((_x_2) => {
  return "expected term; arguments do not use semicolon separators";
}))), "a term");
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($f_tx$(_spaced_0)), _end_0)), run_clo((_x_4) => {
  return {$: "FParsed", "term": ($kt$("Args", "", 0, 1, ($List$reverse$(_acc_0)))), "rest": ($f_tl$(_spaced_0))};
}), run_clo((_x_5) => {
  return $f_arg_next$(run_loop($f_expr$(_spaced_0, 0)), _end_0, _acc_0);
}));
}));
}

function $f_family_first_done$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  const _x_2 = ($f_eq$(($f_tx$(run_loop($f_space$(_ts_0)))), "&"));
  const _x_3 = ($f_eq$(($f_tx$(run_loop($f_space$(_ts_0)))), "|"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(($f_tx$(run_loop($f_space$(_ts_0)))), "->"));
  return $f_choose$((_x_4 || _x_5), run_clo((_x_6) => {
  return $fpe_error$(run_loop($f_space$(_ts_0)), "a compound type argument takes parentheses", "'>' or ',' (a compound type argument takes parens: F<(A & B)>)");
}), run_clo((_x_7) => {
  return $f_arg_next$({$: "FParsed", "term": _n_0, "rest": _ts_0}, ">", {$: "Nil"});
}));
}));
}

function $f_binary_plain$(_a_0, _op_0, _b_0) {
  return $f_choose$(($f_eq$(_op_0, "=>")), run_clo((_x_0) => {
  return $f_lambda_valid$(_a_0, _b_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(_op_0, "->")), run_clo((_x_2) => {
  return $kt$("All", "_", ($ix$(_a_0)), 1, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(_op_0, "<>")), run_clo((_x_4) => {
  return $kt$("Ctr", "Con", 0, 1, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(_op_0, "<&>")), run_clo((_x_6) => {
  return $kt$("Min", "", 0, 1, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}), run_clo((_x_7) => {
  return $f_app$(($kt$("Ref", run_loop($f_operator$(_op_0)), 0, 1, {$: "Nil"})), {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}));
}));
}));
}));
}

function $f_namespace_head$(_t_0) {
  const _x_0 = ($f_eq$(($tg$(_t_0)), "App"));
  const _x_1 = ($f_eq$(($tg$(_t_0)), "Call"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_namespace_head$(run_loop($kid$(_t_0, 0)));
}), run_clo((_x_3) => {
  return _t_0;
}));
}

function $f_namespace_operator$(_head_0) {
  const _x_0 = ($Char$is_eq$(($f_head$(($nm$(_head_0)))), "."));
  const _x_1 = ($f_eq$(($nm$(_head_0)), "Bool.and"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($f_eq$(($nm$(_head_0)), "Bool.or"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($f_eq$(($nm$(_head_0)), "String.append"));
  return $Bool$and$(($f_eq$(($tg$(_head_0)), "Ref")), (_x_4 || _x_5));
}

function $f_namespace_terms$(_terms_0, _ty_0) {
  if (_terms_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _term_0 = _terms_0["head"];
    const _rest_0 = _terms_0["tail"];
    return {$: "Con", "head": run_loop($f_namespace$(_term_0, _ty_0)), "tail": ($f_namespace_terms$(_rest_0, _ty_0))};
  }
}

function $f_do_parameters$(_monad_0, _ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "<>")), run_clo((_x_0) => {
  return $f_do_types$(_monad_0, {$: "FParsed", "term": ($kt$("Args", "", 0, 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))});
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "<")), run_clo((_x_2) => {
  return $f_do_parameters_open$(_monad_0, run_loop($f_space$(($f_tl$(_ts_0)))));
}), run_clo((_x_3) => {
  return $fpe_error$(_ts_0, "expected <", "'<'");
}));
}));
}

function $f_rewrite_proof$(_name_0, _id_0, _p_0) {
  const _e_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_rewrite_motive$(_name_0, _id_0, _e_0, run_loop($f_expr$(_ts_0, 0)));
}

function $f_tuple$(_n_0, _p_0) {
  const _m_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Ctr", "Tuple", 0, 1, {$: "Con", "head": _n_0, "tail": {$: "Con", "head": _m_0, "tail": {$: "Nil"}}})), "rest": _ts_0};
}

function $f_group_namespace$(_n_0, _p_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": run_loop($f_choose$(($String$is_empty$(($f_error_term$(_n_0)))), run_clo((_x_1) => {
  return _ty_0;
}), run_clo((_x_2) => {
  return _n_0;
}))), "rest": _ts_0};
}), run_clo((_x_3) => {
  return {$: "FParsed", "term": run_loop($f_namespace$(_n_0, _ty_0)), "rest": _ts_0};
}));
}

function $f_body_context$(_ts_0, _outer_0) {
  return $f_body_context_at$(run_loop($f_skip$(_ts_0)), _outer_0);
}

function $f_brace_left$(_p_0) {
  const _a_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  const _x_0 = ($f_eq$(($f_tx$(_ts_0)), "=="));
  const _x_1 = ($f_eq$(($f_tx$(_ts_0)), "!="));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_equation$(_a_0, ($f_eq$(($f_tx$(_ts_0)), "!=")), run_loop($f_expect$(run_loop($f_expr$(($f_tl$(_ts_0)), 0)), ":")));
}), run_clo((_x_3) => {
  return $f_group_ann$(_a_0, run_loop($f_expect$(run_loop($f_expr$(($f_pr$(run_loop($f_expect$({$: "FParsed", "term": _a_0, "rest": _ts_0}, ":")))), 0)), "}")));
}));
}

function $f_array_first$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_2) => {
  return $f_array_type$(_n_0, run_loop($f_expr$(($f_tl$(_ts_0)), 12)));
}), run_clo((_x_3) => {
  return $f_list$(run_loop($f_args$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), ",")), run_clo((_x_4) => {
  return $f_tl$(_ts_0);
}), run_clo((_x_5) => {
  return _ts_0;
}))), "]", {$: "Con", "head": _n_0, "tail": {$: "Nil"}})));
}));
}));
}

function $f_all_domain$(_name_0, _id_0, _q_0, _exi_0, _p_0) {
  const _a_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_all_body$(_name_0, _id_0, _q_0, _exi_0, _a_0, run_loop($f_expr$(_ts_0, 0)));
}

function $f_matcher_head$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_n_0)), "Ref")), ($f_eq$(($f_tx$(_ts_0)), ":")))), run_clo((_x_0) => {
  return $f_matcher_arm$(($nm$(_n_0)), run_loop($f_expr$(($f_tl$(_ts_0)), 0)));
}), run_clo((_x_1) => {
  return $f_expect$({$: "FParsed", "term": _n_0, "rest": _ts_0}, "}");
}));
}

function $f_kind$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _ts_0["head"];
    const _k_0 = _t_0["f_kind"];
    return _k_0;
  }
}

function $f_atom_nat_start$(_ts_0, _lit_0) {
  return $f_choose$(($f_eq$(($tg$(_lit_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _lit_0, "rest": {$: "Nil"}};
}), run_clo((_x_1) => {
  return $f_atom_nat_plus$(_lit_0, run_loop($f_expr$(($f_tl$(($f_tl$(_ts_0)))), 0)));
}));
}

function $f_literal$(_s_0) {
  return $f_choose$(($Char$is_eq$(($f_head$(_s_0)), "\"")), run_clo((_x_0) => {
  return $f_string$(($f_tail$(_s_0)));
}), run_clo((_x_1) => {
  return $f_choose$(($Char$is_eq$(($f_head$(_s_0)), "'")), run_clo((_x_2) => {
  return $f_char_literal$(($f_tail$(_s_0)));
}), run_clo((_x_3) => {
  return $f_choose$(run_loop($f_contains$(_s_0, ".")), run_clo((_x_4) => {
  return $f_float$(_s_0);
}), run_clo((_x_5) => {
  return $f_number$(_s_0, 0);
}));
}));
}));
}

function $f_atom_constructor$(_name_0, _id_0, _p_0) {
  const _args_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_args_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _args_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return {$: "FParsed", "term": ($kt$("Ctr", _name_0, _id_0, 1, ($ks$(_args_0)))), "rest": _ts_0};
}));
}

function $f_foreign_path_valid$(_ts_0) {
  const _x_0 = ($f_kind$(($f_tl$(_ts_0))));
  const _x_1 = ($String$ends_with$(run_loop($f_unquote$(($f_tx$(($f_tl$(_ts_0)))))), ".c"));
  const _x_2 = ($String$ends_with$(run_loop($f_unquote$(($f_tx$(($f_tl$(_ts_0)))))), ".js"));
  return $Bool$and$(($Bool$and$((_x_0 === 2), ($Char$is_eq$(($f_head$(($f_tx$(($f_tl$(_ts_0)))))), "\"")))), (_x_1 || _x_2));
}

function $f_unquote$(_s_0) {
  return $f_unquote_chars$(($f_tail$(_s_0)));
}

function $fpe_foreign$(_ts_0) {
  return $f_choose$(($Char$is_eq$(($f_head$(($f_tx$(_ts_0)))), "\"")), run_clo((_x_0) => {
  return $kt$("Error", "foreign import requires a quoted .c or .js path", 0, 0, {$: "Nil"});
}), run_clo((_x_1) => {
  return $f_pn$(($fpe_legacy$(_ts_0, "foreign import requires a quoted .c or .js path", "'\"'")));
}));
}

function $f_put$(_d_0, _book_0) {
  return {$: "Con", "head": _d_0, "tail": _book_0};
}

function $fc_start$(_pars_0, _ty_0, _body_0, _filled_0) {
  const _x_2 = run_loop($f_choose$(_filled_0, run_clo((_x_0) => {
  return $terms_len$(_pars_0);
}), run_clo((_x_1) => {
  return $fc_term$(_ty_0, {$: "Nil"});
})));
  const _x_3 = run_loop($fc_term$(_body_0, _pars_0));
  return ((_x_2 + _x_3) >>> 0);
}

function $f_ctor_more$(_name_0, _found_0, _rest_0) {
  return $f_choose$(($f_eq$(($dk$(_found_0)), "Missing")), run_clo((_x_0) => {
  return $f_ctor_lookup$(_name_0, _rest_0);
}), run_clo((_x_1) => {
  return _found_0;
}));
}

function $f_param_refs$(_pars_0) {
  if (_pars_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _p_0 = _pars_0["head"];
    const _ps_0 = _pars_0["tail"];
    return {$: "Con", "head": ($kt$("Ref", ($nm$(_p_0)), ($ix$(_p_0)), ($qt$(_p_0)), {$: "Nil"})), "tail": ($f_param_refs$(_ps_0))};
  }
}

function $ffw_frame$($0, $1, $2, $3, $4, $5) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _term_0 = $0;
      const _next_0 = $1;
      const _stack_0 = $2;
      if (_stack_0.$ === "Nil") {
        return {$: "FFresh", "term": _term_0, "next": _next_0};
      } else {
        const _frame_0 = _stack_0["head"];
        const _rest_0 = _stack_0["tail"];
        $0 = _frame_0;
        $1 = _term_0;
        $2 = _next_0;
        $3 = _rest_0;
        $pc = 1; continue;
      }
    }
    case 1: {
      const _frame_0 = $0;
      const _value_0 = $1;
      const _next_0 = $2;
      const _stack_0 = $3;
      if (_frame_0.$ === "FFAllA") {
        const _term_0 = _frame_0["term"];
        const _env_0 = _frame_0["env"];
        const _id_0 = _frame_0["id"];
        return $ffw_walk$(run_loop($kid$(_term_0, 1)), {$: "Con", "head": ($kt$("Map", "", ($ix$(_term_0)), 0, {$: "Con", "head": ($var$(($nm$(_term_0)), _id_0)), "tail": {$: "Nil"}})), "tail": _env_0}, _next_0, {$: "Con", "head": {$: "FFAllB", "term": _term_0, "id": _id_0, "typ": _value_0}, "tail": _stack_0});
      } else if (_frame_0.$ === "FFAllB") {
        const _term_1 = _frame_0["term"];
        const _id_1 = _frame_0["id"];
        const _typ_0 = _frame_0["typ"];
        $0 = ($kt$("All", ($nm$(_term_1)), _id_1, ($qt$(_term_1)), {$: "Con", "head": _typ_0, "tail": {$: "Con", "head": _value_0, "tail": {$: "Nil"}}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFLambda") {
        const _term_2 = _frame_0["term"];
        const _id_2 = _frame_0["id"];
        $0 = ($kt$("Lam", ($nm$(_term_2)), _id_2, ($qt$(_term_2)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else if (_frame_0.$ === "FFKids") {
        const _term_3 = _frame_0["term"];
        const _env_1 = _frame_0["env"];
        const _pending_0 = _frame_0["pending"];
        const _built_0 = _frame_0["built"];
        $0 = _term_3;
        $1 = _env_1;
        $2 = _pending_0;
        $3 = {$: "Con", "head": _value_0, "tail": _built_0};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 2; continue;
      } else if (_frame_0.$ === "FFLetValue") {
        const _env_2 = _frame_0["env"];
        const _bodyenv_0 = _frame_0["bodyenv"];
        const _id_3 = _frame_0["id"];
        const _binding_0 = _frame_0["binding"];
        const _pending_1 = _frame_0["pending"];
        const _built_1 = _frame_0["built"];
        $0 = _env_2;
        $1 = {$: "Con", "head": ($kt$("Map", "", ($ix$(_binding_0)), 0, {$: "Con", "head": ($var$(($nm$(_binding_0)), _id_3)), "tail": {$: "Nil"}})), "tail": _bodyenv_0};
        $2 = _pending_1;
        $3 = {$: "Con", "head": ($kt$("Bind", ($nm$(_binding_0)), _id_3, ($qt$(_binding_0)), {$: "Con", "head": _value_0, "tail": {$: "Nil"}})), "tail": _built_1};
        $4 = _next_0;
        $5 = _stack_0;
        $pc = 3; continue;
      } else {
        const _built_2 = _frame_0["built"];
        $0 = ($kt$("Let", "", 0, 1, ($ffw_reverse_onto$(_built_2, {$: "Con", "head": _value_0, "tail": {$: "Nil"}}))));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      }
    }
    case 2: {
      const _term_0 = $0;
      const _env_0 = $1;
      const _pending_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_pending_0.$ === "Nil") {
        $0 = {$: "KTerm", "tag": ($tg$(_term_0)), "name": ($nm$(_term_0)), "id": ($ix$(_term_0)), "quant": ($qt$(_term_0)), "kids": ($List$reverse$(_built_0)), "removed": ($rm$(_term_0))};
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _head_0 = _pending_0["head"];
        const _rest_0 = _pending_0["tail"];
        return $ffw_walk$(_head_0, _env_0, _next_0, {$: "Con", "head": {$: "FFKids", "term": _term_0, "env": _env_0, "pending": _rest_0, "built": _built_0}, "tail": _stack_0});
      }
    }
    case 3: {
      const _env_0 = $0;
      const _bodyenv_0 = $1;
      const _items_0 = $2;
      const _built_0 = $3;
      const _next_0 = $4;
      const _stack_0 = $5;
      if (_items_0.$ === "Nil") {
        $0 = ($kt$("Error", "empty core let", 0, 0, {$: "Nil"}));
        $1 = _next_0;
        $2 = _stack_0;
        $pc = 0; continue;
      } else {
        const _term_0 = _items_0["head"];
        const _tail_0 = _items_0["tail"];
        return $ffw_let_tail$(_env_0, _bodyenv_0, _term_0, _tail_0, _built_0, _next_0, _stack_0);
      }
    }
  }
}

function $ffw_let_tail$(_env_0, _bodyenv_0, _term_0, _tail_0, _built_0, _next_0, _stack_0) {
  if (_tail_0.$ === "Nil") {
    return $ffw_walk$(_term_0, _bodyenv_0, _next_0, {$: "Con", "head": {$: "FFLetBody", "built": _built_0}, "tail": _stack_0});
  } else {
    const _head_0 = _tail_0["head"];
    const _rest_0 = _tail_0["tail"];
    return $ffw_walk$(run_loop($kid$(_term_0, 0)), _env_0, ((_next_0 + 1) >>> 0), {$: "Con", "head": {$: "FFLetValue", "env": _env_0, "bodyenv": _bodyenv_0, "id": _next_0, "binding": _term_0, "pending": {$: "Con", "head": _head_0, "tail": _rest_0}, "built": _built_0}, "tail": _stack_0});
  }
}

function $f_declared$(_name_0, _book_0) {
  if (_book_0.$ === "Nil") {
    return false;
  } else {
    const _d_0 = _book_0["head"];
    const _ds_0 = _book_0["tail"];
    const _x_0 = ($f_eq$(_name_0, ($dn$(_d_0))));
    const _x_1 = ($f_declared$(_name_0, ($dc$(_d_0))));
    const _x_2 = (_x_0 || _x_1);
    const _x_3 = ($f_declared$(_name_0, _ds_0));
    return (_x_2 || _x_3);
  }
}

function $f_do_bind_types$(_types_0, _ty_0) {
  if (_types_0.$ === "Nil") {
    return {$: "Con", "head": _ty_0, "tail": {$: "Nil"}};
  } else {
    const _head_0 = _types_0["head"];
    const _rest_0 = _types_0["tail"];
    return $norm_join$(run_loop($f_init$({$: "Con", "head": _head_0, "tail": _rest_0})), {$: "Con", "head": _ty_0, "tail": {$: "Con", "head": run_loop($f_last$({$: "Con", "head": _head_0, "tail": _rest_0})), "tail": {$: "Nil"}}});
  }
}

function $f_leading_quants$(_ty_0) {
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_ty_0)), "All")), ($f_eq$(($tg$(run_loop($kid$(_ty_0, 0)))), "Qnt")))), run_clo((_x_0) => {
  const _x_1 = run_loop($f_leading_quants$(run_loop($kid$(_ty_0, 1))));
  return ((1 + _x_1) >>> 0);
}), run_clo((_x_2) => {
  return 0;
}));
}

function $f_adt_fill$(_t_0, _args_0, _arity_0, _g_0) {
  const _x_0 = ($terms_len$(_args_0));
  const _x_1 = ((_x_0 + _g_0) >>> 0);
  return $f_choose$((_x_1 === _arity_0), run_clo((_x_2) => {
  const _x_3 = ($qt$(_t_0));
  return {$: "KTerm", "tag": "ADT", "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($norm_join$(run_loop($f_quants$(_g_0, run_loop($f_choose$((_x_3 === 2), run_clo((_x_4) => {
  return 2;
}), run_clo((_x_5) => {
  return 1;
}))))), _args_0)), "removed": ($rm$(_t_0))};
}), run_clo((_x_6) => {
  const _x_7 = ($qt$(_t_0));
  return {$: "KTerm", "tag": "ADT", "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": run_loop($f_choose$((_x_7 === 2), run_clo((_x_8) => {
  return $norm_join$(run_loop($f_quants$(_g_0, 2)), run_loop($f_drop_terms$(_args_0, _g_0)));
}), run_clo((_x_9) => {
  return _args_0;
}))), "removed": ($rm$(_t_0))};
}));
}

function $f_scope_marked$(_t_0, _bound_0, _definition_0, _called_0) {
  return $f_choose$(($f_eq$(($dk$(_definition_0)), "ADT")), run_clo((_x_0) => {
  return $f_adt$({$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": 2, "kids": ($ks$(_t_0)), "removed": ($rm$(_t_0))}, {$: "Nil"}, _definition_0);
}), run_clo((_x_1) => {
  const _x_2 = ($Bool$not$(($f_eq$(($tg$(_bound_0)), "Absent"))));
  const _x_3 = ($Bool$and$(($Bool$not$(_called_0)), ($Bool$not$(($String$contains$(($nm$(_t_0)), "."))))));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $kt$("FUnboundVar", ($nm$(_t_0)), ($ix$(_t_0)), 0, {$: "Nil"});
}), run_clo((_x_5) => {
  return $kt$("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ($ix$(_t_0)), 0, {$: "Nil"});
}));
}));
}

function $f_templates_valid$(_args_0, _left_0, _ordinary_0) {
  if (_args_0.$ === "Nil") {
    return true;
  } else {
    const _a_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return $f_choose$(($f_eq$(($tg$(_a_0)), "TemplateArg")), run_clo((_x_0) => {
  return $Bool$and$(($Bool$and$(($Bool$not$(_ordinary_0)), (_left_0 > 0))), run_loop($f_templates_valid$(_rest_0, ((_left_0 - 1) >>> 0), false)));
}), run_clo((_x_1) => {
  return $f_templates_valid$(_rest_0, _left_0, true);
}));
  }
}

function $f_tail_terms$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _xt_0 = _xs_0["tail"];
    return _xt_0;
  }
}

function $f_scope_apply_many$($0, $1) {
  for (;;) {
    {
      const _head_0 = $0;
      const _args_0 = $1;
      if (_args_0.$ === "Nil") {
        return _head_0;
      } else {
        const _a_0 = _args_0["head"];
        const _rest_0 = _args_0["tail"];
        $0 = run_loop($f_scope_app$(_head_0, _a_0));
        $1 = _rest_0;
        continue;
      }
    }
  }
}

function $f_scope_call_args$(_args_0, _env_0, _book_0) {
  if (_args_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _a_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return {$: "Con", "head": run_loop($f_scope$(run_loop($f_choose$(($f_eq$(($tg$(_a_0)), "TemplateArg")), run_clo((_x_0) => {
  return $kid$(_a_0, 0);
}), run_clo((_x_1) => {
  return _a_0;
}))), _env_0, _book_0)), "tail": ($f_scope_call_args$(_rest_0, _env_0, _book_0))};
  }
}

function $f_sub$(_t_0, _id_0, _v_0) {
  const _x_0 = ($ix$(_t_0));
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_t_0)), "Var")), (_x_0 === _id_0))), run_clo((_x_1) => {
  return _v_0;
}), run_clo((_x_2) => {
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($f_subs$(($ks$(_t_0)), _id_0, _v_0)), "removed": ($rm$(_t_0))};
}));
}

function $f_scope_ref$(_t_0, _bound_0, _book_0) {
  return $f_scope_reference$(_t_0, _bound_0, _book_0);
}

function $f_scope_lambda$(_t_0, _env_0, _book_0) {
  const _x_0 = ($qt$(_t_0));
  const _x_3 = ($qt$(_t_0));
  return $f_scope_lambda_var$(_t_0, _env_0, _book_0, ($kt$(run_loop($f_choose$((_x_0 === 4), run_clo((_x_1) => {
  return "RewriteVar";
}), run_clo((_x_2) => {
  return "Var";
}))), ($nm$(_t_0)), ($ix$(_t_0)), run_loop($f_choose$((_x_3 === 4), run_clo((_x_4) => {
  return 1;
}), run_clo((_x_5) => {
  return $qt$(_t_0);
}))), {$: "Nil"})));
}

function $ff_term$(_r_0) {
  const _t_0 = _r_0["term"];
  return _t_0;
}

function $ff_flat$(_t_0, _vars_0, _next_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Match")), run_clo((_x_0) => {
  return $ff_match$(($ks$(run_loop($kid$(_t_0, 0)))), ($f_tail_terms$(($ks$(_t_0)))), _vars_0, _next_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Local")), run_clo((_x_2) => {
  return $ff_local$(_t_0, _vars_0, _next_0);
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Parallel")), run_clo((_x_4) => {
  return $ff_parallel$(_t_0, _vars_0, run_loop($ff_flat$(run_loop($kid$(_t_0, 2)), ($ks$(run_loop($kid$(_t_0, 0)))), _next_0)));
}), run_clo((_x_5) => {
  return {$: "FFlatten", "term": ($f_lbind$(_vars_0, _t_0)), "next": _next_0};
}));
}));
}));
}

function $f_scope_body$(_t_0, _env_0, _book_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Parallel")), run_clo((_x_0) => {
  return $f_scope_parallel$(_t_0, _env_0, _book_0);
}), run_clo((_x_1) => {
  return $f_scope_body_base$(_t_0, _env_0, _book_0);
}));
}

function $f_vars$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    return {$: "Con", "head": ($kt$("Var", ($nm$(_x_0)), ($ix$(_x_0)), 1, {$: "Nil"})), "tail": ($f_vars$(_xt_0))};
  }
}

function $f_flat$(_t_0, _vars_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Parallel")), run_clo((_x_0) => {
  return $f_flat_parallel$(_t_0, _vars_0);
}), run_clo((_x_1) => {
  return $f_flat_base$(_t_0, _vars_0);
}));
}

function $core_subst_stable_app_kids$(_kids_0) {
  if (_kids_0.$ === "Nil") {
    return false;
  } else {
    const _f_0 = _kids_0["head"];
    const _tail_0 = _kids_0["tail"];
    return $core_subst_stable_app_tail$(_f_0, _tail_0);
  }
}

function $Nat$show$go$($0, $1, $2) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _g_0 = $0;
      const _acc_0 = $1;
      const _dq_0 = $2;
      const _d_0 = _dq_0["fst"];
      const _t_0 = _dq_0["snd"];
      if (_t_0 === 0) {
        return (_d_0 + _acc_0);
      } else {
        const _p_0 = (_t_0 - 1);
        $0 = _g_0;
        $1 = nat_chk(_p_0 + 1);
        $2 = (_d_0 + _acc_0);
        $pc = 1; continue;
      }
    }
    case 1: {
      const _f_0 = $0;
      const _n_0 = $1;
      const _acc_0 = $2;
      if (_f_0 === 0) {
        return _acc_0;
      } else {
        const _g_0 = (_f_0 - 1);
        $0 = _g_0;
        $1 = _acc_0;
        $2 = ($Nat$show$put$(nat_divmod(_n_0, 10)));
        $pc = 0; continue;
      }
    }
  }
}

function $kp_array_join$(_a_0, _b_0) {
  if (_a_0.$ === "Some") {
    const _x_0 = _a_0["value"];
    if (_b_0.$ === "Some") {
      const _y_0 = _b_0["value"];
      return {$: "Some", "value": ($List$append$(_x_0, _y_0))};
    } else {
      return {$: "None"};
    }
  } else {
    return {$: "None"};
  }
}

function $kp_hex$(_n_0) {
  return $kc$((_n_0 < 16), run_clo((_x_0) => {
  return $kp_digit$(_n_0);
}), run_clo((_x_1) => {
  const _x_2 = run_loop($kp_hex$((16 === 0 ? 0 : (_n_0 / 16) >>> 0)));
  const _x_3 = ($kp_digit$((16 === 0 ? _n_0 : _n_0 % 16)));
  return (_x_2 + _x_3);
}));
}

function $g_filled$(_book_0, _id_0, _args_0, _pending_0, _fallback_0, _stack_0, _r_0) {
  return $g_eval$(_book_0, ($g_cache$(($g_state$(_r_0)), _id_0, ($g_term$(_r_0)))), ($g_term$(_r_0)), _args_0, _pending_0, _fallback_0, _stack_0);
}

function $g_share_head$(_st_0, _t_0) {
  const _x_0 = ($String$eq$(($tg$(_t_0)), "Ctr"));
  const _x_1 = ($String$eq$(($tg$(_t_0)), "ADT"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Mat"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($String$eq$(($tg$(_t_0)), "Eql"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($String$eq$(($tg$(_t_0)), "Min"));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($String$eq$(($tg$(_t_0)), "Typ"));
  return $kc$((_x_8 || _x_9), run_clo((_x_10) => {
  return $g_shared_head$(_t_0, ($g_share_terms$(_st_0, ($ks$(_t_0)), {$: "Nil"})));
}), run_clo((_x_11) => {
  return {$: "GResult", "state": _st_0, "term": _t_0};
}));
}

function $g_match$(_book_0, _st_0, _arm_0, _original_0, _raw_0, _x_0, _args_0, _pending_0, _fallback_0, _stack_0) {
  return $kc$(run_loop($core_nat$(_x_0)), run_clo((_x_1) => {
  return $g_match$(_book_0, _st_0, _arm_0, _original_0, _raw_0, run_loop($core_nat_step$(_x_0)), _args_0, _pending_0, _fallback_0, _stack_0);
}), run_clo((_x_2) => {
  return $kc$(($Bool$not$(($String$eq$(($tg$(_x_0)), "Ctr")))), run_clo((_x_3) => {
  return $g_return$(_book_0, _st_0, run_loop($norm_stuck$(_original_0, _raw_0, _args_0, _pending_0, _fallback_0)), _stack_0);
}), run_clo((_x_4) => {
  return $kc$(($String$eq$(($tg$(_arm_0)), "Ann")), run_clo((_x_5) => {
  return $g_match$(_book_0, _st_0, run_loop($kid$(_arm_0, 0)), _original_0, _raw_0, _x_0, _args_0, _pending_0, _fallback_0, _stack_0);
}), run_clo((_x_6) => {
  return $kc$(($String$eq$(($tg$(_arm_0)), "Mat")), run_clo((_x_7) => {
  return $kc$(($String$eq$(($nm$(_arm_0)), ($nm$(_x_0)))), run_clo((_x_8) => {
  return $g_eval$(_book_0, _st_0, run_loop($kid$(_arm_0, 0)), ($norm_join$(($ks$(_x_0)), _args_0)), run_loop($kc$((_pending_0 === 0), run_clo((_x_9) => {
  return 0;
}), run_clo((_x_10) => {
  const _x_11 = run_loop($norm_dec$(_pending_0));
  const _x_12 = ($terms_len$(($ks$(_x_0))));
  return ((_x_11 + _x_12) >>> 0);
}))), _fallback_0, _stack_0);
}), run_clo((_x_13) => {
  return $g_match$(_book_0, _st_0, run_loop($kid$(_arm_0, 1)), _original_0, _raw_0, _x_0, _args_0, _pending_0, _fallback_0, _stack_0);
}));
}), run_clo((_x_14) => {
  return $kc$(($String$eq$(($tg$(_arm_0)), "Efq")), run_clo((_x_15) => {
  return $g_return$(_book_0, _st_0, run_loop($norm_stuck$(_original_0, _raw_0, _args_0, _pending_0, _fallback_0)), _stack_0);
}), run_clo((_x_16) => {
  return $g_eval$(_book_0, _st_0, _arm_0, {$: "Con", "head": _x_0, "tail": _args_0}, _pending_0, _fallback_0, _stack_0);
}));
}));
}));
}));
}));
}

function $g_min_left$(_book_0, _st_0, _a_0, _b_0, _args_0, _stack_0) {
  const _x_0 = ($qt$(_a_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_a_0)), "Qua")), (_x_0 === 2))), run_clo((_x_1) => {
  return $g_eval$(_book_0, _st_0, _b_0, _args_0, 0, ($atom$("Absent")), _stack_0);
}), run_clo((_x_2) => {
  const _x_3 = ($qt$(_a_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_a_0)), "Qua")), (_x_3 === 0))), run_clo((_x_4) => {
  return $g_return$(_book_0, _st_0, ($norm_apply$(_a_0, _args_0)), _stack_0);
}), run_clo((_x_5) => {
  return $g_eval$(_book_0, _st_0, _b_0, {$: "Nil"}, 0, ($atom$("Absent")), {$: "Con", "head": {$: "GMinB", "other": _a_0, "args": _args_0}, "tail": _stack_0});
}));
}));
}

function $sp_len$(_s_0) {
  const _x_0 = [..._s_0].length;
  return (_x_0 >>> 0);
}

function $sp_template_inst$(_rest_0, _ctx_0, _owner_0, _depth_0, _r_0) {
  return $sp_apply_result$(($sp_value$(_r_0)), ($sp_args$(($sp_state$(_r_0)), _rest_0, _ctx_0, ($dt$(run_loop($lookup$(($sp_book$(($sp_state$(_r_0)))), ($nm$(($sp_value$(_r_0)))))))), _owner_0, _depth_0)));
}

function $sp_instance$(_st_0, _d_0, _xs_0, _owner_0, _depth_0, _key_0, _memo_0) {
  return $kc$(($Bool$not$(($String$eq$(($sp_mname$(_memo_0)), "")))), run_clo((_x_0) => {
  return $kc$(($Bool$and$(($sp_active$(_memo_0)), ($Bool$not$(($String$eq$(($sp_mname$(_memo_0)), _owner_0)))))), run_clo((_x_1) => {
  return {$: "KSpecTerm", "state": ($sp_fail$(_st_0, "nondecreasing cross-instance template recursion")), "term": ($ref$(($sp_mname$(_memo_0))))};
}), run_clo((_x_2) => {
  return {$: "KSpecTerm", "state": _st_0, "term": ($ref$(($sp_mname$(_memo_0))))};
}));
}), run_clo((_x_3) => {
  return $kc$((_depth_0 >= 64), run_clo((_x_4) => {
  return {$: "KSpecTerm", "state": ($sp_fail$(_st_0, "template instantiation exceeds 64 levels")), "term": ($ref$(($dn$(_d_0))))};
}), run_clo((_x_5) => {
  const _x_6 = ($U32$show$(($sp_serial$(_st_0))));
  const _x_7 = ($dn$(_d_0));
  const _x_8 = ("~" + _x_6);
  return $sp_mint$(_st_0, _d_0, _xs_0, ((_depth_0 + 1) >>> 0), _key_0, (_x_7 + _x_8));
}));
}));
}

function $sp_find$(_ms_0, _name_0, _key_0) {
  if (_ms_0.$ === "Nil") {
    return {$: "KSpecMemo", "template": "", "key": "", "name": "", "active": false};
  } else {
    const _h_0 = _ms_0["head"];
    const _rest_0 = _ms_0["tail"];
    return $kc$(($Bool$and$(($String$eq$(($sp_mtemplate$(_h_0)), _name_0)), ($String$eq$(($sp_mkey$(_h_0)), _key_0)))), run_clo((_x_0) => {
  return _h_0;
}), run_clo((_x_1) => {
  return $sp_find$(_rest_0, _name_0, _key_0);
}));
  }
}

function $term_key$(_t_0) {
  const _x_0 = ($sp_name_keys$(($rm$(_t_0))));
  const _x_1 = (_x_0 + "]");
  const _x_2 = ($sp_keys$(($ks$(_t_0))));
  const _x_3 = ("][" + _x_1);
  const _x_4 = (_x_2 + _x_3);
  const _x_5 = ($U32$show$(($qt$(_t_0))));
  const _x_6 = ("[" + _x_4);
  const _x_7 = (_x_5 + _x_6);
  const _x_8 = ($U32$show$(($ix$(_t_0))));
  const _x_9 = (":" + _x_7);
  const _x_10 = ($sp_key_string$(($nm$(_t_0))));
  const _x_11 = (_x_8 + _x_9);
  const _x_12 = ($sp_key_string$(($tg$(_t_0))));
  const _x_13 = (_x_10 + _x_11);
  return (_x_12 + _x_13);
}

function $template_arg_done$(_e_0, _ty_0, _h_0, _rest_0, _n_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $template_args$(_e_0, run_loop($subst$(run_loop($kid$(_ty_0, 1)), ($ix$(_ty_0)), _h_0)), _rest_0, ((_n_0 - 1) >>> 0));
}), run_clo((_x_1) => {
  return $bad$("template argument is open or ill-typed");
}));
}

function $descend_step$(_ord_0, _qs_0, _args_0, _cols_0) {
  return $kc$((_ord_0 === 0), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $kc$((_ord_0 === 1), run_clo((_x_2) => {
  return $descend_spine$(_qs_0, _args_0, _cols_0);
}), run_clo((_x_3) => {
  return false;
}));
}));
}

function $descend$(_q_0, _a_0, _p_0) {
  return $kc$((_q_0 === 0), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  return $descend_go$(run_loop($strip$(_a_0)), run_loop($strip$(_p_0)));
}));
}

function $terms_tail$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _ts_0["tail"];
    return _t_0;
  }
}

function $qjoin$(_a_0, _b_0) {
  return $kc$((_a_0 > _b_0), run_clo((_x_0) => {
  return _a_0;
}), run_clo((_x_1) => {
  return _b_0;
}));
}

function $uses_get$(_xs_0, _id_0) {
  if (_xs_0.$ === "Nil") {
    return 0;
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    const _x_0 = ($ix$(_h_0));
    return $kc$((_x_0 === _id_0), run_clo((_x_1) => {
  return $qt$(_h_0);
}), run_clo((_x_2) => {
  return $uses_get$(_t_0, _id_0);
}));
  }
}

function $uses_del$(_xs_0, _id_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _xs_0["head"];
    const _t_0 = _xs_0["tail"];
    const _x_0 = ($ix$(_h_0));
    return $kc$((_x_0 === _id_0), run_clo((_x_1) => {
  return $uses_del$(_t_0, _id_0);
}), run_clo((_x_2) => {
  return {$: "Con", "head": _h_0, "tail": run_loop($uses_del$(_t_0, _id_0))};
}));
  }
}

function $tele_check_cached_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0, _dem_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return $tele_check_after_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0, _dem_0, run_loop($check$(_e_0, _ctx_0, _h_0, run_loop($qdem$(($qt$(_tel_0)), _dem_0)), run_loop($kid$(_tel_0, 0)))));
}), run_clo((_x_1) => {
  return $bad$("too many telescope arguments");
}));
}

function $np_emit_join$(_index_0, _last_0, _word_0, _code_0, _tail_0) {
  const _x_0 = ($nc_body$(_tail_0));
  const _x_1 = ($nc_body$(_code_0));
  const _x_2 = ("} else " + _x_0);
  const _x_3 = (_x_1 + _x_2);
  const _x_4 = ($U32$show$(_index_0));
  const _x_5 = ("ull) {\n" + _x_3);
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = (" == " + _x_6);
  const _x_8 = (_word_0 + _x_7);
  return {$: "NC_Code", "body": ("if (" + _x_8), "segments": ($nt_append$(($nc_segs$(_code_0)), ($nc_segs$(_tail_0)))), "fresh": ($nc_fresh$(_tail_0)), "error": run_loop($nc_first_error$(_code_0, _tail_0))};
}

function $f_alias_terms$(_ts_0, _imports_0, _scope_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": run_loop($f_alias_term$(_t_0, _imports_0, _scope_0)), "tail": ($f_alias_terms$(_rest_0, _imports_0, _scope_0))};
  }
}

function $f_prefix$(_s_0, _prefix_0) {
  return $f_choose$(($String$is_empty$(_prefix_0)), run_clo((_x_0) => {
  return true;
}), run_clo((_x_1) => {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_2) => {
  return false;
}), run_clo((_x_3) => {
  return $Bool$and$(($Char$is_eq$(($f_head$(_s_0)), ($f_head$(_prefix_0)))), run_loop($f_prefix$(($f_tail$(_s_0)), ($f_tail$(_prefix_0)))));
}));
}));
}

function $f_drop_prefix$(_s_0, _prefix_0) {
  return $f_choose$(($String$is_empty$(_prefix_0)), run_clo((_x_0) => {
  return _s_0;
}), run_clo((_x_1) => {
  return $f_drop_prefix$(($f_tail$(_s_0)), ($f_tail$(_prefix_0)));
}));
}

function $f_path_parent$(_parts_0) {
  if (_parts_0.$ === "Nil") {
    return {$: "Con", "head": "..", "tail": {$: "Nil"}};
  } else {
    const _p_0 = _parts_0["head"];
    const _rest_0 = _parts_0["tail"];
    return $f_choose$(($f_eq$(_p_0, "..")), run_clo((_x_0) => {
  return {$: "Con", "head": "..", "tail": {$: "Con", "head": _p_0, "tail": _rest_0}};
}), run_clo((_x_1) => {
  return _rest_0;
}));
  }
}

function $check_ctor_head$(_e_0, _d_0, _tel_0, _kind_0, _params_0, _fields_0, _ctx_0, _args_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  const _x_1 = ($qt$(_tel_0));
  return $check_ctor_domain$(_e_0, _d_0, _tel_0, _kind_0, _params_0, _fields_0, _ctx_0, _args_0, run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_tel_0, 0)), 0, run_loop($kc$(($Bool$and$((_params_0 === 0), (_x_1 === 1))), run_clo((_x_2) => {
  return _kind_0;
}), run_clo((_x_3) => {
  return $typ$(($qt$(_tel_0)));
}))))));
}), run_clo((_x_4) => {
  return "constructor telescope missing a binder";
}));
}

function $check_lam_done$(_t_0, _ty_0, _q_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  const _x_1 = run_loop($uses_get$(($cs$(_r_0)), ($ix$(_t_0))));
  return $kc$((_x_1 > _q_0), run_clo((_x_2) => {
  return $dg_quant_error$("affine variable consumed more than allowed", ($nm$(_t_0)), _q_0, run_loop($uses_get$(($cs$(_r_0)), ($ix$(_t_0)))));
}), run_clo((_x_3) => {
  return $ok$(_t_0, _ty_0, run_loop($uses_del$(($cs$(_r_0)), ($ix$(_t_0)))));
}));
}), run_clo((_x_4) => {
  return _r_0;
}));
}

function $lhs_step$(_e_0, _x_0) {
  const _x_1 = ($cp$(_e_0));
  return $kc$((_x_1 === 0), run_clo((_x_2) => {
  return _e_0;
}), run_clo((_x_3) => {
  const _x_4 = ($cp$(_e_0));
  return {$: "KEnv", "book": ($cb$(_e_0)), "name": ($cn$(_e_0)), "lhs": run_loop($kapply$(($cl$(_e_0)), _x_0)), "pending": ((_x_4 - 1) >>> 0), "quantities": ($cq$(_e_0)), "unsafe": ($cu$(_e_0))};
}));
}

function $dg_ctor_error$(_e_0, _t_0, _ty_0, _ctr_0) {
  return $kc$(($Bool$and$(($Bool$not$(($String$eq$(($dk$(_ctr_0)), "Absent")))), ($Bool$not$(run_loop($has_name$(($rm$(_ty_0)), ($nm$(_t_0)))))))), run_clo((_x_0) => {
  const _x_1 = ($da$(_ctr_0));
  const _x_4 = ($U32$show$(($da$(_ctr_0))));
  const _x_5 = run_loop($kc$((_x_1 === 1), run_clo((_x_2) => {
  return " field";
}), run_clo((_x_3) => {
  return " fields";
})));
  const _x_6 = (_x_4 + _x_5);
  const _x_7 = ($nm$(_t_0));
  const _x_8 = (" with " + _x_6);
  return $dg_bad_detail$("constructor does not belong to goal or field count differs", ($dg_text$((_x_7 + _x_8))), _t_0);
}), run_clo((_x_9) => {
  return $kc$(($String$eq$(run_loop($dg_family$(($cb$(_e_0)), ($nm$(_t_0)))), "")), run_clo((_x_10) => {
  const _x_11 = ($dg_constructor_names$(($dc$(run_loop($lookup$(($cb$(_e_0)), ($nm$(_ty_0))))))));
  const _x_12 = (_x_11 + ")");
  const _x_13 = ($nm$(_ty_0));
  const _x_14 = (" declares " + _x_12);
  const _x_15 = (_x_13 + _x_14);
  return $dg_bad_detail$("constructor does not belong to goal or field count differs", ($dg_text$(("a declared constructor (" + _x_15))), _t_0);
}), run_clo((_x_16) => {
  return $dg_bad_detail$("constructor does not belong to goal or field count differs", _ty_0, ($ref$(run_loop($dg_family$(($cb$(_e_0)), ($nm$(_t_0)))))));
}));
}));
}

function $dead_type$(_book_0, _ty_0) {
  return $Bool$and$(($Bool$and$(($String$eq$(($tg$(_ty_0)), "ADT")), ($String$eq$(($dk$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), "ADT")))), ($defs_empty$(run_loop($remaining$(($dc$(run_loop($lookup$(_book_0, ($nm$(_ty_0)))))), ($rm$(_ty_0)))))));
}

function $ctx_dead$(_book_0, _ctx_0) {
  if (_ctx_0.$ === "Nil") {
    return false;
  } else {
    const _h_0 = _ctx_0["head"];
    const _t_0 = _ctx_0["tail"];
    const _x_0 = ($qt$(_h_0));
    return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return $ctx_dead$(_book_0, _t_0);
}), run_clo((_x_2) => {
  const _x_3 = ($dead_type$(_book_0, run_loop($wnf$(_book_0, run_loop($kid$(_h_0, 0))))));
  const _x_4 = run_loop($ctx_dead$(_book_0, _t_0));
  return (_x_3 || _x_4);
}));
  }
}

function $dg_constructor_names$(_ds_0) {
  if (_ds_0.$ === "Nil") {
    return "";
  } else {
    const _d_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    const _x_3 = ($dn$(_d_0));
    const _x_4 = run_loop($kc$(($defs_empty$(_rest_0)), run_clo((_x_0) => {
  return "";
}), run_clo((_x_1) => {
  const _x_2 = ($dg_constructor_names$(_rest_0));
  return (", " + _x_2);
})));
    return (_x_3 + _x_4);
  }
}

function $check_mat_ctr$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _a_0, _ctr_0) {
  return $kc$(($String$eq$(($dk$(_ctr_0)), "Absent")), run_clo((_x_0) => {
  const _x_1 = ($nm$(_a_0));
  const _x_2 = (_x_1 + " (missing, or already matched)");
  return $dg_bad_detail$("unknown or duplicate match constructor", ($dg_text$(("a constructor of " + _x_2))), _t_0);
}), run_clo((_x_3) => {
  return $both$(run_loop($check$(run_loop($mat_lhs$(_e_0, ($nm$(_t_0)), run_loop($tele_fill$(($cb$(_e_0)), ($dt$(_ctr_0)), ($ks$(_a_0)))), ($da$(_ctr_0)), {$: "Con", "head": _t_0, "tail": {$: "Con", "head": _ty_0, "tail": _ctx_0}})), _ctx_0, run_loop($kid$(_t_0, 0)), _dem_0, run_loop($mat_goal$(($cb$(_e_0)), _ty_0, run_loop($tele_fill$(($cb$(_e_0)), ($dt$(_ctr_0)), ($ks$(_a_0)))), ($da$(_ctr_0)), ($nm$(_t_0)), {$: "Nil"})))), run_loop($check$(_e_0, _ctx_0, run_loop($mat_rest$(($cb$(_e_0)), _t_0, _a_0)), _dem_0, ($all$(($qt$(_ty_0)), ($nm$(_ty_0)), ($ix$(_ty_0)), {$: "KTerm", "tag": ($tg$(_a_0)), "name": ($nm$(_a_0)), "id": ($ix$(_a_0)), "quant": ($qt$(_a_0)), "kids": ($ks$(_a_0)), "removed": {$: "Con", "head": ($nm$(_t_0)), "tail": ($rm$(_a_0))}}, run_loop($kid$(_ty_0, 1)))))), _t_0, _ty_0, true);
}));
}

function $check_let_kind$(_e_0, _outer_0, _ctx_0, _h_0, _rest_0, _dem_0, _ty_0, _bindings_0, _us_0, _r_0, _k_0) {
  return $kc$(($good$(_k_0)), run_clo((_x_0) => {
  return $check_let$(_e_0, _outer_0, ($ctx_bind$(_ctx_0, ($ix$(_h_0)), ($qt$(_h_0)), ($nm$(_h_0)), ($cy$(_r_0)))), _rest_0, _dem_0, _ty_0, {$: "Con", "head": _h_0, "tail": _bindings_0}, ($uses_merge$(_us_0, ($cs$(_r_0)), false)));
}), run_clo((_x_1) => {
  return _k_0;
}));
}

function $dg_quant_error$(_message_0, _name_0, _allowed_0, _used_0) {
  const _x_0 = run_loop($kp_quant$(_allowed_0));
  return $dg_bad_detail$(_message_0, ($dg_text$((_x_0 + _name_0))), ($dg_text$(run_loop($kc$((_used_0 === 2), run_clo((_x_1) => {
  return (_name_0 + " (consumed more than once)");
}), run_clo((_x_2) => {
  const _x_3 = run_loop($kp_quant$(_used_0));
  return (_x_3 + _name_0);
}))))));
}

function $check_rwt_goal$(_e_0, _ctx_0, _t_0, _dem_0, _ty_0, _r_0, _eq_0, _fresh_0) {
  return $kc$(run_loop($compare$(($cb$(_e_0)), run_loop($kapply$(run_loop($kapply$(run_loop($kid$(_t_0, 1)), run_loop($kid$(_eq_0, 1)))), run_loop($kid$(_t_0, 0)))), _ty_0, true)), run_clo((_x_0) => {
  return $both$(_r_0, run_loop($both$(run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 1)), 0, ($all$(1, "_", _fresh_0, run_loop($kid$(_eq_0, 2)), ($all$(1, "e", ((_fresh_0 + 1) >>> 0), ($kt$("Eql", "", 0, 0, {$: "Con", "head": run_loop($kid$(_eq_0, 0)), "tail": {$: "Con", "head": ($var$("_", _fresh_0)), "tail": {$: "Con", "head": run_loop($kid$(_eq_0, 2)), "tail": {$: "Nil"}}}})), ($typ$(1)))))))), run_loop($check$(_e_0, _ctx_0, run_loop($kid$(_t_0, 2)), _dem_0, run_loop($kapply$(run_loop($kapply$(run_loop($kid$(_t_0, 1)), run_loop($kid$(_eq_0, 0)))), ($atom$("Rfl")))))), _t_0, _ty_0, false)), _t_0, _ty_0, false);
}), run_clo((_x_1) => {
  return $dg_bad_detail$("rewrite motive does not fit goal", _ty_0, run_loop($kapply$(run_loop($kapply$(run_loop($kid$(_t_0, 1)), run_loop($kid$(_eq_0, 1)))), run_loop($kid$(_t_0, 0)))));
}));
}

function $norm_subset$(_as_0, _bs_0) {
  if (_bs_0.$ === "Nil") {
    return true;
  } else {
    const _h_0 = _bs_0["head"];
    const _t_0 = _bs_0["tail"];
    return $Bool$and$(run_loop($has_name$(_as_0, _h_0)), ($norm_subset$(_as_0, _t_0)));
  }
}

function $norm_names_len$(_names_0) {
  if (_names_0.$ === "Nil") {
    return 0;
  } else {
    const _rest_0 = _names_0["tail"];
    const _x_0 = ($norm_names_len$(_rest_0));
    return ((1 + _x_0) >>> 0);
  }
}

function $norm_cmp_zip$(_as_0, _bs_0, _fresh_0, _rest_0) {
  if (_as_0.$ === "Con") {
    const _a_0 = _as_0["head"];
    const _ar_0 = _as_0["tail"];
    if (_bs_0.$ === "Con") {
      const _b_0 = _bs_0["head"];
      const _br_0 = _bs_0["tail"];
      return {$: "Con", "head": {$: "KNormCmp", "a": _a_0, "b": _b_0, "le": false, "fresh": _fresh_0}, "tail": ($norm_cmp_zip$(_ar_0, _br_0, _fresh_0, _rest_0))};
    } else {
      return _rest_0;
    }
  } else {
    return _rest_0;
  }
}

function $norm_cmp_ref$(_book_0, _a_0, _b_0, _le_0, _n_0, _fresh_0, _rest_0, _alts_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return $norm_cmp_fail$(_book_0, _alts_0);
}), run_clo((_x_1) => {
  return $kc$((_n_0 === 1), run_clo((_x_2) => {
  return $norm_cmp_loop$(_book_0, {$: "Con", "head": {$: "KNormCmp", "a": ($app$(_a_0, ($var$("_", _fresh_0)))), "b": ($app$(_b_0, ($var$("_", _fresh_0)))), "le": _le_0, "fresh": ((_fresh_0 + 1) >>> 0)}, "tail": _rest_0}, _alts_0);
}), run_clo((_x_3) => {
  return $norm_cmp_ref$(_book_0, ($app$(_a_0, ($var$("_", _fresh_0)))), ($app$(_b_0, ($var$("_", _fresh_0)))), _le_0, ((_n_0 - 1) >>> 0), ((_fresh_0 + 1) >>> 0), _rest_0, _alts_0);
}));
}));
}

function $fp_token_origin$(_t_0, _definition_0, _text_0, _token_0, _route_0) {
  const _word_0 = _token_0["text"];
  const _line_0 = _token_0["f_line"];
  const _column_0 = _token_0["f_col"];
  const _begin_0 = run_loop($fp_offset$(_text_0, 1, 0, _line_0, _column_0, 0));
  const _x_0 = run_loop($fp_utf16$(_word_0));
  return {$: "Con", "head": {$: "DOrigin", "definition": _definition_0, "term": _t_0, "source": _text_0, "begin": _begin_0, "end": ((_begin_0 + _x_0) >>> 0), "path": _route_0}, "tail": {$: "Nil"}};
}

function $f_arg_next$(_p_0, _end_0, _acc_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_args$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), ",")), run_clo((_x_2) => {
  return $f_tl$(_ts_0);
}), run_clo((_x_3) => {
  return _ts_0;
}))), _end_0, {$: "Con", "head": _n_0, "tail": _acc_0});
}));
}

function $f_lambda_valid$(_a_0, _body_0) {
  return $f_choose$(($Bool$and$(($f_eq$(($tg$(_a_0)), "Ref")), ($f_valid_name$(($nm$(_a_0)))))), run_clo((_x_0) => {
  return $kt$("Lam", ($nm$(_a_0)), ($ix$(_a_0)), ($qt$(_a_0)), {$: "Con", "head": _body_0, "tail": {$: "Nil"}});
}), run_clo((_x_1) => {
  return $kt$("Error", "a lambda binder must be a non-reserved name", 0, 0, {$: "Nil"});
}));
}

function $f_operator$(_s_0) {
  return $f_choose$(($f_eq$(_s_0, "&")), run_clo((_x_0) => {
  return "Pair";
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(_s_0, "|")), run_clo((_x_2) => {
  return "Or";
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(_s_0, "++")), run_clo((_x_4) => {
  return "String.append";
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(_s_0, "||")), run_clo((_x_6) => {
  return "Bool.or";
}), run_clo((_x_7) => {
  return $f_choose$(($f_eq$(_s_0, "&&")), run_clo((_x_8) => {
  return "Bool.and";
}), run_clo((_x_9) => {
  return $f_choose$(($f_eq$(_s_0, "+")), run_clo((_x_10) => {
  return ".add";
}), run_clo((_x_11) => {
  return $f_choose$(($f_eq$(_s_0, "-")), run_clo((_x_12) => {
  return ".sub";
}), run_clo((_x_13) => {
  return $f_choose$(($f_eq$(_s_0, "*")), run_clo((_x_14) => {
  return ".mul";
}), run_clo((_x_15) => {
  return $f_choose$(($f_eq$(_s_0, "/")), run_clo((_x_16) => {
  return ".div";
}), run_clo((_x_17) => {
  return $f_choose$(($f_eq$(_s_0, "%")), run_clo((_x_18) => {
  return ".mod";
}), run_clo((_x_19) => {
  return $f_choose$(($f_eq$(_s_0, "<")), run_clo((_x_20) => {
  return ".is_lt";
}), run_clo((_x_21) => {
  return $f_choose$(($f_eq$(_s_0, ">op")), run_clo((_x_22) => {
  return ".is_gt";
}), run_clo((_x_23) => {
  return $f_choose$(($f_eq$(_s_0, "<=")), run_clo((_x_24) => {
  return ".is_le";
}), run_clo((_x_25) => {
  return $f_choose$(($f_eq$(_s_0, ">=")), run_clo((_x_26) => {
  return ".is_ge";
}), run_clo((_x_27) => {
  return $f_choose$(($f_eq$(_s_0, "<<")), run_clo((_x_28) => {
  return ".shln";
}), run_clo((_x_29) => {
  return $f_choose$(($f_eq$(_s_0, ">>op")), run_clo((_x_30) => {
  return ".shrn";
}), run_clo((_x_31) => {
  return $f_choose$(($f_eq$(_s_0, ".&.")), run_clo((_x_32) => {
  return ".and";
}), run_clo((_x_33) => {
  return $f_choose$(($f_eq$(_s_0, ".|.")), run_clo((_x_34) => {
  return ".or";
}), run_clo((_x_35) => {
  return $f_choose$(($f_eq$(_s_0, ".^.")), run_clo((_x_36) => {
  return ".xor";
}), run_clo((_x_37) => {
  return _s_0;
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}));
}

function $f_do_types$(_monad_0, _p_0) {
  const _types_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_types_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _types_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_do_types_at$(_monad_0, _types_0, run_loop($f_space$(_ts_0)));
}));
}

function $f_do_parameters_open$(_monad_0, _ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ";")), run_clo((_x_0) => {
  return $fpe_error$(_ts_0, "expected term", "a term");
}), run_clo((_x_1) => {
  const _x_2 = ($f_eq$(($f_tx$(_ts_0)), ">"));
  const _x_3 = ($f_eq$(($f_tx$(_ts_0)), ">op"));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $f_do_types$(_monad_0, {$: "FParsed", "term": ($kt$("Args", "", 0, 1, {$: "Nil"})), "rest": ($f_tl$(_ts_0))});
}), run_clo((_x_5) => {
  return $f_do_types$(_monad_0, run_loop($f_args$(_ts_0, ">", {$: "Nil"})));
}));
}));
}

function $f_rewrite_motive$(_name_0, _id_0, _e_0, _p_0) {
  const _motive_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_rewrite_body$(_e_0, ($kt$("Lam", "_", ((_id_0 + 2147483648) >>> 0), 4, {$: "Con", "head": ($kt$("Lam", _name_0, _id_0, 1, {$: "Con", "head": _motive_0, "tail": {$: "Nil"}})), "tail": {$: "Nil"}})), run_loop($f_body$(_ts_0)));
}

function $f_error_term$(_t_0) {
  return $nm$(run_loop($fpe_term$(_t_0)));
}

function $f_body_context_at$(_ts_0, _outer_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "match")), run_clo((_x_0) => {
  return $f_match_heads$(($f_tl$(_ts_0)), _outer_0, {$: "Nil"});
}), run_clo((_x_1) => {
  return $f_body_at$(_ts_0);
}));
}

function $f_equation$(_a_0, _neg_0, _p_0) {
  const _b_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_equation_type$(_a_0, _b_0, _neg_0, run_loop($f_expect$(run_loop($f_expr$(_ts_0, 0)), "}")));
}

function $f_group_ann$(_n_0, _p_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Ann", "", 0, 1, {$: "Con", "head": _n_0, "tail": {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}})), "rest": _ts_0};
}

function $f_array_type$(_n_0, _p_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  const _rest_0 = run_loop($f_space$(_ts_0));
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _ty_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  const _x_2 = ($f_eq$(($f_tx$(_rest_0)), "*"));
  const _x_3 = ($f_eq$(($f_tx$(_rest_0)), "^"));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $f_array_size$(_n_0, _ty_0, ($f_eq$(($f_tx$(_rest_0)), "*")), run_loop($f_expr$(($f_tl$(_rest_0)), 0)));
}), run_clo((_x_5) => {
  return $fpe_error$(_rest_0, "expected * or ^ after array element type", "'^'");
}));
}));
}

function $f_list$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": run_loop($f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return _n_0;
}), run_clo((_x_1) => {
  return $f_list_nodes$(($ks$(_n_0)));
}))), "rest": _ts_0};
}

function $f_all_body$(_name_0, _id_0, _q_0, _exi_0, _a_0, _p_0) {
  const _b_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": run_loop($f_choose$(_exi_0, run_clo((_x_0) => {
  return $f_app$(($kt$("Ref", "Exists", 0, 1, {$: "Nil"})), {$: "Con", "head": _a_0, "tail": {$: "Con", "head": ($kt$("Lam", _name_0, _id_0, _q_0, {$: "Con", "head": _b_0, "tail": {$: "Nil"}})), "tail": {$: "Nil"}}});
}), run_clo((_x_1) => {
  return $kt$("All", _name_0, _id_0, _q_0, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}))), "rest": _ts_0};
}

function $f_matcher_arm$(_name_0, _p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_matcher_tail$(_name_0, _n_0, run_loop($f_matcher$(run_loop($f_skip$(_ts_0)))));
}

function $f_atom_nat_plus$(_lit_0, _p_0) {
  const _rhs_0 = _p_0["term"];
  const _rest_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_rhs_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _rhs_0, "rest": _rest_0};
}), run_clo((_x_1) => {
  return {$: "FParsed", "term": run_loop($f_nat_extend$(_lit_0, _rhs_0)), "rest": _rest_0};
}));
}

function $f_string$(_s_0) {
  return $f_choose$(($Char$is_eq$(($f_head$(_s_0)), "\"")), run_clo((_x_0) => {
  return $kt$("Ctr", "SNil", 0, 1, {$: "Nil"});
}), run_clo((_x_1) => {
  return $f_string_decoded$(run_loop($f_decode_char$(_s_0)));
}));
}

function $f_char_literal$(_s_0) {
  return $f_char_decoded$(run_loop($f_decode_char$(_s_0)));
}

function $f_contains$(_s_0, _c_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return false;
}), run_clo((_x_1) => {
  const _x_2 = ($Char$is_eq$(($f_head$(_s_0)), _c_0));
  const _x_3 = run_loop($f_contains$(($f_tail$(_s_0)), _c_0));
  return (_x_2 || _x_3);
}));
}

function $f_float$(_s_0) {
  return $f_float_read$(f32_read(_s_0));
}

function $f_number$(_s_0, _acc_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return $f_u32$(_acc_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(_s_0, "n")), run_clo((_x_2) => {
  return $f_nat$(_acc_0);
}), run_clo((_x_3) => {
  const _x_4 = ($Char$to_u32$(($f_head$(_s_0))));
  const _x_5 = (_acc_0 < 429496729);
  const _x_6 = ($Bool$and$((_acc_0 === 429496729), (_x_4 <= 53)));
  return $f_choose$(($Bool$and$(($Char$is_digit$(($f_head$(_s_0)))), (_x_5 || _x_6))), run_clo((_x_7) => {
  const _x_8 = ($Char$to_u32$(($f_head$(_s_0))));
  const _x_9 = (Math.imul(_acc_0, 10) >>> 0);
  const _x_10 = ((_x_8 - 48) >>> 0);
  return $f_number$(($f_tail$(_s_0)), ((_x_9 + _x_10) >>> 0));
}), run_clo((_x_11) => {
  return $kt$("Error", "invalid or unsupported numeric literal", 0, 0, {$: "Nil"});
}));
}));
}));
}

function $f_unquote_chars$(_s_0) {
  const _x_0 = ($String$is_empty$(_s_0));
  const _x_1 = ($Char$is_eq$(($f_head$(_s_0)), "\""));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return "";
}), run_clo((_x_3) => {
  return $f_choose$(($Char$is_eq$(($f_head$(_s_0)), "\\")), run_clo((_x_4) => {
  return (char_new(run_loop($f_escape_code$(($f_head$(($f_tail$(_s_0))))))) + run_loop($f_unquote_chars$(($f_tail$(($f_tail$(_s_0)))))));
}), run_clo((_x_5) => {
  return (($f_head$(_s_0)) + run_loop($f_unquote_chars$(($f_tail$(_s_0)))));
}));
}));
}

function $fc_term$(_t_0, _env_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Ref")), run_clo((_x_0) => {
  return $fc_ref$(($nm$(_t_0)), _env_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "ADT")), run_clo((_x_2) => {
  const _x_3 = run_loop($fc_ref$(($nm$(_t_0)), _env_0));
  const _x_4 = ($fc_terms$(($ks$(_t_0)), _env_0));
  return ((_x_3 + _x_4) >>> 0);
}), run_clo((_x_5) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "All")), run_clo((_x_6) => {
  const _x_7 = run_loop($fc_term$(run_loop($kid$(_t_0, 0)), _env_0));
  const _x_8 = run_loop($fc_term$(run_loop($kid$(_t_0, 1)), run_loop($fc_bind$(_t_0, _env_0))));
  const _x_9 = ((_x_7 + _x_8) >>> 0);
  return ((1 + _x_9) >>> 0);
}), run_clo((_x_10) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Lam")), run_clo((_x_11) => {
  const _x_12 = run_loop($fc_ref$(($nm$(_t_0)), _env_0));
  const _x_13 = run_loop($fc_term$(run_loop($kid$(_t_0, 0)), run_loop($fc_bind$(_t_0, _env_0))));
  const _x_14 = ((_x_12 + _x_13) >>> 0);
  return ((1 + _x_14) >>> 0);
}), run_clo((_x_15) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Match")), run_clo((_x_16) => {
  const _x_17 = ($fc_terms$(($ks$(run_loop($kid$(_t_0, 0)))), _env_0));
  const _x_18 = ($fc_rows$(($f_tail_terms$(($ks$(_t_0)))), _env_0));
  return ((_x_17 + _x_18) >>> 0);
}), run_clo((_x_19) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Local")), run_clo((_x_20) => {
  const _x_21 = ($qt$(run_loop($kid$(_t_0, 0))));
  const _x_24 = ($fc_bind_count$({$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}}));
  const _x_25 = run_loop($fc_term$(run_loop($kid$(_t_0, 2)), ($norm_join$(run_loop($fc_binders$({$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}})), _env_0))));
  const _x_26 = run_loop($fc_term$(run_loop($kid$(_t_0, 1)), _env_0));
  const _x_27 = ((_x_24 + _x_25) >>> 0);
  const _x_28 = run_loop($f_choose$((_x_21 === 0), run_clo((_x_22) => {
  return 0;
}), run_clo((_x_23) => {
  return $fc_term$(run_loop($kid$(_t_0, 0)), _env_0);
})));
  const _x_29 = ((_x_26 + _x_27) >>> 0);
  return ((_x_28 + _x_29) >>> 0);
}), run_clo((_x_30) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Parallel")), run_clo((_x_31) => {
  const _x_32 = ($fc_bind_count$(($ks$(run_loop($kid$(_t_0, 0))))));
  const _x_33 = run_loop($fc_term$(run_loop($kid$(_t_0, 2)), ($norm_join$(run_loop($fc_binders$(($ks$(run_loop($kid$(_t_0, 0)))))), _env_0))));
  const _x_34 = ($fc_terms$(($ks$(run_loop($kid$(_t_0, 1)))), _env_0));
  const _x_35 = ((_x_32 + _x_33) >>> 0);
  const _x_36 = ($fc_terms$(($ks$(run_loop($kid$(_t_0, 0)))), _env_0));
  const _x_37 = ((_x_34 + _x_35) >>> 0);
  return ((_x_36 + _x_37) >>> 0);
}), run_clo((_x_38) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Mat")), run_clo((_x_39) => {
  const _x_40 = run_loop($fc_ref$(($nm$(_t_0)), _env_0));
  const _x_41 = ($fc_terms$(($ks$(_t_0)), _env_0));
  return ((_x_40 + _x_41) >>> 0);
}), run_clo((_x_42) => {
  return $fc_terms$(($ks$(_t_0)), _env_0);
}));
}));
}));
}));
}));
}));
}));
}));
}

function $ffw_reverse_onto$($0, $1) {
  for (;;) {
    {
      const _items_0 = $0;
      const _onto_0 = $1;
      if (_items_0.$ === "Nil") {
        return _onto_0;
      } else {
        const _head_0 = _items_0["head"];
        const _tail_0 = _items_0["tail"];
        $0 = _tail_0;
        $1 = {$: "Con", "head": _head_0, "tail": _onto_0};
        continue;
      }
    }
  }
}

function $f_init$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    const _x_1 = ($terms_len$(_xt_0));
    return $f_choose$((_x_1 === 0), run_clo((_x_2) => {
  return {$: "Nil"};
}), run_clo((_x_3) => {
  return {$: "Con", "head": _x_0, "tail": run_loop($f_init$(_xt_0))};
}));
  }
}

function $f_last$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    const _x_1 = ($terms_len$(_xt_0));
    return $f_choose$((_x_1 === 0), run_clo((_x_2) => {
  return _x_0;
}), run_clo((_x_3) => {
  return $f_last$(_xt_0);
}));
  }
}

function $f_quants$(_n_0, _q_0) {
  return $f_choose$((_n_0 === 0), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return {$: "Con", "head": ($qua$(_q_0)), "tail": run_loop($f_quants$(((_n_0 - 1) >>> 0), _q_0))};
}));
}

function $f_drop_terms$(_ts_0, _n_0) {
  return $f_choose$((_n_0 === 0), run_clo((_x_0) => {
  return _ts_0;
}), run_clo((_x_1) => {
  return $f_drop_terms$(($f_tail_terms$(_ts_0)), ((_n_0 - 1) >>> 0));
}));
}

function $f_subs$(_ts_0, _id_0, _v_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": run_loop($f_sub$(_t_0, _id_0, _v_0)), "tail": ($f_subs$(_rest_0, _id_0, _v_0))};
  }
}

function $f_scope_reference$(_t_0, _bound_0, _book_0) {
  const _x_0 = ($qt$(_t_0));
  return $f_choose$((_x_0 === 2), run_clo((_x_1) => {
  return $f_scope_marked$(_t_0, _bound_0, run_loop($f_find$(($nm$(_t_0)), _book_0)), false);
}), run_clo((_x_2) => {
  const _x_3 = ($qt$(_t_0));
  const _x_4 = ($Bool$not$(($f_eq$(($tg$(_bound_0)), "Absent"))));
  const _x_5 = ($f_eq$(($dk$(run_loop($f_find$(($nm$(_t_0)), _book_0)))), "ADT"));
  return $f_choose$(($Bool$and$((_x_3 === 3), (_x_4 || _x_5))), run_clo((_x_6) => {
  return $kt$("Error", "offload requires a named definition", 0, 0, {$: "Nil"});
}), run_clo((_x_7) => {
  return $f_choose$(($Bool$not$(($f_eq$(($tg$(_bound_0)), "Absent")))), run_clo((_x_8) => {
  return $kt$("Var", ($nm$(_bound_0)), ($ix$(_bound_0)), ($qt$(_bound_0)), {$: "Nil"});
}), run_clo((_x_9) => {
  return $f_choose$(($f_eq$(($dk$(run_loop($f_find$(($nm$(_t_0)), _book_0)))), "ADT")), run_clo((_x_10) => {
  return $f_adt$(_t_0, {$: "Nil"}, run_loop($f_find$(($nm$(_t_0)), _book_0)));
}), run_clo((_x_11) => {
  return $f_choose$(($Bool$and$(($Char$is_eq$(($f_head$(($nm$(_t_0)))), ".")), ($Bool$not$(($Char$is_eq$(($f_head$(($f_tail$(($nm$(_t_0)))))), ".")))))), run_clo((_x_12) => {
  const _x_13 = run_loop($f_operator_display$(($nm$(_t_0)), {$: "Con", "head": "+", "tail": {$: "Con", "head": "-", "tail": {$: "Con", "head": "*", "tail": {$: "Con", "head": "/", "tail": {$: "Con", "head": "%", "tail": {$: "Con", "head": "<", "tail": {$: "Con", "head": ">op", "tail": {$: "Con", "head": "<=", "tail": {$: "Con", "head": ">=", "tail": {$: "Con", "head": "<<", "tail": {$: "Con", "head": ">>op", "tail": {$: "Con", "head": ".&.", "tail": {$: "Con", "head": ".|.", "tail": {$: "Con", "head": ".^.", "tail": {$: "Nil"}}}}}}}}}}}}}}}));
  const _x_14 = (_x_13 + " b : Nat))");
  return $kt$("Error", ("a type for this operator (write (a " + _x_14), ($ix$(_t_0)), 0, {$: "Nil"});
}), run_clo((_x_15) => {
  return _t_0;
}));
}));
}));
}));
}));
}

function $f_scope_lambda_var$(_t_0, _env_0, _book_0, _v_0) {
  return $f_flat$(run_loop($f_scope_body$(run_loop($kid$(_t_0, 0)), {$: "Con", "head": _v_0, "tail": _env_0}, _book_0)), {$: "Con", "head": ($kt$("Var", ($nm$(_v_0)), ($ix$(_v_0)), ($qt$(_v_0)), {$: "Nil"})), "tail": {$: "Nil"}});
}

function $ff_match$(_heads_0, _rows_0, _vars_0, _next_0) {
  if (_heads_0.$ === "Nil") {
    const _x_0 = ($terms_len$(_rows_0));
    return $f_choose$((_x_0 === 0), run_clo((_x_1) => {
  return {$: "FFlatten", "term": ($atom$("Efq")), "next": _next_0};
}), run_clo((_x_2) => {
  return $ff_flat$(run_loop($kid$(run_loop($terms_at$(_rows_0, 0)), 1)), _vars_0, _next_0);
}));
  } else {
    const _h_0 = _heads_0["head"];
    const _hs_0 = _heads_0["tail"];
    const _x_3 = ($terms_len$(_rows_0));
    return $f_choose$(($Bool$and$(($Bool$and$(($f_eq$(($tg$(run_loop($f_first_ctor$(_rows_0)))), "Absent")), (_x_3 > 0))), ($f_has_id$(_vars_0, ($ix$(_h_0)))))), run_clo((_x_4) => {
  return $ff_match$(_hs_0, ($f_var_rows$(_rows_0, _h_0)), ($f_mark_vars$(_vars_0, ($ix$(_h_0)), ($f_mark_rows$(_rows_0, ($qt$(_h_0)))))), _next_0);
}), run_clo((_x_5) => {
  return $ff_column$(_h_0, _hs_0, _rows_0, _vars_0, _next_0);
}));
  }
}

function $ff_local$(_t_0, _vars_0, _next_0) {
  return $f_choose$(($f_eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Ctr")), run_clo((_x_0) => {
  return $ff_match$({$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Nil"}}, {$: "Con", "head": ($kt$("Row", "", 0, 1, {$: "Con", "head": ($kt$("Patterns", "", 0, 1, {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}})), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 2)), "tail": {$: "Nil"}}})), "tail": {$: "Nil"}}, _vars_0, _next_0);
}), run_clo((_x_1) => {
  return $ff_let$(_t_0, _vars_0, run_loop($ff_flat$(run_loop($kid$(_t_0, 2)), {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}}, _next_0)));
}));
}

function $ff_parallel$(_t_0, _vars_0, _r_0) {
  const _body_0 = _r_0["term"];
  const _next_0 = _r_0["next"];
  return {$: "FFlatten", "term": ($f_lbind$(_vars_0, ($kt$("Let", "", 0, 1, ($norm_join$(($f_parallel_binds$(($ks$(run_loop($kid$(_t_0, 0)))), ($ks$(run_loop($kid$(_t_0, 1)))))), {$: "Con", "head": run_loop($f_unlamb$(_body_0, ($terms_len$(($ks$(run_loop($kid$(_t_0, 0)))))))), "tail": {$: "Nil"}})))))), "next": _next_0};
}

function $f_lbind$(_pars_0, _body_0) {
  if (_pars_0.$ === "Nil") {
    return _body_0;
  } else {
    const _p_0 = _pars_0["head"];
    const _ps_0 = _pars_0["tail"];
    return $kt$("Lam", ($nm$(_p_0)), ($ix$(_p_0)), ($qt$(_p_0)), {$: "Con", "head": ($f_lbind$(_ps_0, _body_0)), "tail": {$: "Nil"}});
  }
}

function $f_scope_parallel$(_t_0, _env_0, _book_0) {
  return $f_scope_parallel_pats$(_t_0, ($f_patterns$(($ks$(run_loop($kid$(_t_0, 0)))))), _env_0, _book_0);
}

function $f_scope_body_base$(_t_0, _env_0, _book_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Local")), run_clo((_x_0) => {
  return $f_scope_local$(_t_0, ($f_patterns$({$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}})), _env_0, _book_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Match")), run_clo((_x_2) => {
  return $kt$("Match", "", 0, 1, {$: "Con", "head": ($kt$("Heads", "", 0, 1, ($f_scope_terms$(($ks$(run_loop($kid$(_t_0, 0)))), _env_0, _book_0)))), "tail": ($f_scope_rows$(($f_tail_terms$(($ks$(_t_0)))), _env_0, _book_0))});
}), run_clo((_x_3) => {
  return $f_scope$(_t_0, _env_0, _book_0);
}));
}));
}

function $f_flat_parallel$(_t_0, _vars_0) {
  return $f_lbind$(_vars_0, ($kt$("Let", "", 0, 1, ($norm_join$(($f_parallel_binds$(($ks$(run_loop($kid$(_t_0, 0)))), ($ks$(run_loop($kid$(_t_0, 1)))))), {$: "Con", "head": run_loop($f_unlamb$(run_loop($f_flat$(run_loop($kid$(_t_0, 2)), ($ks$(run_loop($kid$(_t_0, 0)))))), ($terms_len$(($ks$(run_loop($kid$(_t_0, 0)))))))), "tail": {$: "Nil"}})))));
}

function $f_flat_base$(_t_0, _vars_0) {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Match")), run_clo((_x_0) => {
  return $f_flat_match$(($ks$(run_loop($kid$(_t_0, 0)))), ($f_tail_terms$(($ks$(_t_0)))), _vars_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_t_0)), "Local")), run_clo((_x_2) => {
  return $f_flat_local$(_t_0, _vars_0);
}), run_clo((_x_3) => {
  return $f_lbind$(_vars_0, _t_0);
}));
}));
}

function $core_subst_stable_app_tail$(_f_0, _tail_0) {
  if (_tail_0.$ === "Nil") {
    return false;
  } else {
    const _x_0 = _tail_0["head"];
    const _rest_0 = _tail_0["tail"];
    return $core_subst_stable_app_last$(_f_0, _x_0, _rest_0);
  }
}

function $kp_digit$(_n_0) {
  return $Char$show$(($Char$from_u32$(run_loop($kc$((_n_0 < 10), run_clo((_x_0) => {
  return ((_n_0 + 48) >>> 0);
}), run_clo((_x_1) => {
  return ((_n_0 + 87) >>> 0);
}))))));
}

function $g_cache$(_st_0, _id_0, _t_0) {
  return {$: "GState", "heap": run_loop($g_put$(($g_heap$(_st_0)), _id_0, ($kt$("GValue", "", 0, 0, {$: "Con", "head": _t_0, "tail": {$: "Nil"}})))), "next": ($g_next$(_st_0))};
}

function $g_shared_head$(_t_0, _r_0) {
  return {$: "GResult", "state": ($g_states$(_r_0)), "term": {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": ($ix$(_t_0)), "quant": ($qt$(_t_0)), "kids": ($g_terms$(_r_0)), "removed": ($rm$(_t_0))}};
}

function $g_share_terms$($0, $1, $2) {
  let $pc = 0;
  for (;;) switch ($pc) {
    case 0: {
      const _st_0 = $0;
      const _ts_0 = $1;
      const _done_0 = $2;
      if (_ts_0.$ === "Nil") {
        return {$: "GTerms", "state": _st_0, "terms": ($List$reverse$(_done_0))};
      } else {
        const _h_0 = _ts_0["head"];
        const _rest_0 = _ts_0["tail"];
        $0 = _rest_0;
        $1 = _done_0;
        $2 = run_loop($g_share$(_st_0, _h_0));
        $pc = 1; continue;
      }
    }
    case 1: {
      const _rest_0 = $0;
      const _done_0 = $1;
      const _r_0 = $2;
      $0 = ($g_state$(_r_0));
      $1 = _rest_0;
      $2 = {$: "Con", "head": ($g_term$(_r_0)), "tail": _done_0};
      $pc = 0; continue;
    }
  }
}

function $sp_mname$(_m_0) {
  const _name_0 = _m_0["name"];
  return _name_0;
}

function $sp_active$(_m_0) {
  const _active_0 = _m_0["active"];
  return _active_0;
}

function $sp_mint$(_st_0, _d_0, _xs_0, _depth_0, _key_0, _name_0) {
  return $sp_mint_type$(_st_0, _d_0, _xs_0, _depth_0, _key_0, _name_0, run_loop($tele_fill$(($sp_book$(_st_0)), ($sp_shift$(($dt$(_d_0)), ($sp_fresh$(_st_0)))), _xs_0)), ($sp_apply_template$(($sp_shift$(($dv$(_d_0)), ($sp_fresh$(_st_0)))), _xs_0)));
}

function $sp_mtemplate$(_m_0) {
  const _template_0 = _m_0["template"];
  return _template_0;
}

function $sp_mkey$(_m_0) {
  const _key_0 = _m_0["key"];
  return _key_0;
}

function $sp_key_string$(_s_0) {
  const _x_0 = ($U32$show$(($sp_len$(_s_0))));
  const _x_1 = (":" + _s_0);
  return (_x_0 + _x_1);
}

function $sp_name_keys$(_ns_0) {
  if (_ns_0.$ === "Nil") {
    return "";
  } else {
    const _h_0 = _ns_0["head"];
    const _rest_0 = _ns_0["tail"];
    const _x_0 = ($sp_key_string$(_h_0));
    const _x_1 = ($sp_name_keys$(_rest_0));
    return (_x_0 + _x_1);
  }
}

function $descend_go$(_a_0, _p_0) {
  return $kc$(($Bool$and$(run_loop($core_nat$(_a_0)), ($String$eq$(($tg$(_p_0)), "Ctr")))), run_clo((_x_0) => {
  return $descend_go$(run_loop($core_nat_step$(_a_0)), _p_0);
}), run_clo((_x_1) => {
  return $kc$(($String$eq$(($tg$(_p_0)), "Var")), run_clo((_x_2) => {
  const _x_3 = ($ix$(_a_0));
  const _x_4 = ($ix$(_p_0));
  return $kc$(($Bool$and$(($String$eq$(($tg$(_a_0)), "Var")), (_x_3 === _x_4))), run_clo((_x_5) => {
  return 1;
}), run_clo((_x_6) => {
  return 2;
}));
}), run_clo((_x_7) => {
  return $kc$(($String$eq$(($tg$(_p_0)), "Ctr")), run_clo((_x_8) => {
  const _x_9 = ($terms_len$(($ks$(_a_0))));
  const _x_10 = ($terms_len$(($ks$(_p_0))));
  return $descend_ctr$(_a_0, _p_0, run_loop($kc$(($Bool$and$(($Bool$and$(($String$eq$(($tg$(_a_0)), "Ctr")), ($String$eq$(($nm$(_a_0)), ($nm$(_p_0)))))), (_x_9 === _x_10))), run_clo((_x_11) => {
  return $descend_fields$(($ks$(_a_0)), ($ks$(_p_0)), 1, 0);
}), run_clo((_x_12) => {
  return {$: "KDescent", "order": 2, "bad": 4294967295};
}))));
}), run_clo((_x_13) => {
  return 2;
}));
}));
}));
}

function $tele_check_after_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0, _dem_0, _checked_head_0) {
  return $kc$(run_loop($core_subst_stable$(run_loop($kid$(_tel_0, 1)))), run_clo((_x_0) => {
  return $tele_check_done$(_checked_head_0, run_loop($tele_check_static$(_e_0, _ctx_0, run_loop($kid$(_tel_0, 1)), _rest_0, _dem_0)));
}), run_clo((_x_1) => {
  return $tele_check_done$(_checked_head_0, run_loop($tele_check_legacy$(_e_0, _ctx_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), _h_0)), _rest_0, _dem_0)));
}));
}

function $check_ctor_domain$(_e_0, _d_0, _tel_0, _kind_0, _params_0, _fields_0, _ctx_0, _args_0, _r_0) {
  return $kc$(($good$(_r_0)), run_clo((_x_0) => {
  return $check_ctor_tel$(_e_0, _d_0, run_loop($kid$(_tel_0, 1)), run_loop($kc$((_params_0 === 0), run_clo((_x_1) => {
  return _kind_0;
}), run_clo((_x_2) => {
  return $subst$(run_loop($kid$(run_loop($wnf$(($cb$(_e_0)), _kind_0)), 1)), ($ix$(run_loop($wnf$(($cb$(_e_0)), _kind_0)))), ($var$(($nm$(_tel_0)), ($ix$(_tel_0)))));
}))), run_loop($kc$((_params_0 === 0), run_clo((_x_3) => {
  return 0;
}), run_clo((_x_4) => {
  return ((_params_0 - 1) >>> 0);
}))), run_loop($kc$((_params_0 === 0), run_clo((_x_5) => {
  return ((_fields_0 - 1) >>> 0);
}), run_clo((_x_6) => {
  return _fields_0;
}))), ($ctx_bind$(_ctx_0, ($ix$(_tel_0)), ($qt$(_tel_0)), ($nm$(_tel_0)), run_loop($kid$(_tel_0, 0)))), run_loop($kc$((_params_0 === 0), run_clo((_x_7) => {
  return _args_0;
}), run_clo((_x_8) => {
  return $norm_join$(_args_0, {$: "Con", "head": ($var$(($nm$(_tel_0)), ($ix$(_tel_0)))), "tail": {$: "Nil"}});
}))));
}), run_clo((_x_9) => {
  return $ce$(_r_0);
}));
}

function $cp$(_e_0) {
  const _pending_0 = _e_0["pending"];
  return _pending_0;
}

function $mat_lhs$(_e_0, _name_0, _tel_0, _n_0, _avoid_0) {
  const _x_0 = ($cp$(_e_0));
  return $kc$((_x_0 === 0), run_clo((_x_1) => {
  return _e_0;
}), run_clo((_x_2) => {
  const _x_3 = ($norm_max_walk$({$: "Con", "head": ($cl$(_e_0)), "tail": {$: "Con", "head": _tel_0, "tail": _avoid_0}}, run_loop($norm_book_bound$(($cb$(_e_0))))));
  const _x_4 = ($cp$(_e_0));
  const _x_5 = ((_x_4 - 1) >>> 0);
  return {$: "KEnv", "book": ($cb$(_e_0)), "name": ($cn$(_e_0)), "lhs": run_loop($lhs_ext$(($cl$(_e_0)), _name_0, _tel_0, _n_0, {$: "Nil"}, ((1 + _x_3) >>> 0))), "pending": ((_x_5 + _n_0) >>> 0), "quantities": ($cq$(_e_0)), "unsafe": ($cu$(_e_0))};
}));
}

function $fp_offset$(_text_0, _line_0, _column_0, _targetLine_0, _targetColumn_0, _offset_0) {
  const _x_0 = ($String$is_empty$(_text_0));
  const _x_1 = ($Bool$and$((_line_0 === _targetLine_0), (_column_0 === _targetColumn_0)));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return _offset_0;
}), run_clo((_x_3) => {
  const _x_8 = ($Char$to_u32$(($f_head$(_text_0))));
  const _x_11 = run_loop($f_choose$((_x_8 > 65535), run_clo((_x_9) => {
  return 2;
}), run_clo((_x_10) => {
  return 1;
})));
  return $fp_offset$(($f_tail$(_text_0)), run_loop($f_choose$(($Char$is_eq$(($f_head$(_text_0)), "\n")), run_clo((_x_4) => {
  return ((_line_0 + 1) >>> 0);
}), run_clo((_x_5) => {
  return _line_0;
}))), run_loop($f_choose$(($Char$is_eq$(($f_head$(_text_0)), "\n")), run_clo((_x_6) => {
  return 0;
}), run_clo((_x_7) => {
  return ((_column_0 + 1) >>> 0);
}))), _targetLine_0, _targetColumn_0, ((_offset_0 + _x_11) >>> 0));
}));
}

function $fp_utf16$(_text_0) {
  return $f_choose$(($String$is_empty$(_text_0)), run_clo((_x_0) => {
  return 0;
}), run_clo((_x_1) => {
  const _x_2 = ($Char$to_u32$(($f_head$(_text_0))));
  const _x_5 = run_loop($f_choose$((_x_2 > 65535), run_clo((_x_3) => {
  return 2;
}), run_clo((_x_4) => {
  return 1;
})));
  const _x_6 = run_loop($fp_utf16$(($f_tail$(_text_0))));
  return ((_x_5 + _x_6) >>> 0);
}));
}

function $f_do_types_at$(_monad_0, _types_0, _ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_0) => {
  return $f_do$(_monad_0, ($ks$(_types_0)), run_loop($f_skip$(($f_tl$(_ts_0)))), ($f_col$(run_loop($f_skip$(($f_tl$(_ts_0)))))));
}), run_clo((_x_1) => {
  return $f_err$(_ts_0, "expected :");
}));
}

function $f_rewrite_body$(_e_0, _motive_0, _p_0) {
  const _body_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Rwt", "", 0, 1, {$: "Con", "head": _e_0, "tail": {$: "Con", "head": _motive_0, "tail": {$: "Con", "head": _body_0, "tail": {$: "Nil"}}}})), "rest": _ts_0};
}

function $f_match_heads$(_ts_0, _indent_0, _acc_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_0) => {
  return $f_match_begin$(run_loop($f_skip$(($f_tl$(_ts_0)))), _indent_0, ($List$reverse$(_acc_0)));
}), run_clo((_x_1) => {
  return $f_match_head$(run_loop($f_expr$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), ",")), run_clo((_x_2) => {
  return $f_tl$(_ts_0);
}), run_clo((_x_3) => {
  return _ts_0;
}))), 0)), _indent_0, _acc_0);
}));
}

function $f_body_at$(_ts_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "-")), run_clo((_x_0) => {
  return $f_erased_local$(($f_tl$(_ts_0)));
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "match")), run_clo((_x_2) => {
  return $f_match_heads$(($f_tl$(_ts_0)), ($f_col$(_ts_0)), {$: "Nil"});
}), run_clo((_x_3) => {
  return $f_statement$(run_loop($f_expr$(_ts_0, 0)));
}));
}));
}

function $f_equation_type$(_a_0, _b_0, _neg_0, _p_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": run_loop($f_choose$(_neg_0, run_clo((_x_0) => {
  return $kt$("All", "_", 0, 1, {$: "Con", "head": ($kt$("Eql", "", 0, 1, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}}})), "tail": {$: "Con", "head": ($kt$("Ref", "Empty", 0, 1, {$: "Nil"})), "tail": {$: "Nil"}}});
}), run_clo((_x_1) => {
  return $kt$("Eql", "", 0, 1, {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}}});
}))), "rest": _ts_0};
}

function $f_array_size$(_n_0, _ty_0, _count_0, _p_0) {
  const _size_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_size_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _size_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_expect$({$: "FParsed", "term": ($f_app$(($ref$("Array.new")), {$: "Con", "head": _ty_0, "tail": {$: "Con", "head": run_loop($f_choose$(_count_0, run_clo((_x_2) => {
  return $f_array_depth$(_size_0);
}), run_clo((_x_3) => {
  return _size_0;
}))), "tail": {$: "Con", "head": run_loop($f_namespace$(_n_0, _ty_0)), "tail": {$: "Nil"}}}})), "rest": run_loop($f_space$(_ts_0))}, "]");
}));
}

function $f_list_nodes$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return $kt$("Ctr", "Nil", 0, 1, {$: "Nil"});
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    return $kt$("Ctr", "Con", 0, 1, {$: "Con", "head": _x_0, "tail": {$: "Con", "head": ($f_list_nodes$(_xt_0)), "tail": {$: "Nil"}}});
  }
}

function $f_matcher_tail$(_name_0, _n_0, _p_0) {
  const _m_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Mat", _name_0, 0, 1, {$: "Con", "head": _n_0, "tail": {$: "Con", "head": _m_0, "tail": {$: "Nil"}}})), "rest": _ts_0};
}

function $f_nat_extend$(_a_0, _b_0) {
  return $f_nat_extend_value$(_a_0, _b_0, run_loop($f_choose$(($Bool$and$(($f_eq$(($tg$(_b_0)), "Literal")), ($String$ends_with$(($nm$(_b_0)), "n")))), run_clo((_x_0) => {
  return $f_literal$(($nm$(_b_0)));
}), run_clo((_x_1) => {
  return _b_0;
}))));
}

function $f_string_decoded$(_d_0) {
  const _code_0 = _d_0["code"];
  const _rest_0 = _d_0["rest"];
  const _err_0 = _d_0["error"];
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $kt$("Ctr", "SCon", 0, 1, {$: "Con", "head": ($kt$("Ctr", "Chr", 0, 1, {$: "Con", "head": ($f_u32$(_code_0)), "tail": {$: "Nil"}})), "tail": {$: "Con", "head": run_loop($f_string$(_rest_0)), "tail": {$: "Nil"}}});
}), run_clo((_x_1) => {
  return $kt$("Error", _err_0, 0, 0, {$: "Nil"});
}));
}

function $f_decode_char$(_s_0) {
  return $f_choose$(($String$is_empty$(_s_0)), run_clo((_x_0) => {
  return {$: "FDecoded", "code": 0, "rest": "", "error": "expected character"};
}), run_clo((_x_1) => {
  return $f_choose$(($Char$is_eq$(($f_head$(_s_0)), "\\")), run_clo((_x_2) => {
  return $f_decode_escape$(($f_tail$(_s_0)));
}), run_clo((_x_3) => {
  return {$: "FDecoded", "code": ($Char$to_u32$(($f_head$(_s_0)))), "rest": ($f_tail$(_s_0)), "error": ""};
}));
}));
}

function $f_char_decoded$(_d_0) {
  const _code_0 = _d_0["code"];
  const _rest_0 = _d_0["rest"];
  const _err_0 = _d_0["error"];
  return $f_choose$(($Bool$and$(($String$is_empty$(_err_0)), ($f_eq$(_rest_0, "'")))), run_clo((_x_0) => {
  return $kt$("Ctr", "Chr", 0, 1, {$: "Con", "head": ($f_u32$(_code_0)), "tail": {$: "Nil"}});
}), run_clo((_x_1) => {
  return $kt$("Error", "character literal requires one character and a closing quote", 0, 0, {$: "Nil"});
}));
}

function $f_float_read$(_m_0) {
  if (_m_0.$ === "None") {
    return $kt$("Error", "invalid f32 literal", 0, 0, {$: "Nil"});
  } else {
    const _v_0 = _m_0["value"];
    return $f_float_bits$(f32_bits(_v_0));
  }
}

function $f_u32$(_n_0) {
  return $kt$("Ctr", "U32", 0, 1, {$: "Con", "head": run_loop($f_word$(_n_0, 32)), "tail": {$: "Nil"}});
}

function $f_nat$(_n_0) {
  return $core_nat_make$(_n_0);
}

function $f_escape_code$(_c_0) {
  return $f_choose$(($Char$is_eq$(_c_0, "n")), run_clo((_x_0) => {
  return 10;
}), run_clo((_x_1) => {
  return $f_choose$(($Char$is_eq$(_c_0, "t")), run_clo((_x_2) => {
  return 9;
}), run_clo((_x_3) => {
  return $f_choose$(($Char$is_eq$(_c_0, "r")), run_clo((_x_4) => {
  return 13;
}), run_clo((_x_5) => {
  return $f_choose$(($Char$is_eq$(_c_0, "0")), run_clo((_x_6) => {
  return 0;
}), run_clo((_x_7) => {
  return $Char$to_u32$(_c_0);
}));
}));
}));
}));
}

function $fc_ref$(_name_0, _env_0) {
  const _x_0 = run_loop($f_contains$(_name_0, "."));
  const _x_1 = ($Bool$not$(($f_eq$(($tg$(run_loop($f_env$(_name_0, _env_0)))), "Absent"))));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return 0;
}), run_clo((_x_3) => {
  return 1;
}));
}

function $fc_terms$(_ts_0, _env_0) {
  if (_ts_0.$ === "Nil") {
    return 0;
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = run_loop($fc_term$(_t_0, _env_0));
    const _x_1 = ($fc_terms$(_rest_0, _env_0));
    return ((_x_0 + _x_1) >>> 0);
  }
}

function $fc_bind$(_v_0, _env_0) {
  return $f_choose$(($f_eq$(($nm$(_v_0)), "_")), run_clo((_x_0) => {
  return _env_0;
}), run_clo((_x_1) => {
  return {$: "Con", "head": _v_0, "tail": _env_0};
}));
}

function $fc_rows$(_rs_0, _env_0) {
  if (_rs_0.$ === "Nil") {
    return 0;
  } else {
    const _r_0 = _rs_0["head"];
    const _rest_0 = _rs_0["tail"];
    const _x_0 = run_loop($fc_term$(run_loop($kid$(_r_0, 1)), ($norm_join$(run_loop($fc_binders$(($ks$(run_loop($kid$(_r_0, 0)))))), _env_0))));
    const _x_1 = ($fc_rows$(_rest_0, _env_0));
    const _x_2 = ($fc_bind_count$(($ks$(run_loop($kid$(_r_0, 0))))));
    const _x_3 = ((_x_0 + _x_1) >>> 0);
    const _x_4 = ($fc_terms$(($ks$(run_loop($kid$(_r_0, 0)))), _env_0));
    const _x_5 = ((_x_2 + _x_3) >>> 0);
    return ((_x_4 + _x_5) >>> 0);
  }
}

function $fc_bind_count$(_ps_0) {
  if (_ps_0.$ === "Nil") {
    return 0;
  } else {
    const _p_0 = _ps_0["head"];
    const _rest_0 = _ps_0["tail"];
    const _x_0 = ($f_eq$(($tg$(_p_0)), "Ref"));
    const _x_1 = ($f_eq$(($tg$(_p_0)), "Var"));
    const _x_4 = run_loop($f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return 1;
}), run_clo((_x_3) => {
  return $fc_bind_count$(($ks$(_p_0)));
})));
    const _x_5 = ($fc_bind_count$(_rest_0));
    return ((_x_4 + _x_5) >>> 0);
  }
}

function $fc_binders$(_ps_0) {
  if (_ps_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _p_0 = _ps_0["head"];
    const _rest_0 = _ps_0["tail"];
    const _x_0 = ($f_eq$(($tg$(_p_0)), "Ref"));
    const _x_1 = ($f_eq$(($tg$(_p_0)), "Var"));
    return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $fc_bind$(_p_0, run_loop($fc_binders$(_rest_0)));
}), run_clo((_x_3) => {
  return $norm_join$(run_loop($fc_binders$(($ks$(_p_0)))), run_loop($fc_binders$(_rest_0)));
}));
  }
}

function $f_operator_display$(_name_0, _ops_0) {
  if (_ops_0.$ === "Nil") {
    return _name_0;
  } else {
    const _op_0 = _ops_0["head"];
    const _rest_0 = _ops_0["tail"];
    return $f_choose$(($f_eq$(run_loop($f_operator$(_op_0)), _name_0)), run_clo((_x_0) => {
  return $f_choose$(($f_eq$(_op_0, ">op")), run_clo((_x_1) => {
  return ">";
}), run_clo((_x_2) => {
  return $f_choose$(($f_eq$(_op_0, ">>op")), run_clo((_x_3) => {
  return ">>";
}), run_clo((_x_4) => {
  return _op_0;
}));
}));
}), run_clo((_x_5) => {
  return $f_operator_display$(_name_0, _rest_0);
}));
  }
}

function $f_first_ctor$(_rows_0) {
  if (_rows_0.$ === "Nil") {
    return $atom$("Absent");
  } else {
    const _r_0 = _rows_0["head"];
    const _rs_0 = _rows_0["tail"];
    return $f_choose$(($f_eq$(($tg$(run_loop($f_rowpat$(_r_0)))), "Ctr")), run_clo((_x_0) => {
  return $f_rowpat$(_r_0);
}), run_clo((_x_1) => {
  return $f_first_ctor$(_rs_0);
}));
  }
}

function $f_has_id$(_vars_0, _id_0) {
  if (_vars_0.$ === "Nil") {
    return false;
  } else {
    const _v_0 = _vars_0["head"];
    const _vs_0 = _vars_0["tail"];
    const _x_0 = ($ix$(_v_0));
    const _x_1 = (_x_0 === _id_0);
    const _x_2 = ($f_has_id$(_vs_0, _id_0));
    return (_x_1 || _x_2);
  }
}

function $f_var_rows$(_rows_0, _v_0) {
  if (_rows_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _r_0 = _rows_0["head"];
    const _rs_0 = _rows_0["tail"];
    const _x_0 = ($qt$(_r_0));
    return {$: "Con", "head": ($kt$("Row", "", 0, ($qt$(_r_0)), {$: "Con", "head": ($kt$("Patterns", "", 0, 1, ($f_tail_terms$(($ks$(run_loop($kid$(_r_0, 0)))))))), "tail": {$: "Con", "head": run_loop($f_choose$((_x_0 === 0), run_clo((_x_1) => {
  return $kid$(_r_0, 1);
}), run_clo((_x_2) => {
  return $f_sub$(run_loop($kid$(_r_0, 1)), ($ix$(run_loop($f_rowpat$(_r_0)))), _v_0);
}))), "tail": {$: "Nil"}}})), "tail": ($f_var_rows$(_rs_0, _v_0))};
  }
}

function $f_mark_vars$(_vars_0, _id_0, _q_0) {
  if (_vars_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _v_0 = _vars_0["head"];
    const _vs_0 = _vars_0["tail"];
    const _x_0 = ($ix$(_v_0));
    return {$: "Con", "head": run_loop($f_choose$((_x_0 === _id_0), run_clo((_x_1) => {
  return $kt$("Var", ($nm$(_v_0)), ($ix$(_v_0)), _q_0, {$: "Nil"});
}), run_clo((_x_2) => {
  return _v_0;
}))), "tail": ($f_mark_vars$(_vs_0, _id_0, _q_0))};
  }
}

function $f_mark_rows$($0, $1) {
  for (;;) {
    {
      const _rows_0 = $0;
      const _q_0 = $1;
      if (_rows_0.$ === "Nil") {
        return _q_0;
      } else {
        const _r_0 = _rows_0["head"];
        const _rs_0 = _rows_0["tail"];
        const _x_0 = ($qt$(run_loop($f_rowpat$(_r_0))));
        $0 = _rs_0;
        $1 = run_loop($f_choose$(($Bool$and$(($f_eq$(($tg$(run_loop($f_rowpat$(_r_0)))), "Var")), (_x_0 === 2))), run_clo((_x_1) => {
  return 2;
}), run_clo((_x_2) => {
  return _q_0;
})));
        continue;
      }
    }
  }
}

function $ff_column$(_h_0, _hs_0, _rows_0, _vars_0, _next_0) {
  if (_vars_0.$ === "Nil") {
    return {$: "FFlatten", "term": ($kt$("Error", "match requires an unconsumed parameter or constructor field", 0, 0, {$: "Nil"})), "next": _next_0};
  } else {
    const _v_0 = _vars_0["head"];
    const _vs_0 = _vars_0["tail"];
    const _x_0 = ($ix$(_h_0));
    const _x_1 = ($ix$(_v_0));
    return $f_choose$((_x_0 === _x_1), run_clo((_x_2) => {
  return $ff_split$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, run_loop($f_first_ctor$(_rows_0)), _next_0);
}), run_clo((_x_3) => {
  return $ff_lam$(_v_0, run_loop($ff_match$({$: "Con", "head": _h_0, "tail": _hs_0}, _rows_0, _vs_0, _next_0)));
}));
  }
}

function $ff_let$(_t_0, _vars_0, _r_0) {
  const _body_0 = _r_0["term"];
  const _next_0 = _r_0["next"];
  return {$: "FFlatten", "term": run_loop($f_choose$(($f_eq$(($tg$(_body_0)), "Lam")), run_clo((_x_0) => {
  return $f_lbind$(_vars_0, ($kt$("Let", "", 0, 1, {$: "Con", "head": ($kt$("Bind", ($nm$(run_loop($kid$(_t_0, 0)))), ($ix$(run_loop($kid$(_t_0, 0)))), ($qt$(run_loop($kid$(_t_0, 0)))), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Nil"}})), "tail": {$: "Con", "head": run_loop($kid$(_body_0, 0)), "tail": {$: "Nil"}}})));
}), run_clo((_x_1) => {
  return $kt$("Error", "a match cannot scrutinize a local binding", 0, 0, {$: "Nil"});
}))), "next": _next_0};
}

function $f_parallel_binds$(_pats_0, _vals_0) {
  if (_pats_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _p_0 = _pats_0["head"];
    const _ps_0 = _pats_0["tail"];
    return {$: "Con", "head": ($kt$("Bind", ($nm$(_p_0)), ($ix$(_p_0)), ($qt$(_p_0)), {$: "Con", "head": run_loop($terms_at$(_vals_0, 0)), "tail": {$: "Nil"}})), "tail": ($f_parallel_binds$(_ps_0, ($f_tail_terms$(_vals_0))))};
  }
}

function $f_unlamb$(_body_0, _n_0) {
  return $f_choose$((_n_0 === 0), run_clo((_x_0) => {
  return _body_0;
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($tg$(_body_0)), "Lam")), run_clo((_x_2) => {
  return $f_unlamb$(run_loop($kid$(_body_0, 0)), ((_n_0 - 1) >>> 0));
}), run_clo((_x_3) => {
  return $kt$("Error", "cannot match a parallel let binding", 0, 0, {$: "Nil"});
}));
}));
}

function $f_scope_parallel_pats$(_t_0, _pats_0, _env_0, _book_0) {
  return $f_scope_parallel_valid$(_t_0, _pats_0, _env_0, _book_0, run_loop($f_valid_patterns_mode$(_pats_0, _book_0, true)));
}

function $f_patterns$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    return {$: "Con", "head": run_loop($f_choose$(($f_eq$(($tg$(_x_0)), "Ref")), run_clo((_x_1) => {
  return $kt$("Var", ($nm$(_x_0)), ($ix$(_x_0)), ($qt$(_x_0)), {$: "Nil"});
}), run_clo((_x_2) => {
  return $f_choose$(($f_eq$(($tg$(_x_0)), "Literal")), run_clo((_x_3) => {
  return $f_pattern_literal$(($nm$(_x_0)));
}), run_clo((_x_4) => {
  return $kt$(($tg$(_x_0)), ($nm$(_x_0)), ($ix$(_x_0)), ($qt$(_x_0)), ($f_patterns$(($ks$(_x_0)))));
}));
}))), "tail": ($f_patterns$(_xt_0))};
  }
}

function $f_scope_local$(_t_0, _pats_0, _env_0, _book_0) {
  return $f_scope_local_valid$(_t_0, _pats_0, _env_0, _book_0, run_loop($f_valid_patterns$(_pats_0, run_loop($f_choose$(($f_eq$(($nm$(_t_0)), "Do")), run_clo((_x_0) => {
  return {$: "Nil"};
}), run_clo((_x_1) => {
  return _book_0;
}))))));
}

function $f_scope_rows$(_rows_0, _env_0, _book_0) {
  if (_rows_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _r_0 = _rows_0["head"];
    const _rs_0 = _rows_0["tail"];
    return {$: "Con", "head": run_loop($f_scope_row$(_r_0, ($f_patterns$(($ks$(run_loop($kid$(_r_0, 0)))))), _env_0, _book_0)), "tail": ($f_scope_rows$(_rs_0, _env_0, _book_0))};
  }
}

function $f_flat_match$(_heads_0, _rows_0, _vars_0) {
  if (_heads_0.$ === "Nil") {
    const _x_0 = ($terms_len$(_rows_0));
    return $f_choose$((_x_0 === 0), run_clo((_x_1) => {
  return $atom$("Efq");
}), run_clo((_x_2) => {
  return $f_flat$(run_loop($kid$(run_loop($terms_at$(_rows_0, 0)), 1)), _vars_0);
}));
  } else {
    const _h_0 = _heads_0["head"];
    const _hs_0 = _heads_0["tail"];
    const _x_3 = ($terms_len$(_rows_0));
    return $f_choose$(($Bool$and$(($Bool$and$(($f_eq$(($tg$(run_loop($f_first_ctor$(_rows_0)))), "Absent")), (_x_3 > 0))), ($f_has_id$(_vars_0, ($ix$(_h_0)))))), run_clo((_x_4) => {
  return $f_flat_match$(_hs_0, ($f_var_rows$(_rows_0, _h_0)), ($f_mark_vars$(_vars_0, ($ix$(_h_0)), ($f_mark_rows$(_rows_0, ($qt$(_h_0)))))));
}), run_clo((_x_5) => {
  return $f_flat_column$(_h_0, _hs_0, _rows_0, _vars_0);
}));
  }
}

function $f_flat_local$(_t_0, _vars_0) {
  return $f_choose$(($f_eq$(($tg$(run_loop($kid$(_t_0, 0)))), "Ctr")), run_clo((_x_0) => {
  return $f_flat_match$({$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Nil"}}, {$: "Con", "head": ($kt$("Row", "", 0, 1, {$: "Con", "head": ($kt$("Patterns", "", 0, 1, {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}})), "tail": {$: "Con", "head": run_loop($kid$(_t_0, 2)), "tail": {$: "Nil"}}})), "tail": {$: "Nil"}}, _vars_0);
}), run_clo((_x_1) => {
  return $f_flat_let$(_t_0, _vars_0, run_loop($f_flat$(run_loop($kid$(_t_0, 2)), {$: "Con", "head": run_loop($kid$(_t_0, 0)), "tail": {$: "Nil"}})));
}));
}

function $core_subst_stable_app_last$(_f_0, _x_0, _rest_0) {
  if (_rest_0.$ === "Con") {
    return false;
  } else {
    return $Bool$not$(($String$eq$(($tg$(_f_0)), "Lam")));
  }
}

function $g_states$(_r_0) {
  const _state_0 = _r_0["state"];
  return _state_0;
}

function $g_terms$(_r_0) {
  const _terms_0 = _r_0["terms"];
  return _terms_0;
}

function $g_shared_term$($0, $1, $2) {
  let $pc = 1;
  for (;;) switch ($pc) {
    case 0: {
      const _st_0 = $0;
      const _ts_0 = $1;
      const _done_0 = $2;
      if (_ts_0.$ === "Nil") {
        return {$: "GTerms", "state": _st_0, "terms": ($List$reverse$(_done_0))};
      } else {
        const _h_0 = _ts_0["head"];
        const _rest_0 = _ts_0["tail"];
        $0 = _rest_0;
        $1 = _done_0;
        $2 = run_loop($g_share$(_st_0, _h_0));
        $pc = 1; continue;
      }
    }
    case 1: {
      const _rest_0 = $0;
      const _done_0 = $1;
      const _r_0 = $2;
      $0 = ($g_state$(_r_0));
      $1 = _rest_0;
      $2 = {$: "Con", "head": ($g_term$(_r_0)), "tail": _done_0};
      $pc = 0; continue;
    }
  }
}

function $sp_mint_type$(_st_0, _d_0, _xs_0, _depth_0, _key_0, _name_0, _ty_0, _body_0) {
  const _x_0 = ($da$(_d_0));
  const _x_1 = ($dx$(_d_0));
  const _x_2 = ($sp_fresh$(_st_0));
  const _x_3 = run_loop($norm_max$(($norm_max_term$(($dt$(_d_0)))), ($norm_max_term$(($dv$(_d_0))))));
  const _x_4 = ($sp_serial$(_st_0));
  const _x_5 = ($sp_fresh$(_st_0));
  const _x_6 = run_loop($norm_max$(($norm_max_term$(($dt$(_d_0)))), ($norm_max_term$(($dv$(_d_0))))));
  const _x_7 = ((_x_5 + _x_6) >>> 0);
  return $sp_mint_body$(_d_0, _name_0, _ty_0, run_loop($sp_term$({$: "KSpecState", "book": {$: "Con", "head": {$: "KDef", "name": _name_0, "kind": "Def", "arity": ((_x_0 - _x_1) >>> 0), "templates": 0, "typ": _ty_0, "value": ($atom$("Absent")), "ctors": {$: "Nil"}, "native": false, "unsafe": ($du$(_d_0))}, "tail": ($sp_stamp$(($sp_book$(_st_0)), ((_x_2 + _x_3) >>> 0)))}, "memo": {$: "Con", "head": {$: "KSpecMemo", "template": ($dn$(_d_0)), "key": _key_0, "name": _name_0, "active": true}, "tail": ($sp_memo$(_st_0))}, "serial": ((_x_4 + 1) >>> 0), "fresh": ((_x_7 + 1) >>> 0), "error": ($sp_error$(_st_0)), "templates": ($sp_templates$(_st_0))}, _body_0, {$: "Nil"}, _ty_0, _name_0, _depth_0)));
}

function $sp_shift$(_t_0, _offset_0) {
  const _x_0 = ($String$eq$(($tg$(_t_0)), "Var"));
  const _x_1 = ($String$eq$(($tg$(_t_0)), "All"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($String$eq$(($tg$(_t_0)), "Lam"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($String$eq$(($tg$(_t_0)), "Bind"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($String$eq$(($tg$(_t_0)), "Sub"));
  return {$: "KTerm", "tag": ($tg$(_t_0)), "name": ($nm$(_t_0)), "id": run_loop($kc$((_x_6 || _x_7), run_clo((_x_8) => {
  const _x_9 = ($ix$(_t_0));
  return ((_x_9 + _offset_0) >>> 0);
}), run_clo((_x_10) => {
  return $ix$(_t_0);
}))), "quant": ($qt$(_t_0)), "kids": ($sp_shifts$(($ks$(_t_0)), _offset_0)), "removed": ($rm$(_t_0))};
}

function $sp_apply_template$($0, $1) {
  for (;;) {
    {
      const _body_0 = $0;
      const _xs_0 = $1;
      if (_xs_0.$ === "Nil") {
        return _body_0;
      } else {
        const _h_0 = _xs_0["head"];
        const _rest_0 = _xs_0["tail"];
        $0 = run_loop($kapply$(_body_0, _h_0));
        $1 = _rest_0;
        continue;
      }
    }
  }
}

function $descend_ctr$(_a_0, _p_0, _result_0) {
  const _ord_0 = _result_0["order"];
  const _bad_0 = _result_0["bad"];
  return $kc$((_ord_0 === 2), run_clo((_x_0) => {
  return $descend_sub$(_a_0, ($ks$(_p_0)), _bad_0, 0);
}), run_clo((_x_1) => {
  return _ord_0;
}));
}

function $descend_fields$(_a_0, _p_0, _ord_0, _index_0) {
  if (_a_0.$ === "Nil") {
    return {$: "KDescent", "order": _ord_0, "bad": 4294967295};
  } else {
    const _h_0 = _a_0["head"];
    const _t_0 = _a_0["tail"];
    return $descend_field$(_t_0, ($terms_tail$(_p_0)), _ord_0, _index_0, run_loop($descend$(1, _h_0, run_loop($terms_at$(_p_0, 0)))));
  }
}

function $tele_check_done$(_a_0, _b_0) {
  return $both$(_a_0, _b_0, ($ct$(_b_0)), ($cy$(_b_0)), false);
}

function $tele_check_static$(_e_0, _ctx_0, _tel_0, _args_0, _dem_0) {
  if (_args_0.$ === "Nil") {
    return $ok$(($atom$("Args")), _tel_0, {$: "Nil"});
  } else {
    const _h_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return $tele_check_done$(run_loop($check$(_e_0, _ctx_0, _h_0, run_loop($qdem$(($qt$(_tel_0)), _dem_0)), run_loop($kid$(_tel_0, 0)))), run_loop($tele_check_static$(_e_0, _ctx_0, run_loop($kid$(_tel_0, 1)), _rest_0, _dem_0)));
}), run_clo((_x_1) => {
  return $tele_check$(_e_0, _ctx_0, _tel_0, {$: "Con", "head": _h_0, "tail": _rest_0}, _dem_0);
}));
  }
}

function $tele_check_legacy$(_e_0, _ctx_0, _tel_0, _args_0, _dem_0) {
  if (_args_0.$ === "Nil") {
    return $ok$(($atom$("Args")), _tel_0, {$: "Nil"});
  } else {
    const _h_0 = _args_0["head"];
    const _rest_0 = _args_0["tail"];
    return $tele_check_legacy_head$(_e_0, _ctx_0, run_loop($wnf$(($cb$(_e_0)), _tel_0)), _h_0, _rest_0, _dem_0);
  }
}

function $lhs_ext$(_lhs_0, _name_0, _tel_0, _n_0, _xs_0, _fresh_0) {
  return $kc$((_n_0 === 0), run_clo((_x_0) => {
  return $kapply$(_lhs_0, ($kt$("Ctr", _name_0, 0, 0, _xs_0)));
}), run_clo((_x_1) => {
  return $kt$("Lam", ($nm$(_tel_0)), _fresh_0, ($qt$(_tel_0)), {$: "Con", "head": run_loop($lhs_ext$(_lhs_0, _name_0, run_loop($kid$(_tel_0, 1)), ((_n_0 - 1) >>> 0), ($norm_join$(_xs_0, {$: "Con", "head": ($var$(($nm$(_tel_0)), _fresh_0)), "tail": {$: "Nil"}})), ((_fresh_0 + 1) >>> 0))), "tail": {$: "Nil"}});
}));
}

function $f_do$(_monad_0, _types_0, _ts_0, _indent_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "return")), run_clo((_x_0) => {
  return $f_do_return$(_monad_0, _types_0, ($f_atid$(_ts_0)), run_loop($f_expr$(($f_tl$(_ts_0)), 0)));
}), run_clo((_x_1) => {
  return $f_do_statement$(_monad_0, _types_0, run_loop($f_expr$(_ts_0, 0)), _indent_0);
}));
}

function $f_match_begin$(_ts_0, _outer_0, _heads_0) {
  const _x_0 = ($f_col$(_ts_0));
  return $f_choose$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "case")), (_x_0 > _outer_0))), run_clo((_x_1) => {
  const _x_2 = ($f_col$(_ts_0));
  return $f_match_cases$(_ts_0, ((_x_2 - 1) >>> 0), _heads_0, {$: "Nil"});
}), run_clo((_x_3) => {
  return {$: "FParsed", "term": ($kt$("Match", "", 0, 1, {$: "Con", "head": ($kt$("Heads", "", 0, 1, _heads_0)), "tail": {$: "Nil"}})), "rest": _ts_0};
}));
}

function $f_match_head$(_p_0, _indent_0, _acc_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_match_heads$(_ts_0, _indent_0, {$: "Con", "head": _n_0, "tail": _acc_0});
}));
}

function $f_erased_local$(_ts_0) {
  return $f_statement$({$: "FParsed", "term": ($kt$("Ref", ($f_tx$(_ts_0)), ($f_atid$(_ts_0)), 0, {$: "Nil"})), "rest": ($f_tl$(_ts_0))});
}

function $f_statement$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "=")), run_clo((_x_0) => {
  return $f_let_value$(_n_0, run_loop($f_expr$(($f_tl$(_ts_0)), 0)));
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_2) => {
  return $f_typed_let_try$(_n_0, _ts_0, run_loop($f_expr$(($f_tl$(_ts_0)), 0)));
}), run_clo((_x_3) => {
  return $f_statement_more$({$: "FParsed", "term": _n_0, "rest": _ts_0});
}));
}));
}

function $f_array_depth$(_size_0) {
  return $f_choose$(($f_eq$(($tg$(_size_0)), "Literal")), run_clo((_x_0) => {
  return $f_power_depth$(($nm$(_size_0)), 0);
}), run_clo((_x_1) => {
  return $kt$("Error", "array count must be a literal power of two", 0, 0, {$: "Nil"});
}));
}

function $f_nat_extend_value$(_a_0, _b_0, _value_0) {
  const _x_0 = ($qt$(_a_0));
  const _x_1 = ($qt$(_value_0));
  const _x_2 = ((4294967295 - _x_0) >>> 0);
  return $f_choose$(($Bool$and$(($Bool$and$(run_loop($core_nat$(_a_0)), run_loop($core_nat$(_value_0)))), (_x_1 <= _x_2))), run_clo((_x_3) => {
  const _x_4 = ($qt$(_a_0));
  const _x_5 = ($qt$(_value_0));
  const _x_6 = ($U32$show$(((_x_4 + _x_5) >>> 0)));
  return $kt$("Literal", (_x_6 + "n"), 0, 1, {$: "Nil"});
}), run_clo((_x_7) => {
  const _x_8 = ($qt$(_a_0));
  return $f_choose$(($Bool$and$(run_loop($core_nat$(_a_0)), (_x_8 <= 256))), run_clo((_x_9) => {
  return $f_nat_prefix$(($qt$(_a_0)), _b_0);
}), run_clo((_x_10) => {
  return $f_app$(($ref$("Nat.add")), {$: "Con", "head": _a_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}});
}));
}));
}

function $f_decode_escape$(_s_0) {
  return $f_choose$(($Bool$and$(($Char$is_eq$(($f_head$(_s_0)), "u")), ($Char$is_eq$(($f_head$(($f_tail$(_s_0)))), "{")))), run_clo((_x_0) => {
  return $f_decode_unicode$(($f_tail$(($f_tail$(_s_0)))), 0, 0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_escape_valid$(($f_head$(_s_0)))), run_clo((_x_2) => {
  return {$: "FDecoded", "code": run_loop($f_escape_code$(($f_head$(_s_0)))), "rest": ($f_tail$(_s_0)), "error": ""};
}), run_clo((_x_3) => {
  return {$: "FDecoded", "code": 0, "rest": _s_0, "error": "invalid character escape"};
}));
}));
}

function $f_float_bits$(_bits_0) {
  const _x_0 = ((_bits_0 & 2139095040) >>> 0);
  return $f_choose$((_x_0 === 2139095040), run_clo((_x_1) => {
  return $kt$("Error", "float literal must be finite", 0, 0, {$: "Nil"});
}), run_clo((_x_2) => {
  return $kt$("Ctr", "F32", 0, 1, {$: "Con", "head": run_loop($f_word$(_bits_0, 32)), "tail": {$: "Nil"}});
}));
}

function $f_word$(_n_0, _bits_0) {
  return $f_choose$((_bits_0 === 0), run_clo((_x_0) => {
  return $kt$("Ctr", "WNil", 0, 1, {$: "Nil"});
}), run_clo((_x_1) => {
  const _x_2 = ((_n_0 & 1) >>> 0);
  return $kt$("Ctr", "WCon", 0, 1, {$: "Con", "head": ($kt$("Ctr", run_loop($f_choose$((_x_2 === 0), run_clo((_x_3) => {
  return "False";
}), run_clo((_x_4) => {
  return "True";
}))), 0, 1, {$: "Nil"})), "tail": {$: "Con", "head": run_loop($f_word$((1 >= 32 ? 0 : (_n_0 >>> 1) >>> 0), ((_bits_0 - 1) >>> 0))), "tail": {$: "Nil"}}});
}));
}

function $f_rowpat$(_r_0) {
  return $kid$(run_loop($kid$(_r_0, 0)), 0);
}

function $ff_split$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, _next_0) {
  return $f_choose$(($f_eq$(($tg$(_c_0)), "Absent")), run_clo((_x_0) => {
  return {$: "FFlatten", "term": ($atom$("Efq")), "next": _next_0};
}), run_clo((_x_1) => {
  return $ff_fields_done$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, run_loop($ff_fields$(($ks$(_c_0)), ($f_mark_rows$(_rows_0, ($qt$(_v_0)))), _next_0)));
}));
}

function $ff_lam$(_v_0, _r_0) {
  const _body_0 = _r_0["term"];
  const _next_0 = _r_0["next"];
  return {$: "FFlatten", "term": ($kt$("Lam", ($nm$(_v_0)), ($ix$(_v_0)), ($qt$(_v_0)), {$: "Con", "head": _body_0, "tail": {$: "Nil"}})), "next": _next_0};
}

function $f_scope_parallel_valid$(_t_0, _pats_0, _env_0, _book_0, _err_0) {
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $kt$("Parallel", "", 0, 1, {$: "Con", "head": ($kt$("Patterns", "", 0, 1, _pats_0)), "tail": {$: "Con", "head": ($kt$("Values", "", 0, 1, ($f_scope_terms$(($ks$(run_loop($kid$(_t_0, 1)))), _env_0, _book_0)))), "tail": {$: "Con", "head": run_loop($f_scope_body$(run_loop($kid$(_t_0, 2)), ($f_pattern_env$(_pats_0, _env_0)), _book_0)), "tail": {$: "Nil"}}}});
}), run_clo((_x_1) => {
  return $kt$("Error", _err_0, 0, 0, {$: "Nil"});
}));
}

function $f_valid_patterns_mode$(_ps_0, _book_0, _names_0) {
  if (_ps_0.$ === "Nil") {
    return "";
  } else {
    const _p_0 = _ps_0["head"];
    const _rest_0 = _ps_0["tail"];
    return $f_valid_patterns_mode_next$(run_loop($f_valid_binding_pattern$(_p_0, _book_0, _names_0)), _rest_0, _book_0, _names_0);
  }
}

function $f_pattern_literal$(_s_0) {
  return $f_choose$(($String$ends_with$(_s_0, "n")), run_clo((_x_0) => {
  return $f_nat_pattern$(run_loop($f_pattern_number$(_s_0, 0)));
}), run_clo((_x_1) => {
  return $f_literal$(_s_0);
}));
}

function $f_scope_local_valid$(_t_0, _pats_0, _env_0, _book_0, _err_0) {
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $kt$("Local", "", 0, ($qt$(_t_0)), {$: "Con", "head": run_loop($terms_at$(_pats_0, 0)), "tail": {$: "Con", "head": run_loop($f_scope$(run_loop($kid$(_t_0, 1)), _env_0, _book_0)), "tail": {$: "Con", "head": run_loop($f_scope_body$(run_loop($kid$(_t_0, 2)), ($f_pattern_env$(_pats_0, _env_0)), _book_0)), "tail": {$: "Nil"}}}});
}), run_clo((_x_1) => {
  return $kt$("Error", _err_0, 0, 0, {$: "Nil"});
}));
}

function $f_valid_patterns$(_ps_0, _book_0) {
  return $f_valid_patterns_mode$(_ps_0, _book_0, false);
}

function $f_scope_row$(_r_0, _pats_0, _env_0, _book_0) {
  return $f_scope_row_valid$(_r_0, _pats_0, _env_0, _book_0, run_loop($f_valid_patterns$(_pats_0, _book_0)));
}

function $f_flat_column$(_h_0, _hs_0, _rows_0, _vars_0) {
  if (_vars_0.$ === "Nil") {
    return $kt$("Error", "match requires an unconsumed parameter or constructor field", 0, 0, {$: "Nil"});
  } else {
    const _v_0 = _vars_0["head"];
    const _vs_0 = _vars_0["tail"];
    const _x_0 = ($ix$(_h_0));
    const _x_1 = ($ix$(_v_0));
    return $f_choose$((_x_0 === _x_1), run_clo((_x_2) => {
  return $f_flat_split$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, run_loop($f_first_ctor$(_rows_0)));
}), run_clo((_x_3) => {
  return $kt$("Lam", ($nm$(_v_0)), ($ix$(_v_0)), ($qt$(_v_0)), {$: "Con", "head": run_loop($f_flat_match$({$: "Con", "head": _h_0, "tail": _hs_0}, _rows_0, _vs_0)), "tail": {$: "Nil"}});
}));
  }
}

function $f_flat_let$(_t_0, _vars_0, _body_0) {
  return $f_choose$(($f_eq$(($tg$(_body_0)), "Lam")), run_clo((_x_0) => {
  return $f_lbind$(_vars_0, ($kt$("Let", "", 0, 1, {$: "Con", "head": ($kt$("Bind", ($nm$(run_loop($kid$(_t_0, 0)))), ($ix$(run_loop($kid$(_t_0, 0)))), ($qt$(run_loop($kid$(_t_0, 0)))), {$: "Con", "head": run_loop($kid$(_t_0, 1)), "tail": {$: "Nil"}})), "tail": {$: "Con", "head": run_loop($kid$(_body_0, 0)), "tail": {$: "Nil"}}})));
}), run_clo((_x_1) => {
  return $kt$("Error", "a match cannot scrutinize a local binding", 0, 0, {$: "Nil"});
}));
}

function $sp_mint_body$(_d_0, _name_0, _ty_0, _r_0) {
  const _x_0 = ($da$(_d_0));
  const _x_1 = ($dx$(_d_0));
  return $sp_validate$(($sp_state$(_r_0)), {$: "KDef", "name": _name_0, "kind": "Def", "arity": ((_x_0 - _x_1) >>> 0), "templates": 0, "typ": _ty_0, "value": ($sp_value$(_r_0)), "ctors": {$: "Nil"}, "native": false, "unsafe": ($du$(_d_0))});
}

function $sp_shifts$(_ts_0, _offset_0) {
  if (_ts_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    return {$: "Con", "head": ($sp_shift$(_h_0, _offset_0)), "tail": ($sp_shifts$(_rest_0, _offset_0))};
  }
}

function $descend_sub$(_a_0, _ps_0, _bad_0, _index_0) {
  if (_ps_0.$ === "Nil") {
    return 2;
  } else {
    const _h_0 = _ps_0["head"];
    const _t_0 = _ps_0["tail"];
    return $kc$((_index_0 === _bad_0), run_clo((_x_0) => {
  return $descend_sub$(_a_0, _t_0, _bad_0, ((_index_0 + 1) >>> 0));
}), run_clo((_x_1) => {
  const _x_2 = run_loop($descend$(1, _a_0, _h_0));
  return $kc$((_x_2 === 2), run_clo((_x_3) => {
  return $descend_sub$(_a_0, _t_0, _bad_0, ((_index_0 + 1) >>> 0));
}), run_clo((_x_4) => {
  return 0;
}));
}));
  }
}

function $descend_field$(_a_0, _p_0, _ord_0, _index_0, _field_0) {
  return $kc$((_field_0 === 2), run_clo((_x_0) => {
  return {$: "KDescent", "order": 2, "bad": _index_0};
}), run_clo((_x_1) => {
  return $descend_fields$(_a_0, _p_0, run_loop($kc$((_field_0 === 1), run_clo((_x_2) => {
  return _ord_0;
}), run_clo((_x_3) => {
  return _field_0;
}))), ((_index_0 + 1) >>> 0));
}));
}

function $tele_check_legacy_head$(_e_0, _ctx_0, _tel_0, _h_0, _rest_0, _dem_0) {
  return $kc$(($String$eq$(($tg$(_tel_0)), "All")), run_clo((_x_0) => {
  return $tele_check_done$(run_loop($check$(_e_0, _ctx_0, _h_0, run_loop($qdem$(($qt$(_tel_0)), _dem_0)), run_loop($kid$(_tel_0, 0)))), run_loop($tele_check_legacy$(_e_0, _ctx_0, run_loop($subst$(run_loop($kid$(_tel_0, 1)), ($ix$(_tel_0)), _h_0)), _rest_0, _dem_0)));
}), run_clo((_x_1) => {
  return $bad$("too many telescope arguments");
}));
}

function $f_do_return$(_monad_0, _types_0, _position_0, _p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("FDo", _monad_0, _position_0, 1, {$: "Con", "head": ($kt$("ADT", _monad_0, _position_0, 1, _types_0)), "tail": {$: "Con", "head": _n_0, "tail": {$: "Nil"}}})), "rest": _ts_0};
}

function $f_do_statement$(_monad_0, _types_0, _p_0, _indent_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($Bool$and$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), ":")), ($f_eq$(($tg$(_n_0)), "Ref")))), ($f_alias_valid$(($nm$(_n_0)))))), run_clo((_x_0) => {
  return $f_do_annotated$(_monad_0, _types_0, _n_0, run_loop($f_expr$(($f_tl$(_ts_0)), 1)), _indent_0);
}), run_clo((_x_1) => {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "<-")), run_clo((_x_2) => {
  return $f_do_value$(_monad_0, _types_0, ($kt$("Ref", "_", ($ix$(_n_0)), 1, {$: "Nil"})), _n_0, false, run_loop($f_expr$(($f_tl$(_ts_0)), 0)), _indent_0);
}), run_clo((_x_3) => {
  const _x_4 = ($f_col$(run_loop($f_skip$(_ts_0))));
  const _x_5 = ($f_eq$(($f_tx$(_ts_0)), ";"));
  const _x_6 = (_x_4 === _indent_0);
  return $f_choose$(($Bool$and$((_x_5 || _x_6), ($Bool$not$(($f_eq$(($f_tx$(run_loop($f_skip$(_ts_0)))), "<eof>")))))), run_clo((_x_7) => {
  return $f_do_value$(_monad_0, _types_0, ($kt$("Ref", "_", ($ix$(_n_0)), 1, {$: "Nil"})), ($ref$("Unit")), false, {$: "FParsed", "term": _n_0, "rest": _ts_0}, _indent_0);
}), run_clo((_x_8) => {
  return {$: "FParsed", "term": ($kt$("FDo", _monad_0, ($ix$(_n_0)), 0, {$: "Con", "head": ($kt$("ADT", _monad_0, ($ix$(_n_0)), 1, _types_0)), "tail": {$: "Con", "head": _n_0, "tail": {$: "Nil"}}})), "rest": _ts_0};
}));
}));
}));
}

function $f_match_cases$(_ts_0, _indent_0, _heads_0, _rows_0) {
  const _x_0 = ($f_col$(_ts_0));
  return $f_choose$(($Bool$and$(($f_eq$(($f_tx$(_ts_0)), "case")), (_x_0 > _indent_0))), run_clo((_x_1) => {
  return $f_case_pats$(($f_tl$(_ts_0)), _indent_0, _heads_0, _rows_0, {$: "Nil"});
}), run_clo((_x_2) => {
  return {$: "FParsed", "term": ($kt$("Match", "", 0, 1, {$: "Con", "head": ($kt$("Heads", "", 0, 1, _heads_0)), "tail": ($List$reverse$(_rows_0))})), "rest": _ts_0};
}));
}

function $f_let_value$(_pat_0, _p_0) {
  const _v_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_let_body$(_pat_0, _v_0, run_loop($f_body$(_ts_0)));
}

function $f_typed_let_try$(_n_0, _old_0, _p_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "=")), run_clo((_x_0) => {
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Ref")), run_clo((_x_1) => {
  return $f_let_value$(_n_0, ($f_let_ann$(_ty_0, run_loop($f_expr$(($f_tl$(_ts_0)), 0)))));
}), run_clo((_x_2) => {
  return $f_err$(_ts_0, "a name (a parallel or typed let binds names; destructure in its body)");
}));
}), run_clo((_x_3) => {
  return {$: "FParsed", "term": _n_0, "rest": _old_0};
}));
}

function $f_statement_more$(_p_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Write")), run_clo((_x_0) => {
  return $f_write_statement$(_n_0, _ts_0);
}), run_clo((_x_1) => {
  const _x_2 = ($f_kind$(_ts_0));
  const _x_3 = (_x_2 === 1);
  const _x_4 = ($f_eq$(($f_tx$(_ts_0)), "+bind"));
  return $f_choose$((_x_3 || _x_4), run_clo((_x_5) => {
  return $f_parallel$(_ts_0, {$: "Con", "head": _n_0, "tail": {$: "Nil"}});
}), run_clo((_x_6) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}));
}));
}

function $f_power_depth$(_s_0, _n_0) {
  const _x_0 = ($String$is_empty$(_s_0));
  const _x_1 = ($f_eq$(_s_0, "n"));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return $f_power_bits$(_n_0, 0);
}), run_clo((_x_3) => {
  return $f_choose$(($Char$is_digit$(($f_head$(_s_0)))), run_clo((_x_4) => {
  const _x_5 = ($Char$to_u32$(($f_head$(_s_0))));
  const _x_6 = (Math.imul(_n_0, 10) >>> 0);
  const _x_7 = ((_x_5 - 48) >>> 0);
  return $f_power_depth$(($f_tail$(_s_0)), ((_x_6 + _x_7) >>> 0));
}), run_clo((_x_8) => {
  return $kt$("Error", "array count must be a literal power of two", 0, 0, {$: "Nil"});
}));
}));
}

function $f_nat_prefix$(_n_0, _b_0) {
  return $f_choose$((_n_0 === 0), run_clo((_x_0) => {
  return _b_0;
}), run_clo((_x_1) => {
  return $kt$("Ctr", "Succ", 0, 1, {$: "Con", "head": run_loop($f_nat_prefix$(((_n_0 - 1) >>> 0), _b_0)), "tail": {$: "Nil"}});
}));
}

function $f_decode_unicode$(_s_0, _code_0, _count_0) {
  return $f_choose$(($Bool$and$(($Char$is_eq$(($f_head$(_s_0)), "}")), (_count_0 > 0))), run_clo((_x_0) => {
  return {$: "FDecoded", "code": _code_0, "rest": ($f_tail$(_s_0)), "error": ""};
}), run_clo((_x_1) => {
  const _x_2 = run_loop($f_hex$(($f_head$(_s_0))));
  return $f_choose$(($Bool$and$((_x_2 < 16), (_count_0 < 6))), run_clo((_x_3) => {
  const _x_4 = (Math.imul(_code_0, 16) >>> 0);
  const _x_5 = run_loop($f_hex$(($f_head$(_s_0))));
  return $f_decode_unicode$(($f_tail$(_s_0)), ((_x_4 + _x_5) >>> 0), ((_count_0 + 1) >>> 0));
}), run_clo((_x_6) => {
  return {$: "FDecoded", "code": 0, "rest": _s_0, "error": "invalid Unicode escape"};
}));
}));
}

function $f_escape_valid$(_c_0) {
  const _x_0 = ($Char$is_eq$(_c_0, "n"));
  const _x_1 = ($Char$is_eq$(_c_0, "t"));
  const _x_2 = (_x_0 || _x_1);
  const _x_3 = ($Char$is_eq$(_c_0, "r"));
  const _x_4 = (_x_2 || _x_3);
  const _x_5 = ($Char$is_eq$(_c_0, "0"));
  const _x_6 = (_x_4 || _x_5);
  const _x_7 = ($Char$is_eq$(_c_0, "\\"));
  const _x_8 = (_x_6 || _x_7);
  const _x_9 = ($Char$is_eq$(_c_0, "'"));
  const _x_10 = (_x_8 || _x_9);
  const _x_11 = ($Char$is_eq$(_c_0, "\""));
  return (_x_10 || _x_11);
}

function $ff_fields_done$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, _r_0) {
  const _fields_0 = _r_0["fields"];
  const _next_0 = _r_0["next"];
  return $ff_hit_done$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, run_loop($ff_match$(($norm_join$(_fields_0, _hs_0)), run_loop($f_hit_rows$(_rows_0, _c_0, _fields_0, _v_0)), ($norm_join$(_fields_0, _vs_0)), _next_0)));
}

function $ff_fields$(_ps_0, _q_0, _next_0) {
  if (_ps_0.$ === "Nil") {
    return {$: "FFields", "fields": {$: "Nil"}, "next": _next_0};
  } else {
    const _p_0 = _ps_0["head"];
    const _rest_0 = _ps_0["tail"];
    return $f_choose$(($f_eq$(($tg$(_p_0)), "Var")), run_clo((_x_0) => {
  return $ff_field_cons$(($kt$("Var", ($nm$(_p_0)), ($ix$(_p_0)), run_loop($f_choose$((_q_0 === 2), run_clo((_x_1) => {
  return 2;
}), run_clo((_x_2) => {
  return $qt$(_p_0);
}))), {$: "Nil"})), run_loop($ff_fields$(_rest_0, _q_0, _next_0)));
}), run_clo((_x_3) => {
  const _x_4 = ($U32$show$(_next_0));
  return $ff_field_cons$(($kt$("Var", ("_" + _x_4), ((2147483648 + _next_0) >>> 0), _q_0, {$: "Nil"})), run_loop($ff_fields$(_rest_0, _q_0, ((_next_0 + 1) >>> 0))));
}));
  }
}

function $f_pattern_env$(_pats_0, _env_0) {
  return $norm_join$(($List$reverse$(run_loop($f_penv$(_pats_0)))), _env_0);
}

function $f_valid_patterns_mode_next$(_err_0, _ps_0, _book_0, _names_0) {
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $f_valid_patterns_mode$(_ps_0, _book_0, _names_0);
}), run_clo((_x_1) => {
  return _err_0;
}));
}

function $f_valid_binding_pattern$(_p_0, _book_0, _names_0) {
  return $f_choose$(_names_0, run_clo((_x_0) => {
  return $f_choose$(($f_eq$(($tg$(_p_0)), "Var")), run_clo((_x_1) => {
  return $f_valid_pattern$(_p_0, _book_0);
}), run_clo((_x_2) => {
  return "a parallel let binds names; destructure in its body";
}));
}), run_clo((_x_3) => {
  return $f_valid_pattern$(_p_0, _book_0);
}));
}

function $f_nat_pattern$(_n_0) {
  return $f_choose$((_n_0 === 0), run_clo((_x_0) => {
  return $kt$("Ctr", "Zero", 0, 1, {$: "Nil"});
}), run_clo((_x_1) => {
  return $kt$("Ctr", "Succ", 0, 1, {$: "Con", "head": run_loop($f_nat_pattern$(((_n_0 - 1) >>> 0))), "tail": {$: "Nil"}});
}));
}

function $f_pattern_number$(_s_0, _n_0) {
  const _x_0 = ($f_eq$(_s_0, "n"));
  const _x_1 = ($String$is_empty$(_s_0));
  return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return _n_0;
}), run_clo((_x_3) => {
  const _x_4 = ($Char$to_u32$(($f_head$(_s_0))));
  const _x_5 = (Math.imul(_n_0, 10) >>> 0);
  const _x_6 = ((_x_4 - 48) >>> 0);
  return $f_pattern_number$(($f_tail$(_s_0)), ((_x_5 + _x_6) >>> 0));
}));
}

function $f_scope_row_valid$(_r_0, _pats_0, _env_0, _book_0, _err_0) {
  return $f_choose$(($String$is_empty$(_err_0)), run_clo((_x_0) => {
  return $f_scoped_row$(_pats_0, run_loop($f_scope_body$(run_loop($kid$(_r_0, 1)), ($f_pattern_env$(_pats_0, _env_0)), _book_0)));
}), run_clo((_x_1) => {
  return $kt$("Row", "", 0, 1, {$: "Con", "head": ($kt$("Patterns", "", 0, 1, _pats_0)), "tail": {$: "Con", "head": ($kt$("Error", _err_0, 0, 0, {$: "Nil"})), "tail": {$: "Nil"}}});
}));
}

function $f_flat_split$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0) {
  return $f_choose$(($f_eq$(($tg$(_c_0)), "Absent")), run_clo((_x_0) => {
  return $atom$("Efq");
}), run_clo((_x_1) => {
  const _x_2 = ($ix$(_c_0));
  return $f_flat_fields$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, ($f_mark_fields$(($f_fresh_fields$(($ks$(_c_0)), ((2147483648 + _x_2) >>> 0))), ($f_mark_rows$(_rows_0, ($qt$(_v_0)))))));
}));
}

function $sp_validate$(_st_0, _d_0) {
  return $kc$(($String$eq$(($sp_error$(_st_0)), "")), run_clo((_x_0) => {
  return $sp_validate_done$(_st_0, _d_0, ($check_definition$(($sp_book$(_st_0)), _d_0)));
}), run_clo((_x_1) => {
  return {$: "KSpecTerm", "state": _st_0, "term": ($ref$(($dn$(_d_0))))};
}));
}

function $f_do_annotated$(_monad_0, _types_0, _binder_0, _p_0, _indent_0) {
  const _ty_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_ty_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _ty_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  const _x_2 = ($f_eq$(($f_tx$(_ts_0)), "="));
  const _x_3 = ($f_eq$(($f_tx$(_ts_0)), "<-"));
  return $f_choose$((_x_2 || _x_3), run_clo((_x_4) => {
  return $f_do_value$(_monad_0, _types_0, _binder_0, _ty_0, ($f_eq$(($f_tx$(_ts_0)), "=")), run_loop($f_expr$(($f_tl$(_ts_0)), 0)), _indent_0);
}), run_clo((_x_5) => {
  return $f_err$(_ts_0, "expected <-");
}));
}));
}

function $f_do_value$(_monad_0, _types_0, _binder_0, _ty_0, _pure_0, _p_0, _indent_0) {
  const _v_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_do_tail$(_monad_0, _types_0, _binder_0, _ty_0, _pure_0, _v_0, run_loop($f_do$(_monad_0, _types_0, run_loop($f_skip$(_ts_0)), _indent_0)));
}

function $f_case_pats$(_ts_0, _indent_0, _heads_0, _rows_0, _pats_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), ":")), run_clo((_x_0) => {
  const _x_1 = ($terms_len$(_pats_0));
  const _x_2 = ($terms_len$(_heads_0));
  return $f_choose$((_x_1 === _x_2), run_clo((_x_3) => {
  return $f_case_body$(run_loop($f_body_context$(($f_tl$(_ts_0)), ((_indent_0 + 1) >>> 0))), _indent_0, _heads_0, _rows_0, ($List$reverse$(_pats_0)));
}), run_clo((_x_4) => {
  const _x_5 = ($U32$show$(($terms_len$(_heads_0))));
  return $fpe_error$(_ts_0, "one pattern is required per match scrutinee", (_x_5 + " patterns (one per scrutinee)"));
}));
}), run_clo((_x_6) => {
  return $f_case_pat$(run_loop($f_expr$(run_loop($f_choose$(($f_eq$(($f_tx$(_ts_0)), ",")), run_clo((_x_7) => {
  return $f_tl$(_ts_0);
}), run_clo((_x_8) => {
  return _ts_0;
}))), 0)), _indent_0, _heads_0, _rows_0, _pats_0);
}));
}

function $f_let_body$(_pat_0, _v_0, _p_0) {
  const _b_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Local", "", 0, 1, {$: "Con", "head": _pat_0, "tail": {$: "Con", "head": _v_0, "tail": {$: "Con", "head": _b_0, "tail": {$: "Nil"}}}})), "rest": _ts_0};
}

function $f_let_ann$(_ty_0, _p_0) {
  const _v_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Ann", "", 0, 1, {$: "Con", "head": _v_0, "tail": {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}})), "rest": _ts_0};
}

function $f_write_statement$(_n_0, _ts_0) {
  const _x_0 = ($ix$(_n_0));
  const _x_1 = ($f_col$(run_loop($f_skip$(_ts_0))));
  const _x_2 = ((_x_0 & 65535) >>> 0);
  const _x_3 = ($f_eq$(($f_tx$(_ts_0)), ";"));
  const _x_4 = (_x_1 === _x_2);
  return $f_choose$(($Bool$and$((_x_3 || _x_4), ($Bool$not$(($f_eq$(($f_tx$(run_loop($f_skip$(_ts_0)))), "<eof>")))))), run_clo((_x_5) => {
  return $f_let_value$(($kt$("Ref", ($nm$(_n_0)), ($ix$(_n_0)), 1, {$: "Nil"})), {$: "FParsed", "term": run_loop($kid$(_n_0, 0)), "rest": _ts_0});
}), run_clo((_x_6) => {
  return {$: "FParsed", "term": run_loop($kid$(_n_0, 0)), "rest": _ts_0};
}));
}

function $f_parallel$(_ts_0, _pats_0) {
  return $f_choose$(($f_eq$(($f_tx$(_ts_0)), "=")), run_clo((_x_0) => {
  return $f_parallel_values$(($f_tl$(_ts_0)), ($List$reverse$(_pats_0)), ($terms_len$(_pats_0)), {$: "Nil"});
}), run_clo((_x_1) => {
  return $f_parallel_pat$(run_loop($f_expr$(_ts_0, 0)), _pats_0);
}));
}

function $f_power_bits$(_n_0, _d_0) {
  return $f_choose$((_n_0 === 1), run_clo((_x_0) => {
  return $f_nat$(_d_0);
}), run_clo((_x_1) => {
  const _x_2 = ((_n_0 & 1) >>> 0);
  const _x_3 = (_n_0 === 0);
  const _x_4 = (_x_2 === 1);
  return $f_choose$((_x_3 || _x_4), run_clo((_x_5) => {
  return $kt$("Error", "array count must be a positive power of two", 0, 0, {$: "Nil"});
}), run_clo((_x_6) => {
  return $f_power_bits$((1 >= 32 ? 0 : (_n_0 >>> 1) >>> 0), ((_d_0 + 1) >>> 0));
}));
}));
}

function $f_hex$(_c_0) {
  return $f_choose$(($Char$is_digit$(_c_0)), run_clo((_x_0) => {
  const _x_1 = ($Char$to_u32$(_c_0));
  return ((_x_1 - 48) >>> 0);
}), run_clo((_x_2) => {
  const _x_3 = ($Char$to_u32$(($Char$to_lower$(_c_0))));
  const _x_4 = ($Char$to_u32$(($Char$to_lower$(_c_0))));
  return $f_choose$(($Bool$and$((_x_3 >= 97), (_x_4 <= 102))), run_clo((_x_5) => {
  const _x_6 = ($Char$to_u32$(($Char$to_lower$(_c_0))));
  return ((_x_6 - 87) >>> 0);
}), run_clo((_x_7) => {
  return 16;
}));
}));
}

function $ff_hit_done$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, _r_0) {
  const _hit_0 = _r_0["term"];
  const _next_0 = _r_0["next"];
  return $ff_miss_done$(_c_0, _hit_0, run_loop($ff_match$({$: "Con", "head": _h_0, "tail": _hs_0}, run_loop($f_miss_rows$(_rows_0, ($nm$(_c_0)))), {$: "Con", "head": _v_0, "tail": _vs_0}, _next_0)));
}

function $f_hit_rows$(_rows_0, _c_0, _fields_0, _v_0) {
  if (_rows_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _r_0 = _rows_0["head"];
    const _rs_0 = _rows_0["tail"];
    const _x_0 = ($f_eq$(($tg$(run_loop($f_rowpat$(_r_0)))), "Var"));
    const _x_1 = ($f_eq$(($nm$(run_loop($f_rowpat$(_r_0)))), ($nm$(_c_0))));
    return $f_choose$((_x_0 || _x_1), run_clo((_x_2) => {
  return {$: "Con", "head": ($f_hit_row$(_r_0, _c_0, _fields_0, _v_0)), "tail": run_loop($f_hit_rows$(_rs_0, _c_0, _fields_0, _v_0))};
}), run_clo((_x_3) => {
  return $f_hit_rows$(_rs_0, _c_0, _fields_0, _v_0);
}));
  }
}

function $ff_field_cons$(_p_0, _r_0) {
  const _fields_0 = _r_0["fields"];
  const _next_0 = _r_0["next"];
  return {$: "FFields", "fields": {$: "Con", "head": _p_0, "tail": _fields_0}, "next": _next_0};
}

function $f_penv$(_xs_0) {
  if (_xs_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _x_0 = _xs_0["head"];
    const _xt_0 = _xs_0["tail"];
    return $f_choose$(($f_eq$(($tg$(_x_0)), "Var")), run_clo((_x_1) => {
  return {$: "Con", "head": _x_0, "tail": run_loop($f_penv$(_xt_0))};
}), run_clo((_x_2) => {
  return $norm_join$(run_loop($f_penv$(($ks$(_x_0)))), run_loop($f_penv$(_xt_0)));
}));
  }
}

function $f_valid_pattern$(_p_0, _book_0) {
  return $f_choose$(($f_eq$(($tg$(_p_0)), "Var")), run_clo((_x_0) => {
  return $f_choose$(($Bool$not$(($f_valid_name$(($nm$(_p_0)))))), run_clo((_x_1) => {
  const _x_2 = ($nm$(_p_0));
  return ("reserved pattern binder: " + _x_2);
}), run_clo((_x_3) => {
  return $f_choose$(($f_eq$(($dk$(run_loop($f_ctor_lookup$(($nm$(_p_0)), _book_0)))), "Missing")), run_clo((_x_4) => {
  return "";
}), run_clo((_x_5) => {
  const _x_6 = ($nm$(_p_0));
  return ("a constructor pattern requires braces: " + _x_6);
}));
}));
}), run_clo((_x_7) => {
  return $f_choose$(($f_eq$(($tg$(_p_0)), "Ctr")), run_clo((_x_8) => {
  return $f_valid_ctor_pattern$(_p_0, run_loop($f_ctor_lookup$(($nm$(_p_0)), _book_0)), _book_0);
}), run_clo((_x_9) => {
  return "expected a binder or constructor pattern";
}));
}));
}

function $f_scoped_row$(_pats_0, _body_0) {
  return $kt$("Row", "", 0, run_loop($f_choose$(($f_contains_var$(_body_0)), run_clo((_x_0) => {
  return 1;
}), run_clo((_x_1) => {
  return 0;
}))), {$: "Con", "head": ($kt$("Patterns", "", 0, 1, _pats_0)), "tail": {$: "Con", "head": _body_0, "tail": {$: "Nil"}}});
}

function $f_flat_fields$(_h_0, _hs_0, _rows_0, _v_0, _vs_0, _c_0, _fields_0) {
  return $kt$("Mat", ($nm$(_c_0)), 0, 1, {$: "Con", "head": run_loop($f_flat_match$(($norm_join$(_fields_0, _hs_0)), run_loop($f_hit_rows$(_rows_0, _c_0, _fields_0, _v_0)), ($norm_join$(_fields_0, _vs_0)))), "tail": {$: "Con", "head": run_loop($f_flat_match$({$: "Con", "head": _h_0, "tail": _hs_0}, run_loop($f_miss_rows$(_rows_0, ($nm$(_c_0)))), {$: "Con", "head": _v_0, "tail": _vs_0})), "tail": {$: "Nil"}}});
}

function $f_mark_fields$(_vars_0, _q_0) {
  if (_vars_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _v_0 = _vars_0["head"];
    const _vs_0 = _vars_0["tail"];
    return {$: "Con", "head": ($kt$("Var", ($nm$(_v_0)), ($ix$(_v_0)), run_loop($f_choose$((_q_0 === 2), run_clo((_x_0) => {
  return 2;
}), run_clo((_x_1) => {
  return $qt$(_v_0);
}))), {$: "Nil"})), "tail": ($f_mark_fields$(_vs_0, _q_0))};
  }
}

function $f_fresh_fields$(_ps_0, _id_0) {
  if (_ps_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _p_0 = _ps_0["head"];
    const _rest_0 = _ps_0["tail"];
    return {$: "Con", "head": run_loop($f_choose$(($f_eq$(($tg$(_p_0)), "Var")), run_clo((_x_0) => {
  return _p_0;
}), run_clo((_x_1) => {
  return $kt$("Var", "_field", _id_0, 1, {$: "Nil"});
}))), "tail": ($f_fresh_fields$(_rest_0, ((_id_0 + 1) >>> 0)))};
  }
}

function $sp_validate_done$(_st_0, _d_0, _error_0) {
  return $kc$(($String$eq$(_error_0, "")), run_clo((_x_0) => {
  return {$: "KSpecTerm", "state": {$: "KSpecState", "book": {$: "Con", "head": _d_0, "tail": run_loop($index_remove$(($sp_book$(_st_0)), ($dn$(_d_0))))}, "memo": ($sp_done_memo$(($sp_memo$(_st_0)), ($dn$(_d_0)))), "serial": ($sp_serial$(_st_0)), "fresh": ($sp_fresh$(_st_0)), "error": ($sp_error$(_st_0)), "templates": ($sp_templates$(_st_0))}, "term": ($ref$(($dn$(_d_0))))};
}), run_clo((_x_1) => {
  const _x_2 = ($dn$(_d_0));
  const _x_3 = (": " + _error_0);
  return {$: "KSpecTerm", "state": ($sp_fail$(_st_0, (_x_2 + _x_3))), "term": ($ref$(($dn$(_d_0))))};
}));
}

function $check_definition$(_book_0, _d_0) {
  return $ce$(run_loop($check_definition_result$(_book_0, _d_0)));
}

function $f_do_tail$(_monad_0, _types_0, _binder_0, _ty_0, _pure_0, _v_0, _p_0) {
  const _body_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": run_loop($f_choose$(_pure_0, run_clo((_x_0) => {
  return $kt$("Local", "Do", 0, 1, {$: "Con", "head": _binder_0, "tail": {$: "Con", "head": ($kt$("Ann", "", 0, 1, {$: "Con", "head": _v_0, "tail": {$: "Con", "head": _ty_0, "tail": {$: "Nil"}}})), "tail": {$: "Con", "head": _body_0, "tail": {$: "Nil"}}}});
}), run_clo((_x_1) => {
  return $kt$("FDo", _monad_0, ($ix$(_binder_0)), 2, {$: "Con", "head": ($kt$("ADT", _monad_0, ($ix$(_binder_0)), 1, _types_0)), "tail": {$: "Con", "head": _ty_0, "tail": {$: "Con", "head": _v_0, "tail": {$: "Con", "head": ($kt$("Lam", ($nm$(_binder_0)), ($ix$(_binder_0)), ($qt$(_binder_0)), {$: "Con", "head": _body_0, "tail": {$: "Nil"}})), "tail": {$: "Nil"}}}}});
}))), "rest": _ts_0};
}

function $f_case_body$(_p_0, _indent_0, _heads_0, _rows_0, _pats_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_match_cases$(run_loop($f_skip$(_ts_0)), _indent_0, _heads_0, {$: "Con", "head": ($kt$("Row", "", 0, 1, {$: "Con", "head": ($kt$("Patterns", "", 0, 1, _pats_0)), "tail": {$: "Con", "head": _n_0, "tail": {$: "Nil"}}})), "tail": _rows_0});
}));
}

function $f_case_pat$(_p_0, _indent_0, _heads_0, _rows_0, _pats_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_case_pats$(_ts_0, _indent_0, _heads_0, _rows_0, {$: "Con", "head": _n_0, "tail": _pats_0});
}));
}

function $f_parallel_values$(_ts_0, _pats_0, _left_0, _vals_0) {
  return $f_choose$((_left_0 === 0), run_clo((_x_0) => {
  return $f_parallel_body$(_pats_0, ($List$reverse$(_vals_0)), run_loop($f_body$(_ts_0)));
}), run_clo((_x_1) => {
  return $f_parallel_value$(run_loop($f_expr$(_ts_0, 0)), _pats_0, _left_0, _vals_0);
}));
}

function $f_parallel_pat$(_p_0, _pats_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_parallel$(_ts_0, {$: "Con", "head": _n_0, "tail": _pats_0});
}));
}

function $ff_miss_done$(_c_0, _hit_0, _r_0) {
  const _miss_0 = _r_0["term"];
  const _next_0 = _r_0["next"];
  return {$: "FFlatten", "term": ($kt$("Mat", ($nm$(_c_0)), 0, 1, {$: "Con", "head": _hit_0, "tail": {$: "Con", "head": _miss_0, "tail": {$: "Nil"}}})), "next": _next_0};
}

function $f_miss_rows$(_rows_0, _name_0) {
  if (_rows_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _r_0 = _rows_0["head"];
    const _rs_0 = _rows_0["tail"];
    return $f_choose$(($Bool$and$(($f_eq$(($tg$(run_loop($f_rowpat$(_r_0)))), "Ctr")), ($f_eq$(($nm$(run_loop($f_rowpat$(_r_0)))), _name_0)))), run_clo((_x_0) => {
  return $f_miss_rows$(_rs_0, _name_0);
}), run_clo((_x_1) => {
  return {$: "Con", "head": _r_0, "tail": run_loop($f_miss_rows$(_rs_0, _name_0))};
}));
  }
}

function $f_hit_row$(_r_0, _c_0, _fields_0, _v_0) {
  const _x_2 = ($qt$(_r_0));
  return $kt$("Row", "", 0, ($qt$(_r_0)), {$: "Con", "head": ($kt$("Patterns", "", 0, 1, ($norm_join$(run_loop($f_choose$(($f_eq$(($tg$(run_loop($f_rowpat$(_r_0)))), "Var")), run_clo((_x_0) => {
  return _fields_0;
}), run_clo((_x_1) => {
  return $ks$(run_loop($f_rowpat$(_r_0)));
}))), ($f_tail_terms$(($ks$(run_loop($kid$(_r_0, 0)))))))))), "tail": {$: "Con", "head": run_loop($f_choose$((_x_2 === 0), run_clo((_x_3) => {
  return $kid$(_r_0, 1);
}), run_clo((_x_4) => {
  return $f_sub$(run_loop($f_choose$(($f_eq$(($tg$(run_loop($f_rowpat$(_r_0)))), "Var")), run_clo((_x_5) => {
  return $f_sub$(run_loop($kid$(_r_0, 1)), ($ix$(run_loop($f_rowpat$(_r_0)))), _v_0);
}), run_clo((_x_6) => {
  return $kid$(_r_0, 1);
}))), ($ix$(_v_0)), ($kt$("Ctr", ($nm$(_c_0)), 0, 1, _fields_0)));
}))), "tail": {$: "Nil"}}});
}

function $f_valid_ctor_pattern$(_p_0, _ctr_0, _book_0) {
  return $f_choose$(($f_eq$(($dk$(_ctr_0)), "Missing")), run_clo((_x_0) => {
  const _x_1 = ($nm$(_p_0));
  return ("unknown constructor pattern: " + _x_1);
}), run_clo((_x_2) => {
  const _x_3 = ($da$(_ctr_0));
  const _x_4 = ($terms_len$(($ks$(_p_0))));
  return $f_choose$((_x_3 === _x_4), run_clo((_x_5) => {
  return $f_valid_patterns$(($ks$(_p_0)), _book_0);
}), run_clo((_x_6) => {
  const _x_7 = ($nm$(_p_0));
  return ("constructor pattern field count differs: " + _x_7);
}));
}));
}

function $f_contains_var$(_t_0) {
  const _x_0 = ($f_eq$(($tg$(_t_0)), "Var"));
  const _x_1 = ($f_contains_var_terms$(($ks$(_t_0))));
  return (_x_0 || _x_1);
}

function $sp_done_memo$(_ms_0, _name_0) {
  if (_ms_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ms_0["head"];
    const _rest_0 = _ms_0["tail"];
    return {$: "Con", "head": run_loop($kc$(($String$eq$(($sp_mname$(_h_0)), _name_0)), run_clo((_x_0) => {
  return {$: "KSpecMemo", "template": ($sp_mtemplate$(_h_0)), "key": ($sp_mkey$(_h_0)), "name": ($sp_mname$(_h_0)), "active": false};
}), run_clo((_x_1) => {
  return _h_0;
}))), "tail": ($sp_done_memo$(_rest_0, _name_0))};
  }
}

function $f_parallel_body$(_pats_0, _vals_0, _p_0) {
  const _body_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return {$: "FParsed", "term": ($kt$("Parallel", "", 0, 1, {$: "Con", "head": ($kt$("Patterns", "", 0, 1, _pats_0)), "tail": {$: "Con", "head": ($kt$("Values", "", 0, 1, _vals_0)), "tail": {$: "Con", "head": _body_0, "tail": {$: "Nil"}}}})), "rest": _ts_0};
}

function $f_parallel_value$(_p_0, _pats_0, _left_0, _vals_0) {
  const _n_0 = _p_0["term"];
  const _ts_0 = _p_0["rest"];
  return $f_choose$(($f_eq$(($tg$(_n_0)), "Error")), run_clo((_x_0) => {
  return {$: "FParsed", "term": _n_0, "rest": _ts_0};
}), run_clo((_x_1) => {
  return $f_parallel_values$(_ts_0, _pats_0, ((_left_0 - 1) >>> 0), {$: "Con", "head": _n_0, "tail": _vals_0});
}));
}

function $f_contains_var_terms$(_ts_0) {
  if (_ts_0.$ === "Nil") {
    return false;
  } else {
    const _t_0 = _ts_0["head"];
    const _rest_0 = _ts_0["tail"];
    const _x_0 = ($f_contains_var$(_t_0));
    const _x_1 = ($f_contains_var_terms$(_rest_0));
    return (_x_0 || _x_1);
  }
}
export default {
  "f_parse": run_lib((a0) => { const r = (run_loop($f_parse$((a0)))); (a0); return r; }, 1),
  "f_load": run_lib((a0, a1) => { const r = (run_loop($f_load$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_path_join": run_lib((a0, a1) => { const r = (run_loop($f_path_join$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_path_dir": run_lib((a0) => { const r = (run_loop($f_path_dir$((a0)))); (a0); return r; }, 1),
  "check_book": run_lib((a0) => { const r = (run_loop($check_book$((a0)))); (a0); return r; }, 1),
  "annotate_book": run_lib((a0) => { const r = (run_loop($annotate_book$((a0)))); (a0); return r; }, 1),
  "j_program": run_lib((a0) => { const r = (run_loop($j_program$((a0)))); (a0); return r; }, 1),
  "j_library": run_lib((a0) => { const r = (run_loop($j_library$((a0)))); (a0); return r; }, 1),
  "j_expr": run_lib((a0, a1, a2, a3, a4) => { const r = (run_loop($j_expr$((a0), (a1), (a2), (a3), (a4)))); (a0); (a1); (a2); (a3); (a4); return r; }, 5),
  "j_descriptor": run_lib((a0, a1, a2) => { const r = (run_loop($j_descriptor$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),
  "j_io_type": run_lib((a0, a1) => { const r = (run_loop($j_io_type$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "j_modules": run_lib((a0, a1) => { const r = (run_loop($j_modules$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "driver_has_main": run_lib((a0) => { const r = (run_loop($driver_has_main$((a0)))); (a0); return r; }, 1),
  "driver_is_io": run_lib((a0) => { const r = (run_loop($driver_is_io$((a0)))); (a0); return r; }, 1),
  "driver_interpret": run_lib((a0) => { const r = (run_loop($driver_interpret$((a0)))); (a0); return r; }, 1),
  "driver_todos": run_lib((a0) => { const r = (run_loop($driver_todos$((a0)))); (a0); return r; }, 1),
  "driver_emit_owned": run_lib((a0) => { const r = (run_loop($driver_emit_owned$((a0)))); (a0); return r; }, 1),
  "specialize_book": run_lib((a0) => { const r = (run_loop($specialize_book$((a0)))); (a0); return r; }, 1),
  "specialized_book": run_lib((a0) => { const r = (run_loop($specialized_book$((a0)))); (a0); return r; }, 1),
  "specialized_error": run_lib((a0) => { const r = (run_loop($specialized_error$((a0)))); (a0); return r; }, 1),
  "nc_compile": run_lib((a0, a1, a2) => { const r = (run_loop($nc_compile$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),
  "nc_foreign_paths": run_lib((a0) => { const r = (run_loop($nc_foreign_paths$((a0)))); (a0); return r; }, 1),
  "nc_annotation_stops": run_lib((a0) => { const r = (run_loop($nc_annotation_stops$((a0)))); (a0); return r; }, 1),
  "nc_annotated_context": run_lib((a0, a1) => { const r = (run_loop($nc_annotated_context$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "nc_foreign_source": run_lib((a0, a1, a2, a3, a4) => { const r = (run_loop($nc_foreign_source$((a0), (a1), (a2), (a3), (a4)))); (a0); (a1); (a2); (a3); (a4); return r; }, 5),
  "nc_foreign_scope": run_lib((a0) => { const r = (run_loop($nc_foreign_scope$((a0)))); (a0); return r; }, 1),
  "check_from_exact_prefix": run_lib((a0, a1) => { const r = (run_loop($check_from_exact_prefix$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "exact_prefix": run_lib((a0, a1) => { const r = (run_loop($exact_prefix$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_load_graph": run_lib((a0, a1) => { const r = (run_loop($f_load_graph$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_main_names": run_lib((a0, a1) => { const r = (run_loop($f_main_names$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_load_graph_trace": run_lib((a0, a1) => { const r = (run_loop($f_load_graph_trace$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_source_parsed": run_lib((a0, a1, a2, a3) => { const r = (run_loop($f_source_parsed$((a0), (a1), (a2), (a3)))); (a0); (a1); (a2); (a3); return r; }, 4),
  "book_context": run_lib((a0) => { const r = (run_loop($book_context$((a0)))); (a0); return r; }, 1),
  "book_cached": run_lib((a0, a1) => { const r = (run_loop($book_cached$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_load_graph_seed": run_lib((a0, a1, a2, a3, a4) => { const r = (run_loop($f_load_graph_seed$((a0), (a1), (a2), (a3), (a4)))); (a0); (a1); (a2); (a3); (a4); return r; }, 5),
  "f_load_graph_seed_trace": run_lib((a0, a1, a2, a3, a4) => { const r = (run_loop($f_load_graph_seed_trace$((a0), (a1), (a2), (a3), (a4)))); (a0); (a1); (a2); (a3); (a4); return r; }, 5),
  "driver_report": run_lib((a0, a1) => { const r = (run_loop($driver_report$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "driver_bad_names": run_lib((a0) => { const r = (run_loop($driver_bad_names$((a0)))); (a0); return r; }, 1),
  "compiler_check_result_abi": run_lib(() => { const r = (run_loop($compiler_check_result_abi$()));  return r; }, 0),
  "check_book_diagnostic": run_lib((a0, a1) => { const r = (run_loop($check_book_diagnostic$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "check_book_diagnostic_from_exact_prefix": run_lib((a0, a1, a2) => { const r = (run_loop($check_book_diagnostic_from_exact_prefix$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),
  "diagnostic_render": run_lib((a0) => { const r = (run_loop($diagnostic_render$((a0)))); (a0); return r; }, 1),
  "diagnostic_result_locate": run_lib((a0, a1) => { const r = (run_loop($diagnostic_result_locate$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "f_load_origins_for": run_lib((a0, a1, a2) => { const r = (run_loop($f_load_origins_for$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),
  "f_loaded_origins_for": run_lib((a0, a1) => { const r = (run_loop($f_loaded_origins_for$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "j_compile_error": run_lib((a0) => { const r = (run_loop($j_compile_error$((a0)))); (a0); return r; }, 1),
  "j_layout_error": run_lib((a0, a1, a2, a3) => { const r = (run_loop($j_layout_error$((a0), (a1), (a2), (a3)))); (a0); (a1); (a2); (a3); return r; }, 4),
  "reach_book": run_lib((a0, a1, a2) => { const r = (run_loop($reach_book$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),
  "j_roots": run_lib((a0, a1) => { const r = (run_loop($j_roots$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "j_stops": run_lib((a0) => { const r = (run_loop($j_stops$((a0)))); (a0); return r; }, 1),
  "annotate_except": run_lib((a0, a1) => { const r = (run_loop($annotate_except$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "kf_source": run_lib((a0, a1, a2, a3) => { const r = (run_loop($kf_source$((a0), (a1), (a2), (a3)))); (a0); (a1); (a2); (a3); return r; }, 4),
  "annotate_selected": run_lib((a0, a1, a2) => { const r = (run_loop($annotate_selected$((a0), (a1), (a2)))); (a0); (a1); (a2); return r; }, 3),
  "j_program_selected": run_lib((a0, a1) => { const r = (run_loop($j_program_selected$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "j_library_selected": run_lib((a0, a1) => { const r = (run_loop($j_library_selected$((a0), (a1)))); (a0); (a1); return r; }, 2),
  "j_foreign_paths": run_lib((a0) => { const r = (run_loop($j_foreign_paths$((a0)))); (a0); return r; }, 1),
  "j_foreign_error": run_lib((a0) => { const r = (run_loop($j_foreign_error$((a0)))); (a0); return r; }, 1),
};
