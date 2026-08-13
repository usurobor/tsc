(* test_coh_min — stdlib-only assertions (no ppx; the contract forbids it).
   `dune runtest` runs this; a non-zero exit fails the build, and `make gate`
   depends on it.

   WHAT THIS FILE IS FOR, AND WHAT THE MAKEFILE IS FOR. The gate's shell targets
   run the SHIPPED methodologies end to end and vet the artifacts they emit —
   that is where "two structurally different CMs run through one binary" is
   demonstrated. This file proves the criteria that a subprocess cannot reach:
   the algebra's semantics, the load-time refusals, the linker's obligations,
   the provider-contract enforcement on the success path, scheduling
   independence, and the digest-binding negatives. Between them every criterion
   has an executable check; none is verified by reading the code.

   FIXTURE DISCIPLINE. Every negative below is DERIVED from one canonical
   document by changing exactly one thing — [without], [set_in], [replace_step].
   A negative fixture that differs from the positive in one field is evidence; a
   hand-retyped one is not, because it can fail for a reason nobody intended.

   The IRs here are built in-code rather than read from `examples/`, so the test
   is self-contained and does not depend on the example tree's layout. The
   shipped IRs are gated separately, and against the real contracts, by
   `make vet-ir`. *)

module J = Coh_min.Json
module Jread = Coh_min.Jread
module Value = Coh_min.Value
module Rule = Coh_min.Rule
module Ir = Coh_min.Ir
module P = Coh_min.Provider
module Request = Coh_min.Request
module Plan = Coh_min.Plan
module Linker = Coh_min.Linker
module Exec = Coh_min.Exec
module Receipt = Coh_min.Receipt
module R = Coh_min.Runner

let failures = ref 0
let checks = ref 0

let check name cond =
  incr checks;
  if cond then Printf.printf "ok   - %s\n" name
  else (incr failures; Printf.printf "FAIL - %s\n" name)

let is_error = function Error _ -> true | Ok _ -> false

(* A refusal must not merely happen — it must SAY what happened. Every negative
   asserts on the message as well as on the failure, so a refusal that starts
   firing for an unrelated reason is caught. *)
let contains (needle : string) (haystack : string) : bool =
  let n = String.length needle and h = String.length haystack in
  let rec scan i = i + n <= h && (String.sub haystack i n = needle || scan (i + 1)) in
  n = 0 || scan 0

let refuses name ~saying r =
  incr checks;
  match r with
  | Error msg when contains saying msg -> Printf.printf "ok   - %s\n" name
  | Error msg ->
    incr failures;
    Printf.printf "FAIL - %s (refused, but message lacks %S: %s)\n" name saying msg
  | Ok _ -> incr failures; Printf.printf "FAIL - %s (was ADMITTED)\n" name

(* ────────────────────── JSON surgery for one-field negatives ─────────── *)

let obj_of = function J.Obj kvs -> kvs | _ -> []

let without (key : string) (j : J.t) : J.t = J.Obj (List.remove_assoc key (obj_of j))

let set_field (key : string) (v : J.t) (j : J.t) : J.t =
  J.Obj ((key, v) :: List.remove_assoc key (obj_of j))

let get (key : string) (j : J.t) : J.t =
  match List.assoc_opt key (obj_of j) with Some v -> v | None -> J.Null

(* Change one field of a nested object, addressed by a path. *)
let rec set_in (path : string list) (v : J.t) (j : J.t) : J.t =
  match path with
  | [] -> v
  | [ k ] -> set_field k v j
  | k :: rest -> set_field k (set_in rest v (get k j)) j

let rec drop_in (path : string list) (j : J.t) : J.t =
  match path with
  | [] -> j
  | [ k ] -> without k j
  | k :: rest -> set_field k (drop_in rest (get k j)) j

(* Replace the step whose `id` is [sid], leaving every other step untouched. *)
let replace_step (sid : string) (f : J.t -> J.t) (ir : J.t) : J.t =
  let steps =
    match get "steps" ir with
    | J.Arr xs ->
      J.Arr (List.map (fun s -> if get "id" s = J.Str sid then f s else s) xs)
    | other -> other
  in
  set_field "steps" steps ir

(* ─────────────────────────── the canonical IR ────────────────────────── *)

(* A three-step methodology with the shape issue AC3 requires: two INDEPENDENT
   steps, one DEPENDENT step binding another step's declared output port, and a
   reachable principled skip when that port is lawfully withheld. It mirrors the
   shipped `example.repo-legibility` without being it — the shipped one is
   gated by `make gate`, this one by the assertions below. *)
