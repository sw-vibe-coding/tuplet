type shape = Shape of int * int
type result = IROk of string list | IRError of string

let rec count_items xs = match xs with [] -> 0 | h :: t -> 1 + count_items t
let rec find_group kind nodes = match nodes with [] -> Ast.AGroup ("", []) | h :: t -> (match h with Ast.AGroup (k, xs) -> if k = kind then h else find_group kind t | _ -> find_group kind t)
let group_items n = match n with Ast.AGroup (k, xs) -> xs | _ -> []
let group_first n = match group_items n with [] -> "" | h :: t -> h

let rec lookup_shape name env = match env with [] -> (false, Shape (0, 0)) | pair :: rest -> let k = fst pair in let v = snd pair in if k = name then (true, v) else lookup_shape name rest

let scalar_instr item = match item with
  | "int:0" -> "PUSH_INT 0"
  | "int:1" -> "PUSH_INT 1"
  | "int:2" -> "PUSH_INT 2"
  | "int:3" -> "PUSH_INT 3"
  | "int:4" -> "PUSH_INT 4"
  | "int:5" -> "PUSH_INT 5"
  | "int:6" -> "PUSH_INT 6"
  | "int:7" -> "PUSH_INT 7"
  | "int:8" -> "PUSH_INT 8"
  | "int:9" -> "PUSH_INT 9"
  | "pct:50" -> "PUSH_PCT 50"
  | _ -> ""

let emit_item item env acc =
  let scalar = scalar_instr item in
  if scalar = "" then let pair = lookup_shape item env in
    if fst pair then (match snd pair with Shape (i, o) -> if i = 0 then IROk (("LOAD_TUPLE " ^ item ^ " arity:" ^ string_of_int o) :: acc) else IROk (("CALL " ^ item ^ " inputs:" ^ string_of_int i ^ " outputs:" ^ string_of_int o) :: acc))
    else IROk (("LOAD " ^ item) :: acc)
  else IROk (scalar :: acc)

let rec emit_items xs env acc = match xs with [] -> IROk acc | h :: t -> (match emit_item h env acc with IRError s -> IRError s | IROk acc2 -> emit_items t env acc2)

let store_name item = "STORE " ^ item
let rec store_pattern_reverse xs acc = match xs with [] -> acc | h :: t -> store_pattern_reverse t (store_name h :: acc)

let lower_signature nodes env acc =
  let name = group_first (find_group "name" nodes) in
  let inputs = count_items (group_items (find_group "inputs" nodes)) in
  let outputs = count_items (group_items (find_group "outputs" nodes)) in
  let line = "DECLARE " ^ name ^ " inputs:" ^ string_of_int inputs ^ " outputs:" ^ string_of_int outputs in
  (IROk (line :: acc), (name, Shape (inputs, outputs)) :: env)

let lower_assign nodes env acc =
  let pattern = group_items (find_group "pattern" nodes) in
  let expr = group_items (find_group "expr" nodes) in
  match emit_items expr env acc with
  | IRError s -> (IRError s, env)
  | IROk acc2 -> (IROk (store_pattern_reverse (List.rev pattern) acc2), env)

let lower_call nodes env acc =
  let callee = group_first (find_group "callee" nodes) in
  let args = group_items (find_group "args" nodes) in
  match emit_items args env acc with
  | IRError s -> (IRError s, env)
  | IROk acc2 ->
      let pair = lookup_shape callee env in
      if fst pair then (match snd pair with Shape (inputs, outputs) -> (IROk (("CALL " ^ callee ^ " inputs:" ^ string_of_int inputs ^ " outputs:" ^ string_of_int outputs) :: acc2), env))
      else (IRError ("ir:unbound-callee:" ^ callee), env)

let lower_stmt stmt env acc = match stmt with Ast.AStmt (kind, nodes) -> if kind = "signature" then lower_signature nodes env acc else if kind = "assign" then lower_assign nodes env acc else if kind = "call" then lower_call nodes env acc else (IROk (("SKIP " ^ kind) :: acc), env) | _ -> (IROk acc, env)
let rec lower_nodes nodes env acc = match nodes with [] -> IROk (List.rev acc) | h :: t -> let pair = lower_stmt h env acc in let res = fst pair in let env2 = snd pair in (match res with IRError s -> IRError s | IROk acc2 -> lower_nodes t env2 acc2)
let lower n = match Checker.check n with Checker.CError s -> IRError s | Checker.COk xs -> (match n with Ast.AProgram nodes -> lower_nodes nodes [] [] | Ast.AError s -> IRError s | _ -> lower_nodes [n] [] [])

let rec dump_lines xs = match xs with [] -> () | h :: t -> let _ = print_endline h in dump_lines t
let dump_result r = match r with IRError s -> print_endline ("ERROR  " ^ s) | IROk xs -> let _ = print_endline "IR" in let _ = dump_lines xs in print_endline "ENDIR"