let base_ir_text = {json|
{
  "format": "tsc-cm-ir/0.2",
  "cm": {
    "id": "test.legibility",
    "version": "0.1",
    "source_digest": "sha256:0000000000000000000000000000000000000000000000000000000000000000"
  },
  "question": "Does the subject present a readable entry document under a licence?",
  "inputs": {
    "repository": {
      "kind": "directory",
      "schema": "tsc://schema/directory-artifact/0.1",
      "required": true
    }
  },
  "steps": [
    {
      "id": "readme_locate",
      "kind": "mechanical",
      "checker": { "capability": "fs.file-exists", "interface": "tsc-checker/0.1" },
      "inputs": {
        "root": {
          "from": { "input": "repository" },
          "schema": "tsc://schema/directory-artifact/0.1"
        }
      },
      "outputs": {
        "present": { "schema": "tsc://schema/boolean/0.1", "required": true },
        "path": { "schema": "tsc://schema/relative-path/0.1", "required": false }
      },
      "config": { "relative_path": "README.md" },
      "evidence": {
        "schema": "tsc://schema/file-observation/0.1",
        "required": true,
        "predicates": ["exists", "size_bytes"]
      },
      "capabilities": { "request": ["subject.fs.read"] },
      "bounds": { "wall_time_ms": 1000, "output_bytes": 4096 },
      "failure_policy": {
        "incomplete": "fact_unavailable",
        "refused": "fact_unavailable",
        "failed": "run_failed"
      }
    },
    {
      "id": "license_locate",
      "kind": "mechanical",
      "checker": { "capability": "fs.file-exists", "interface": "tsc-checker/0.1" },
      "inputs": {
        "root": {
          "from": { "input": "repository" },
          "schema": "tsc://schema/directory-artifact/0.1"
        }
      },
      "outputs": {
        "present": { "schema": "tsc://schema/boolean/0.1", "required": true }
      },
      "config": { "relative_path": "LICENSE" },
      "evidence": {
        "schema": "tsc://schema/file-observation/0.1",
        "required": true,
        "predicates": ["exists"]
      },
      "capabilities": { "request": ["subject.fs.read"] },
      "bounds": { "wall_time_ms": 1000, "output_bytes": 4096 },
      "failure_policy": {
        "incomplete": "fact_unavailable",
        "refused": "fact_unavailable",
        "failed": "run_failed"
      }
    },
    {
      "id": "readme_depth",
      "kind": "mechanical",
      "checker": { "capability": "fs.text-metrics", "interface": "tsc-checker/0.1" },
      "inputs": {
        "root": {
          "from": { "input": "repository" },
          "schema": "tsc://schema/directory-artifact/0.1"
        },
        "target": {
          "from": { "step": "readme_locate", "output": "path" },
          "schema": "tsc://schema/relative-path/0.1"
        }
      },
      "outputs": {
        "line_count": { "schema": "tsc://schema/integer/0.1", "required": true },
        "non_empty": { "schema": "tsc://schema/boolean/0.1", "required": true }
      },
      "config": { "max_bytes": 65536 },
      "evidence": {
        "schema": "tsc://schema/text-metrics-observation/0.1",
        "required": true,
        "predicates": ["checked_path", "read_bytes"]
      },
      "capabilities": { "request": ["subject.fs.read"] },
      "bounds": { "wall_time_ms": 2000, "output_bytes": 65536 },
      "failure_policy": {
        "incomplete": "fact_unavailable",
        "refused": "fact_unavailable",
        "failed": "run_failed"
      }
    }
  ],
  "result": {
    "classes": ["LEGIBLE", "SHALLOW", "NO_ENTRY_DOC", "INCOMPLETE"],
    "rules": [
      {
        "id": "no-entry-doc",
        "when": { "eq": [{ "fact": "readme_locate.present" }, false] },
        "emit": "NO_ENTRY_DOC"
      },
      {
        "id": "depth-unavailable",
        "when": { "not": { "step_status": ["readme_depth", "success"] } },
        "emit": "INCOMPLETE"
      },
      {
        "id": "legible",
        "when": {
          "and": [
            { "ge": [{ "fact": "readme_depth.line_count" }, 5] },
            { "eq": [{ "fact": "license_locate.present" }, true] }
          ]
        },
        "emit": "LEGIBLE"
      }
    ],
    "default": { "id": "shallow", "emit": "SHALLOW" },
    "obligations": [
      { "class": "LEGIBLE", "requires": ["evidence.readme_depth", "evidence.license_locate"] }
    ]
  },
  "receipt": {
    "family": "repository_measurement",
    "schema": "tsc://receipt/repository-measurement/0.1",
    "reports": ["readme_locate.present", "readme_depth.line_count"],
    "measure_only": true
  },
  "permissions": {
    "capabilities": ["subject.fs.read"],
    "bounds": { "wall_time_ms": 10000, "output_bytes": 65536 }
  }
}
|json}

let base_ir () : J.t = J.parse base_ir_text

let load (j : J.t) = Ir.of_json j

(* The canonical IR as a loaded value. Named [loaded_ir] rather than [base] so
   it cannot be shadowed by the [base] temp-directory parameter the end-to-end
   tests thread through. *)
let loaded_ir () = match load (base_ir ()) with
  | Ok ir -> ir
  | Error e -> failwith ("the canonical test IR must load, got: " ^ e)

(* ─────────────────────────── temp-dir scaffolding ────────────────────── *)

let mkdir_p path = if not (Sys.file_exists path) then Sys.mkdir path 0o755

let write_file path contents =
  let oc = open_out_bin path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc contents)

(* A stdlib-only unique temp dir: temp_file mints a unique name, which we
   replace with a directory (no Unix.getpid — the contract forbids Unix). *)
let temp_dir () =
  let base = Filename.temp_file "coh_min_test_" "" in
  Sys.remove base;
  mkdir_p base;
  base

let ir_seq = ref 0

let write_ir base (j : J.t) =
  incr ir_seq;
  let path = Filename.concat base (Printf.sprintf "ir-%d.json" !ir_seq) in
  write_file path (J.document j);
  path

let run_ir ~base ~subject (j : J.t) =
  R.run { R.ir_path = write_ir base j; request_path = None;
          locators = [ ("repository", subject) ] }

let class_of (o : R.outputs) =
  J.to_string (J.member "class" (J.member "result" o.R.receipt))

let rule_of (o : R.outputs) =
  J.to_string (J.member "rule_id" (J.member "result" o.R.receipt))

(* ══════════════════════ 1. path confinement (pure) ════════════════════ *)

let test_confine () =
  let admit rel = P.confine ~root:"/subject" ~rel in
  check "confine admits README.md" (admit "README.md" = Ok "/subject/README.md");
  check "confine admits nested docs/README.md"
    (admit "docs/README.md" = Ok "/subject/docs/README.md");
  check "confine denies empty" (is_error (admit ""));
  check "confine denies absolute /etc/passwd" (is_error (admit "/etc/passwd"));
  check "confine denies leading ../" (is_error (admit "../secret"));
  check "confine denies interior a/../../b" (is_error (admit "a/../../b"));
  check "confine denies bare .." (is_error (admit ".."));
  check "confine admits ..README (not a segment)"
    (admit "..README" = Ok "/subject/..README")

(* ══════════════════════ 2. the v0 result algebra ══════════════════════ *)

(* A fact set built by hand, so the algebra is tested without a filesystem. *)
let env_of ~outputs ~predicates ~statuses : Rule.env = {
  Rule.output = (fun sid port -> List.assoc_opt (sid, port) outputs);
  Rule.predicate = (fun sid p -> List.assoc_opt (sid, p) predicates);
  Rule.status = (fun sid -> List.assoc_opt sid statuses);
}

let eval_text env text =
  match Rule.expr_of_json ~ctx:"t." (J.parse text) with
  | Error e -> Error e
  | Ok expr -> Rule.eval env expr

let test_algebra () =
  let env =
    env_of
      ~outputs:[ (("a", "n"), Value.Int 7); (("a", "flag"), Value.Bool true);
                 (("a", "name"), Value.Str "readme") ]
      ~predicates:[ (("a", "size"), Value.Int 120) ]
      ~statuses:[ ("a", "success"); ("b", "skipped") ]
  in
  let yes name text = check name (eval_text env text = Ok true) in
  let no name text = check name (eval_text env text = Ok false) in
  yes "eq int" {|{"eq":[{"fact":"a.n"},7]}|};
  no  "eq int (false)" {|{"eq":[{"fact":"a.n"},8]}|};
  yes "ne int" {|{"ne":[{"fact":"a.n"},8]}|};
  yes "eq bool" {|{"eq":[{"fact":"a.flag"},true]}|};
  yes "eq string" {|{"eq":[{"fact":"a.name"},"readme"]}|};
  yes "lt" {|{"lt":[{"fact":"a.n"},8]}|};
  yes "le (equal)" {|{"le":[{"fact":"a.n"},7]}|};
  yes "gt" {|{"gt":[{"fact":"a.n"},6]}|};
  yes "ge (equal)" {|{"ge":[{"fact":"a.n"},7]}|};
  no  "ge (false)" {|{"ge":[{"fact":"a.n"},8]}|};
  yes "string ordering" {|{"lt":[{"fact":"a.name"},"zzz"]}|};
  yes "and" {|{"and":[{"eq":[{"fact":"a.n"},7]},{"eq":[{"fact":"a.flag"},true]}]}|};
  no  "and (one false)" {|{"and":[{"eq":[{"fact":"a.n"},7]},{"eq":[{"fact":"a.flag"},false]}]}|};
  yes "or" {|{"or":[{"eq":[{"fact":"a.n"},1]},{"eq":[{"fact":"a.flag"},true]}]}|};
  yes "not" {|{"not":{"eq":[{"fact":"a.n"},1]}}|};
  yes "evidence predicate" {|{"eq":[{"evidence":"a.size"},120]}|};
  yes "present (available)" {|{"present":{"fact":"a.n"}}|};
  no  "present (unavailable)" {|{"present":{"fact":"a.missing"}}|};
  yes "step_status success" {|{"step_status":["a","success"]}|};
  yes "step_status skipped" {|{"step_status":["b","skipped"]}|};
  no  "step_status of an unrun step" {|{"step_status":["zz","success"]}|};
  (* An UNAVAILABLE fact makes a comparison false rather than an error: "the
     line count is at least 5" is well-posed with answer "no" when no line count
     was produced. `present` is the predicate that observes it directly. *)
  no  "comparison over an unavailable fact is false, not an error"
    {|{"ge":[{"fact":"a.missing"},1]}|};
  (* A type mismatch between two AVAILABLE facts is a methodology fault and is
     REFUSED, not answered. *)
  refuses "ordered comparison across types is refused"
    ~saying:"ordered comparison"
    (eval_text env {|{"lt":[{"fact":"a.name"},5]}|});
  (* Parse-level refusals: the algebra is closed. *)
  refuses "unknown operator is refused at parse"
    ~saying:"unknown operator"
    (Rule.expr_of_json ~ctx:"t." (J.parse {|{"xor":[1,2]}|}));
  refuses "two operators in one expression are refused"
    ~saying:"exactly one operator"
    (Rule.expr_of_json ~ctx:"t." (J.parse {|{"eq":[1,1],"ne":[1,2]}|}));
  refuses "a misspelled reference is not silently a literal"
    ~saying:"reference must be"
    (Rule.expr_of_json ~ctx:"t." (J.parse {|{"eq":[{"factt":"a.n"},1]}|}));
  refuses "eq with three operands is refused"
    ~saying:"exactly two operands"
    (Rule.expr_of_json ~ctx:"t." (J.parse {|{"eq":[1,2,3]}|}))

(* Ordered first-match + a mandatory default, and the exactness of the witness. *)
let test_rule_table () =
  let env =
    env_of ~outputs:[ (("a", "n"), Value.Int 7) ] ~predicates:[]
      ~statuses:[ ("a", "success") ] in
  let table text =
    match Rule.of_json (J.parse text) with
    | Ok t -> t
    | Error e -> failwith ("test table must parse: " ^ e)
  in
  let t = table {|{
    "classes": ["A","B","C"],
    "rules": [
      {"id":"first","when":{"eq":[{"fact":"a.n"},1]},"emit":"A"},
      {"id":"second","when":{"eq":[{"fact":"a.n"},7]},"emit":"B"},
      {"id":"third","when":{"eq":[{"fact":"a.n"},7]},"emit":"C"}
    ],
    "default": {"id":"fallback","emit":"C"},
    "obligations": []
  }|} in
  (match Rule.derive env t with
   | Ok d ->
     check "first match wins (not the last, not the default)"
       (d.Rule.emitted_class = "B" && d.Rule.matched_rule = "second");
     (* The witness is EXACT: evaluation does not short-circuit, so every
        reference in the clauses that were evaluated appears, and no reference
        from an unevaluated clause does. Rules `first` and `second` were
        evaluated; `third` was not — and all three name the same reference, so
        the witness is one entry either way. Deduplication is what keeps that
        readable. *)
     check "witness carries the facts the evaluated clauses read"
       (List.length d.Rule.witness = 1
        && Rule.reference_to_string (List.hd d.Rule.witness).Rule.read_reference = "a.n"
        && (List.hd d.Rule.witness).Rule.read_value = Some (Value.Int 7))
   | Error e -> check ("derive should succeed, got " ^ e) false);
  (* Totality: no rule matches, the default fires, and its declared id is what
     the receipt will carry. *)
  let t2 = table {|{
    "classes": ["A","B"],
    "rules": [{"id":"never","when":{"eq":[{"fact":"a.n"},99]},"emit":"A"}],
    "default": {"id":"otherwise","emit":"B"},
    "obligations": []
  }|} in
  (match Rule.derive env t2 with
   | Ok d ->
     check "no rule matches -> the default emits, naming its own rule id"
       (d.Rule.emitted_class = "B" && d.Rule.matched_rule = "otherwise")
   | Error e -> check ("default derive should succeed, got " ^ e) false);
  (* AC6 result honesty, at LOAD. *)
  refuses "a rule table with no default is refused" ~saying:"result.default is missing"
    (Rule.of_json (J.parse {|{"classes":["A"],"rules":[],"obligations":[]}|}));
  refuses "a rule emitting an undeclared class is refused" ~saying:"does not declare"
    (Rule.of_json (J.parse {|{
       "classes":["A"],
       "rules":[{"id":"r","when":{"present":{"fact":"a.n"}},"emit":"Z"}],
       "default":{"id":"d","emit":"A"},"obligations":[]}|}));
  refuses "a DEFAULT emitting an undeclared class is refused" ~saying:"does not declare"
    (Rule.of_json (J.parse {|{
       "classes":["A"],"rules":[],
       "default":{"id":"d","emit":"Z"},"obligations":[]}|}));
  refuses "an empty class vocabulary is refused" ~saying:"declares no result class"
    (Rule.of_json (J.parse {|{
       "classes":[],"rules":[],"default":{"id":"d","emit":"A"},"obligations":[]}|}));
  refuses "duplicate rule ids are refused" ~saying:"duplicate rule id"
    (Rule.of_json (J.parse {|{
       "classes":["A"],
       "rules":[{"id":"r","when":{"present":{"fact":"a.n"}},"emit":"A"},
                {"id":"r","when":{"present":{"fact":"a.n"}},"emit":"A"}],
       "default":{"id":"d","emit":"A"},"obligations":[]}|}));
  refuses "an obligation naming an undeclared class is refused" ~saying:"does not declare"
    (Rule.of_json (J.parse {|{
       "classes":["A"],"rules":[],"default":{"id":"d","emit":"A"},
       "obligations":[{"class":"Z","requires":["evidence.a"]}]}|}))

(* ═════════════════ 3. IR load-time refusals (AC5, AC8, AC12) ══════════ *)

let test_canonical_blocks () =
  (* Table-driven over the SAME list the validator and the CUE contract derive
     from, so adding a canonical block automatically adds its regression. *)
  List.iter
    (fun block ->
       refuses
         (Printf.sprintf "IR missing canonical block %S is refused" block)
         ~saying:block
         (load (without block (base_ir ()))))
    Ir.canonical_blocks;
  refuses "an IR whose `format` is not the 0.2 pin is refused"
    ~saying:"is not the NormalizedCMIR format"
    (load (set_field "format" (J.Str "tsc-cm-ir/0.1") (base_ir ())));
  refuses "an IR carrying an undeclared top-level field is refused"
    ~saying:"undeclared field"
    (load (set_field "procedure" (J.Obj []) (base_ir ())));
  refuses "an IR declaring no step is refused" ~saying:"declares no work"
    (load (set_field "steps" (J.Arr []) (base_ir ())));
  refuses "an IR declaring no subject input is refused" ~saying:"declares no subject input"
    (load (set_field "inputs" (J.Obj []) (base_ir ())));
  refuses "an empty governing question is refused" ~saying:"measures nothing"
    (load (set_field "question" (J.Str "  ") (base_ir ())));
  refuses "a non-mechanical step kind is refused (FLAT execution)"
    ~saying:"not executable by this runtime"
    (load (replace_step "readme_depth" (set_field "kind" (J.Str "invoke_cm")) (base_ir ())));
  refuses "duplicate step ids are refused" ~saying:"duplicate step id"
    (load (replace_step "license_locate" (set_field "id" (J.Str "readme_locate")) (base_ir ())))

let test_graph_refusals () =
  refuses "an input binding an undeclared CM input is refused"
    ~saying:"which `inputs` does not declare"
    (load (replace_step "readme_locate"
             (set_in [ "inputs"; "root"; "from" ] (J.Obj [ "input", J.Str "elsewhere" ]))
             (base_ir ())));
  refuses "an input binding a non-existent step is refused" ~saying:"does not exist"
    (load (replace_step "readme_depth"
             (set_in [ "inputs"; "target"; "from" ]
                (J.Obj [ "step", J.Str "ghost"; "output", J.Str "path" ]))
             (base_ir ())));
  refuses "an input binding an undeclared output port is refused"
    ~saying:"does not declare as an output port"
    (load (replace_step "readme_depth"
             (set_in [ "inputs"; "target"; "from" ]
                (J.Obj [ "step", J.Str "readme_locate"; "output", J.Str "nope" ]))
             (base_ir ())));
  refuses "a step binding its own output is refused" ~saying:"binds its own output"
    (load (replace_step "readme_depth"
             (set_in [ "inputs"; "target"; "from" ]
                (J.Obj [ "step", J.Str "readme_depth"; "output", J.Str "line_count" ]))
             (base_ir ())));
  refuses "a cyclic graph is refused" ~saying:"cyclic"
    (load (replace_step "readme_locate"
             (set_in [ "inputs"; "root"; "from" ]
                (J.Obj [ "step", J.Str "readme_depth"; "output", J.Str "line_count" ]))
             (base_ir ())));
  refuses "a step with no output port is refused" ~saying:"declares no port"
    (load (replace_step "license_locate" (set_field "outputs" (J.Obj [])) (base_ir ())))

(* AC5 — fact provenance. The discriminating property: these are refused at
   LOAD, before any provider runs, so a rule reaching for an undeclared fact
   cannot be discovered by whichever subject happens to reach that clause. *)
let test_provenance () =
  let with_first_rule guard ir =
    set_in [ "result"; "rules" ]
      (match get "rules" (get "result" ir) with
       | J.Arr (r :: rest) -> J.Arr (set_field "when" (J.parse guard) r :: rest)
       | other -> other)
      ir
  in
  refuses "a rule reading an undeclared output port is refused at load"
    ~saying:"does not declare as an output port"
    (load (with_first_rule {|{"eq":[{"fact":"readme_locate.size"},1]}|} (base_ir ())));
  refuses "a rule reading a fact of a non-existent step is refused at load"
    ~saying:"no step"
    (load (with_first_rule {|{"eq":[{"fact":"ghost.present"},true]}|} (base_ir ())));
  refuses "a rule reading an undeclared evidence predicate is refused at load"
    ~saying:"does not declare"
    (load (with_first_rule {|{"eq":[{"evidence":"readme_locate.mtime"},1]}|} (base_ir ())));
  refuses "a rule testing a status outside the closed set is refused at load"
    ~saying:"closed status set"
    (load (with_first_rule {|{"step_status":["readme_locate","maybe"]}|} (base_ir ())));
  refuses "a rule testing the status of a non-existent step is refused at load"
    ~saying:"not declared"
    (load (with_first_rule {|{"step_status":["ghost","success"]}|} (base_ir ())));
  refuses "a receipt report naming an undeclared fact is refused at load"
    ~saying:"does not declare as an output port"
    (load (set_in [ "receipt"; "reports" ]
             (J.Arr [ J.Str "readme_locate.mtime" ]) (base_ir ())));
  (* A DECLARED evidence predicate is a lawful rule input — the invariant says
     "declared typed step output OR declared evidence predicate", and a test
     that only proved the refusals would not show the permission. *)
  check "a rule reading a DECLARED evidence predicate loads"
    (match load (with_first_rule {|{"eq":[{"evidence":"readme_locate.size_bytes"},1]}|}
                   (base_ir ())) with Ok _ -> true | Error _ -> false);
  refuses "a step requesting capability outside the CM envelope is refused"
    ~saying:"outside the CM's declared permissions"
    (load (replace_step "readme_depth"
             (set_in [ "capabilities"; "request" ]
                (J.Arr [ J.Str "subject.fs.read"; J.Str "subject.net.read" ]))
             (base_ir ())));
  refuses "a step declaring bounds above the CM ceiling is refused"
    ~saying:"above the CM ceiling"
    (load (replace_step "readme_depth"
             (set_in [ "bounds"; "output_bytes" ] (J.Int 999999)) (base_ir ())));
  refuses "a failure_policy naming a result class is refused"
    ~saying:"never to a result class"
    (load (replace_step "readme_depth"
             (set_in [ "failure_policy"; "failed" ] (J.Str "INCOMPLETE")) (base_ir ())))

(* ══════════════ 4. link-time refusals (AC11 and link safety) ══════════ *)

(* A dedicated empty subject for the link tests. Deliberately NOT the process
   temp directory: `directory-merkle/0.1` digests every regular file reachable
   from the root, so pointing it at a shared /tmp would make the linker tests
   depend on whatever else the host happens to have there. *)
let link_root = lazy (
  let d = Filename.concat (temp_dir ()) "empty-subject" in
  mkdir_p d;
  d)

let link_of (j : J.t) =
  match Ir.of_json j with
  | Error e -> Error e
  | Ok ir ->
    (match Request.synthesize ir ~ir_digest:("sha256:" ^ String.make 64 '0')
             ~locators:[ ("repository", Lazy.force link_root) ] with
     | Error e -> Error e
     | Ok (rq, _) -> Linker.link ir rq ~request_digest:("sha256:" ^ String.make 64 '1')
                     |> Result.map (fun _ -> ()))

let test_link_safety () =
  check "the canonical IR links" (link_of (base_ir ()) = Ok ());
  (* Gate 11: the CAPABILITY owns the config schema, and a config that does not
     validate refuses at LINK time rather than reaching the provider. *)
  refuses "config of the wrong type refuses at link"
    ~saying:"declares it as integer"
    (link_of (replace_step "readme_depth"
                (set_in [ "config"; "max_bytes" ] (J.Str "big")) (base_ir ())));
  refuses "config missing a required capability field refuses at link"
    ~saying:"config is missing"
    (link_of (replace_step "readme_depth" (drop_in [ "config"; "max_bytes" ]) (base_ir ())));
  refuses "config carrying a field the capability does not declare refuses at link"
    ~saying:"widen nothing and narrow nothing"
    (link_of (replace_step "readme_depth"
                (set_in [ "config"; "depth" ] (J.Int 2)) (base_ir ())));
  refuses "config below a declared floor refuses at link"
    ~saying:"declares it as integer >= 1"
    (link_of (replace_step "readme_depth"
                (set_in [ "config"; "max_bytes" ] (J.Int 0)) (base_ir ())));
  (* Path confinement is a CONFIG TYPE, so an escaping literal is refused
     statically — which is what keeps "zero receipt bytes" true. *)
  refuses "an escaping relative_path refuses at link, before anything runs"
    ~saying:"could escape the subject root"
    (link_of (replace_step "readme_locate"
                (set_in [ "config"; "relative_path" ] (J.Str "../README.md")) (base_ir ())));
  refuses "an unregistered capability refuses at link"
    ~saying:"no provider is registered"
    (link_of (replace_step "readme_depth"
                (set_in [ "checker"; "capability" ] (J.Str "fs.nope")) (base_ir ())));
  refuses "a checker interface mismatch refuses at link" ~saying:"implements"
    (link_of (replace_step "readme_depth"
                (set_in [ "checker"; "interface" ] (J.Str "tsc-checker/9.9")) (base_ir ())));
  (* Requiredness compatibility: a methodology may declare a WITHHOLDABLE port
     optional, but may not assert a promise the capability never made. *)
  refuses "declaring a withholdable port required refuses at link"
    ~saying:"may lawfully withhold it"
    (link_of (replace_step "readme_locate"
                (set_in [ "outputs"; "path"; "required" ] (J.Bool true)) (base_ir ())));
  refuses "an undeclared output port refuses at link" ~saying:"does not publish"
    (link_of (replace_step "license_locate"
                (set_in [ "outputs"; "colour" ]
                   (J.Obj [ "schema", J.Str "tsc://schema/boolean/0.1" ])) (base_ir ())));
  refuses "an output schema mismatch refuses at link" ~saying:"publishes it as"
    (link_of (replace_step "license_locate"
                (set_in [ "outputs"; "present"; "schema" ] (J.Str "tsc://schema/int/9")) (base_ir ())));
  refuses "an evidence schema mismatch refuses at link" ~saying:"produces"
    (link_of (replace_step "license_locate"
                (set_in [ "evidence"; "schema" ] (J.Str "tsc://schema/other/0.1")) (base_ir ())));
  refuses "an evidence predicate the capability never emits refuses at link"
    ~saying:"does not emit"
    (link_of (replace_step "license_locate"
                (set_in [ "evidence"; "predicates" ] (J.Arr [ J.Str "mtime" ])) (base_ir ())));
  refuses "an unbound capability slot refuses at link" ~saying:"unbound"
    (link_of (replace_step "readme_depth" (drop_in [ "inputs"; "target" ]) (base_ir ())));
  refuses "binding a subject input into a value slot refuses at link"
    ~saying:"a value slot takes another step's output port"
    (link_of (replace_step "readme_depth"
                (set_in [ "inputs"; "target"; "from" ] (J.Obj [ "input", J.Str "repository" ]))
                (base_ir ())));
  (* MISSING and EXCESS capability are BOTH errors. *)
  refuses "a step requesting fewer capabilities than its provider needs refuses"
    ~saying:"are missing"
    (link_of (replace_step "readme_depth"
                (set_in [ "capabilities"; "request" ] (J.Arr [])) (base_ir ())))

(* Excess capability against the REQUEST ceiling (as opposed to the CM
   envelope, which [test_provenance] covers) needs a narrowed request. *)
let test_request_ceiling () =
  match Ir.of_json (base_ir ()) with
  | Error e -> check ("base IR must load: " ^ e) false
  | Ok ir ->
    (match Request.synthesize ir ~ir_digest:("sha256:" ^ String.make 64 '0')
             ~locators:[ ("repository", Lazy.force link_root) ] with
     | Error e -> check ("synthesize must succeed: " ^ e) false
     | Ok (rq, _) ->
       let narrowed = { rq with Request.capability_ceiling = [] } in
       refuses "a step outside the run request's capability_ceiling refuses at link"
         ~saying:"excess capability is an error"
         (Linker.link ir narrowed ~request_digest:("sha256:" ^ String.make 64 '1')
          |> Result.map (fun _ -> ()));
       let widened =
         { rq with Request.capability_ceiling = [ "subject.fs.read"; "subject.net.read" ] } in
       refuses "a request offering capability the CM does not declare refuses at link"
         ~saying:"the CM's permissions do not declare"
         (Linker.link ir widened ~request_digest:("sha256:" ^ String.make 64 '1')
          |> Result.map (fun _ -> ())))

(* ═══════════ 5. provider contract enforcement on the success path ═════ *)

let step_named sid (ir : Ir.t) =
  match Ir.find_step ir sid with
  | Some s -> s
  | None -> failwith ("no step " ^ sid)

let test_outcome_contract () =
  let ir = loaded_ir () in
  let locate = step_named "readme_locate" ir in
  let ok_outcome ports = {
    P.out_status = P.Success;
    out_ports = ports;
    out_evidence = [ "exists", Value.Bool true; "size_bytes", Value.Int 12 ];
    out_diagnostics = [];
  } in
  (* AC6, third clause: a PROVIDER-SUPPLIED result field is never authoritative.
     A provider publishing a port the methodology did not declare has it
     DROPPED — the fact set contains only what the step declared, so no rule can
     read it (provenance already refuses naming it) and no receipt field can
     carry it. *)
  (match Exec.accept_success locate
           (ok_outcome [ "present", Value.Bool true; "path", Value.Str "README.md";
                         "result_class", Value.Str "README_PRESENT" ]) with
   | Ok (published, _) ->
     check "a provider-supplied result field is dropped, never authoritative"
       (not (List.mem_assoc "result_class" published));
     check "declared ports survive the projection"
       (List.assoc_opt "present" published = Some (Value.Bool true))
   | Error e -> check ("projection should succeed, got " ^ e) false);
  (* A success missing a REQUIRED output is rejected, not downgraded. *)
  refuses "a success missing a required output is rejected, not downgraded"
    ~saying:"rejected, not downgraded"
    (Exec.accept_success locate (ok_outcome [ "path", Value.Str "README.md" ]));
  (* An absent OPTIONAL output is lawful withholding, and is RECORDED. *)
  (match Exec.accept_success locate (ok_outcome [ "present", Value.Bool false ]) with
   | Ok (published, withheld) ->
     check "an absent optional output is lawful withholding, recorded as withheld"
       (withheld = [ "path" ] && List.length published = 1)
   | Error e -> check ("withholding should be lawful, got " ^ e) false);
  (* Declared-required evidence must actually arrive. *)
  refuses "a success omitting a declared required evidence predicate is rejected"
    ~saying:"omits"
    (Exec.accept_success locate
       { (ok_outcome [ "present", Value.Bool true ]) with P.out_evidence = [] })

(* ═════════════════ 6. end to end, both branches (AC3) ════════════════ *)

let rich_subject base =
  let d = Filename.concat base "rich" in
  mkdir_p d;
  write_file (Filename.concat d "README.md")
    "# rich\n\nline\n- a\n- b\n- c\n\nend\n";
  write_file (Filename.concat d "LICENSE") "MIT\n";
  d

let bare_subject base =
  let d = Filename.concat base "bare" in
  mkdir_p d;
  write_file (Filename.concat d ".keep") "";
  d

let thin_subject base =
  let d = Filename.concat base "thin" in
  mkdir_p d;
  write_file (Filename.concat d "README.md") "# thin\n";
  write_file (Filename.concat d "LICENSE") "MIT\n";
  d

let trace_of (o : R.outputs) = J.to_list (J.member "trace" o.R.receipt)

let entry_for sid o =
  List.find_opt (fun e -> J.member_opt "step_id" e = Some (J.Str sid)) (trace_of o)

let test_end_to_end base =
  let rich = rich_subject base and bare = bare_subject base and thin = thin_subject base in
  (* DEPENDENCY SATISFIED. *)
  (match run_ir ~base ~subject:rich (base_ir ()) with
   | Ok o ->
     check "dependency satisfied -> LEGIBLE via the `legible` rule"
       (class_of o = "LEGIBLE" && rule_of o = "legible");
     check "the dependent step ran"
       (match entry_for "readme_depth" o with
        | Some e -> J.member_opt "status" e = Some (J.Str "success")
        | None -> false)
   | Error e -> check ("rich run should succeed, got: " ^ e) false);
  (* DEPENDENCY UNSATISFIABLE — the principled-skip branch. *)
  (match run_ir ~base ~subject:bare (base_ir ()) with
   | Ok o ->
     check "dependency unsatisfiable -> NO_ENTRY_DOC (first matching rule)"
       (class_of o = "NO_ENTRY_DOC" && rule_of o = "no-entry-doc");
     (match entry_for "readme_locate" o with
      | Some e ->
        check "the withholding step is a SUCCESS that recorded `path` as withheld"
          (J.member_opt "status" e = Some (J.Str "success")
           && J.to_list (J.member "withheld" e) = [ J.Str "path" ])
      | None -> check "readme_locate must appear in the trace" false);
     (match entry_for "readme_depth" o with
      | Some e ->
        check "the dependent step is a principled skip"
          (J.member_opt "status" e = Some (J.Str "skipped"));
        (* THE POINT OF THE WHOLE BRANCH: the trace NAMES the unpublished
           port. A skip that does not say what it waited on is not
           principled, and no value is fabricated in its place. *)
        let why = match J.member_opt "skipped_because" e with
          | Some (J.Str s) -> s | _ -> "" in
        check "the skip names the unpublished port `readme_locate.path`"
          (contains "readme_locate.path" why);
        check "the skipped step published nothing"
          (J.to_list (J.member "published" e) = [])
      | None -> check "readme_depth must appear in the trace" false)
   | Error e -> check ("bare run should succeed, got: " ^ e) false);
  (* The third and fourth classes, so the vocabulary is exercised, not just
     declared. *)
  (match run_ir ~base ~subject:thin (base_ir ()) with
   | Ok o -> check "a shallow entry document -> SHALLOW via the default"
               (class_of o = "SHALLOW" && rule_of o = "shallow")
   | Error e -> check ("thin run should succeed, got: " ^ e) false);
  (match run_ir ~base ~subject:rich
           (replace_step "readme_depth"
              (set_in [ "config"; "max_bytes" ] (J.Int 8)) (base_ir ())) with
   | Ok o ->
     check "a bound the checker cannot meet -> refused -> INCOMPLETE"
       (class_of o = "INCOMPLETE" && rule_of o = "depth-unavailable");
     check "the refused step is recorded as `refused`, not as a failure"
       (match entry_for "readme_depth" o with
        | Some e -> J.member_opt "status" e = Some (J.Str "refused")
        | None -> false)
   | Error e -> check ("tight run should succeed, got: " ^ e) false);
  (* INPUT SENSITIVITY: the receipts differ, because a real provider read the
     disk. *)
  (match run_ir ~base ~subject:rich (base_ir ()), run_ir ~base ~subject:thin (base_ir ()) with
   | Ok a, Ok b ->
     check "two subjects produce different receipts"
       (J.document a.R.receipt <> J.document b.R.receipt)
   | _ -> check "both runs should produce receipts" false);
  (* DETERMINISM: the same subject twice produces byte-identical receipts.
     Without this the sensitivity check above would be satisfied by noise. *)
  (match run_ir ~base ~subject:rich (base_ir ()), run_ir ~base ~subject:rich (base_ir ()) with
   | Ok a, Ok b ->
     check "the same subject produces a byte-identical receipt"
       (J.document a.R.receipt = J.document b.R.receipt)
   | _ -> check "both determinism runs should produce receipts" false);
  (rich, bare)

(* Gate 2: observable results must not depend on scheduling order. The steps are
   REVERSED in the IR — so the scheduler meets them in a different order — and
   the derived class, matched rule and published fact set must be unchanged. *)
let test_scheduling_independence base rich =
  let reversed =
    let ir = base_ir () in
    set_field "steps" (match get "steps" ir with J.Arr xs -> J.Arr (List.rev xs) | o -> o) ir
  in
  match run_ir ~base ~subject:rich (base_ir ()), run_ir ~base ~subject:rich reversed with
  | Ok a, Ok b ->
    let facts o =
      List.sort compare
        (List.concat_map
           (fun e ->
              let sid = J.to_string (J.member "step_id" e) in
              List.map
                (fun p -> (sid, J.to_string (J.member "port" p), J.document (J.member "value" p)))
                (J.to_list (J.member "published" e)))
           (trace_of o))
    in
    check "permuting the IR's step order does not change the result class"
      (class_of a = class_of b && rule_of a = rule_of b);
    check "permuting the IR's step order does not change the published fact set"
      (facts a = facts b);
    check "the trace records the ACTUAL order, which does differ"
      (List.map (fun e -> J.to_string (J.member "step_id" e)) (trace_of a)
       <> List.map (fun e -> J.to_string (J.member "step_id" e)) (trace_of b))
  | _ -> check "both scheduling runs should produce receipts" false

(* ══════════════ 7. warrant obligations (evidence honesty) ═════════════ *)

let test_obligations base rich =
  (* The shipped table's LEGIBLE obligation is discharged on a rich subject. *)
  (match run_ir ~base ~subject:rich (base_ir ()) with
   | Ok o ->
     let obs = J.to_list (J.member "obligations" o.R.receipt) in
     check "the emitted class's obligations are recorded and discharged"
       (List.length obs = 2
        && List.for_all (fun x -> J.member_opt "discharged" x = Some (J.Bool true)) obs)
   | Error e -> check ("obligation run should succeed, got " ^ e) false);
  (* An UNKNOWN obligation is never treated as discharged, so inventing a
     stronger-sounding requirement makes the class unclaimable rather than
     free. *)
  refuses "an unknown warrant obligation is not discharged, and refuses the run"
    ~saying:"not in the v0 obligation catalog"
    (run_ir ~base ~subject:rich
       (set_in [ "result"; "obligations" ]
          (J.Arr [ J.Obj [ "class", J.Str "LEGIBLE";
                           "requires", J.Arr [ J.Str "oracle.commit_before_reveal" ] ] ])
          (base_ir ()))
     |> Result.map (fun _ -> ()));
  (* An obligation whose evidence this run did not retain refuses too. *)
  refuses "a strong class whose required evidence is absent is refused"
    ~saying:"did not discharge"
    (run_ir ~base ~subject:rich
       (set_in [ "result"; "obligations" ]
          (J.Arr [ J.Obj [ "class", J.Str "LEGIBLE";
                           "requires", J.Arr [ J.Str "evidence.ghost_step" ] ] ])
          (base_ir ()))
     |> Result.map (fun _ -> ()))

(* ════════════ 8. RunRequest: subject identity, not location (AC9) ════ *)

let test_run_request rich bare =
  let ir = loaded_ir () in
  let d = "sha256:" ^ String.make 64 '0' in
  let synth root =
    match Request.synthesize ir ~ir_digest:d ~locators:[ ("repository", root) ] with
    | Ok (rq, _) -> Some rq
    | Error _ -> None
  in
  (match synth rich, synth bare with
   | Some a, Some b ->
     check "different subjects give different snapshot digests"
       ((List.hd a.Request.subject).Request.subject_digest
        <> (List.hd b.Request.subject).Request.subject_digest);
     check "every subject entry names a versioned scheme"
       (List.for_all
          (fun (e : Request.subject_entry) ->
             e.Request.subject_scheme = "directory-merkle/0.1")
          a.Request.subject)
   | _ -> check "both syntheses should succeed" false);
  (* The digest is of CONTENT, so it changes when the content does — and is
     stable when it does not. *)
  (match synth rich, synth rich with
   | Some a, Some b ->
     check "the same bytes give the same snapshot digest"
       ((List.hd a.Request.subject).Request.subject_digest
        = (List.hd b.Request.subject).Request.subject_digest)
   | _ -> check "repeat synthesis should succeed" false);
  let before = synth rich in
  write_file (Filename.concat rich "EXTRA.md") "new file\n";
  let after = synth rich in
  (match before, after with
   | Some a, Some b ->
     check "adding a file to the subject changes the snapshot digest"
       ((List.hd a.Request.subject).Request.subject_digest
        <> (List.hd b.Request.subject).Request.subject_digest)
   | _ -> check "digest-change synthesis should succeed" false);
  Sys.remove (Filename.concat rich "EXTRA.md");
  (* An authored request is VERIFIED against the artifacts it binds. *)
  (match synth rich with
   | None -> check "synthesis for verification should succeed" false
   | Some rq ->
     check "a matching request verifies"
       (match Request.verify rq ~ir_digest:d ~locators:[ ("repository", rich) ] with
        | Ok _ -> true | Error _ -> false);
     refuses "a request whose subject digest does not match the bytes refuses"
       ~saying:"but the bytes at"
       (Request.verify rq ~ir_digest:d ~locators:[ ("repository", bare) ]
        |> Result.map (fun _ -> ()));
     refuses "a request binding a different IR digest refuses"
       ~saying:"but the loaded IR canonicalizes to"
       (Request.verify rq ~ir_digest:("sha256:" ^ String.make 64 'a')
          ~locators:[ ("repository", rich) ] |> Result.map (fun _ -> ()));
     (* The scheme requirement, both halves. *)
     let doc = Request.to_json rq in
     let strip_scheme j =
       set_in [ "subject" ]
         (J.Obj (List.map (fun (k, v) -> (k, without "scheme" v))
                   (obj_of (get "subject" j)))) j
     in
     refuses "a subject entry with no scheme refuses fail-closed"
       ~saying:"must name a versioned snapshot/digest scheme"
       (Request.of_json (strip_scheme doc) |> Result.map (fun _ -> ()));
     let bad_scheme j =
       set_in [ "subject" ]
         (J.Obj (List.map (fun (k, v) -> (k, set_field "scheme" (J.Str "git-tree/0.1") v))
                   (obj_of (get "subject" j)))) j
     in
     refuses "an unrecognized scheme refuses fail-closed" ~saying:"is not recognized"
       (Request.of_json (bad_scheme doc) |> Result.map (fun _ -> ()));
     refuses "an unknown profile refuses rather than being ignored"
       ~saying:"v0 defines exactly one profile"
       (Request.of_json (set_field "profile" (J.Str "fast") doc)
        |> Result.map (fun _ -> ()));
     refuses "an uninterpreted run parameter refuses rather than being ignored"
       ~saying:"v0 interprets no run parameter"
       (Request.of_json (set_field "parameters" (J.Obj [ "depth", J.Int 2 ]) doc)
        |> Result.map (fun _ -> ()));
     (* Table-driven over the canonical blocks, as for the IR. *)
     List.iter
       (fun block ->
          refuses (Printf.sprintf "RunRequest missing canonical block %S is refused" block)
            ~saying:block
            (Request.of_json (without block doc) |> Result.map (fun _ -> ())))
       Request.canonical_blocks)

(* ═════════ 9. digest binding is CHECKED, not decorated (AC10) ════════ *)

let test_digest_binding base rich =
  match run_ir ~base ~subject:rich (base_ir ()) with
  | Error e -> check ("binding run should succeed, got " ^ e) false
  | Ok o ->
    let receipt = o.R.receipt in
    let request_digest = J.to_string (J.member "digest" (J.member "request" receipt)) in
    let cm_ir_digest = J.to_string (J.member "digest" (J.member "cm_ir" receipt)) in
    let plan_digest = J.to_string (J.member "digest" (J.member "plan" receipt)) in
    let bind r =
      match Receipt.of_json r with
      | Error e -> Error e
      | Ok parsed -> Receipt.binding_error parsed ~request_digest ~cm_ir_digest ~plan_digest
    in
    check "the emitted receipt's own bindings check out" (bind receipt = Ok ());
    (* One negative per binding. Each mutates EXACTLY ONE digest to another
       well-formed digest, so every field remains individually well-typed and
       the receipt still admits structurally — the refusal can only come from
       the binding check itself. *)
    let other = "sha256:" ^ String.make 64 'b' in
    List.iter
      (fun (block, what) ->
         let mutated = set_in [ block; "digest" ] (J.Str other) receipt in
         check (Printf.sprintf "a receipt with a mutated %s digest still ADMITS structurally" what)
           (match Receipt.of_json mutated with Ok _ -> true | Error _ -> false);
         refuses
           (Printf.sprintf "a receipt whose %s digest does not match the artifact is refused" what)
           ~saying:what (bind mutated))
      [ ("request", "request"); ("cm_ir", "cm_ir"); ("plan", "plan") ];
    (* Table-driven canonical blocks for the receipt and the plan families. *)
    List.iter
      (fun block ->
         refuses (Printf.sprintf "MeasurementReceipt missing canonical block %S is refused" block)
           ~saying:block
           (Receipt.of_json (without block receipt) |> Result.map (fun _ -> ())))
      Receipt.canonical_blocks;
    let plan = o.R.plan_json in
    check "the emitted plan admits"
      (match Plan.of_json plan with Ok _ -> true | Error _ -> false);
    List.iter
      (fun block ->
         refuses (Printf.sprintf "SandboxExecutionPlan missing canonical block %S is refused" block)
           ~saying:block
           (Plan.of_json (without block plan) |> Result.map (fun _ -> ())))
      Plan.canonical_blocks;
    refuses "a plan carrying an unproved linker obligation is refused"
      ~saying:"unproved linker obligation"
      (Plan.of_json
         (set_field "steps"
            (match get "steps" plan with
             | J.Arr (s :: rest) ->
               J.Arr (set_in [ "discharge"; "config_schema" ] (J.Bool false) s :: rest)
             | other -> other)
            plan)
       |> Result.map (fun _ -> ()));
    refuses "a receipt naming an unknown extension family is refused"
      ~saying:"not a known receipt family"
      (Receipt.of_json (set_in [ "extension"; "family" ] (J.Str "ascent") receipt)
       |> Result.map (fun _ -> ()));
    (* The receipt must CARRY what a verifier needs: the matched rule and the
       fact references it read, each with a content digest. *)
    let result = J.member "result" receipt in
    let refs = J.to_list (J.member "fact_refs" result) in
    check "the receipt records the matched rule id"
      (J.to_string (J.member "rule_id" result) = "legible");
    check "the receipt records the fact references the rule read, with digests"
      (refs <> []
       && List.for_all
            (fun r ->
               J.member_opt "ref" r <> None && J.member_opt "kind" r <> None
               && (J.member_opt "available" r = Some (J.Bool false)
                   || J.member_opt "digest" r <> None))
            refs)

(* ══════════════ 10. malformed input never escapes as an exception ═════ *)

let test_malformed base rich =
  let path name contents =
    let p = Filename.concat base name in write_file p contents; p in
  let run p =
    R.run { R.ir_path = p; request_path = None; locators = [ ("repository", rich) ] } in
  (* β #126 round-1 F1 regression pair: the vendored parser raises exception
     classes beyond Parse_error — [Failure] on a malformed number literal and
     [Invalid_argument] on a truncated `\u` escape. Both must funnel to the
     clean fail-closed [Error] channel. *)
  check "a malformed number literal is a clean error, not an exception"
    (match run (path "bad-number.json" {|{ "format": "x", "n": 12e }|}) with
     | Error _ -> true | Ok _ -> false | exception _ -> false);
  check "a truncated \\u escape is a clean error, not an exception"
    (match run (path "bad-escape.json" {|{ "format": "\u00|}) with
     | Error _ -> true | Ok _ -> false | exception _ -> false);
  check "an unreadable IR path is a clean error, not an exception"
    (match run (Filename.concat base "no-such-file.json") with
     | Error _ -> true | Ok _ -> false | exception _ -> false)

(* ═══════════ 11. the artifact-family table used by `check` ════════════ *)

let test_families () =
  check "every artifact family declares a non-empty canonical block set"
    (List.for_all
       (fun name ->
          match R.family_of_string name with
          | Ok f -> R.canonical_blocks_of f <> []
          | Error _ -> false)
       R.family_names);
  refuses "an unknown artifact family is refused" ~saying:"unknown artifact family"
    (R.family_of_string "ascent-receipt" |> Result.map (fun _ -> ()));
  check "the negative generator yields one variant per canonical block"
    (List.length (R.missing_block_variants R.Cm_ir (base_ir ()))
     = List.length Ir.canonical_blocks)

(* ═══════════════════════════════ main ════════════════════════════════ *)

let () =
  test_confine ();
  test_algebra ();
  test_rule_table ();
  test_canonical_blocks ();
  test_graph_refusals ();
  test_provenance ();
  test_link_safety ();
  test_request_ceiling ();
  test_outcome_contract ();
  let base = temp_dir () in
  let (rich, bare) = test_end_to_end base in
  test_scheduling_independence base rich;
  test_obligations base rich;
  test_run_request rich bare;
  test_digest_binding base rich;
  test_malformed base rich;
  test_families ();
  Printf.printf "\n%d check(s) run\n" !checks;
  if !failures > 0 then (Printf.printf "%d check(s) failed\n" !failures; exit 1)
  else print_endline "all checks passed"
