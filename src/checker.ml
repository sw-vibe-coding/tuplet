type shape = Shape of int * int
type result = COk of string list | CError of string
type arity_result = AOk of int | AError of string

let rec count_items xs = match xs with [] -> 0 | h :: t -> 1 + count_items t
let rec lookup_shape name env = match env with [] -> (false, Shape (0, 0)) | pair :: rest -> let k = fst pair in let v = snd pair in if k = name then (true, v) else lookup_shape name rest
let rec find_group kind nodes = match nodes with [] -> Ast.AGroup ("", []) | h :: t -> (match h with Ast.AGroup (k, xs) -> if k = kind then h else find_group kind t | _ -> find_group kind t)
let group_items n = match n with Ast.AGroup (k, xs) -> xs | _ -> []
let group_first n = match group_items n with [] -> "" | h :: t -> h

let scalar_arity item = match item with "int:0" -> 1 | "int:1" -> 1 | "int:2" -> 1 | "int:3" -> 1 | "int:4" -> 1 | "int:5" -> 1 | "int:6" -> 1 | "int:7" -> 1 | "int:8" -> 1 | "int:9" -> 1 | "pct:50" -> 1 | _ -> 0
let item_arity item env = let scalar = scalar_arity item in if scalar > 0 then AOk scalar else let pair = lookup_shape item env in if fst pair then (match snd pair with Shape (i, o) -> AOk o) else AError ("checker:unbound-name:" ^ item)
let rec sum_item_arities xs env total = match xs with [] -> AOk total | h :: t -> (match item_arity h env with AError s -> AError s | AOk n -> sum_item_arities t env (total + n))

let check_signature nodes env acc =
  let name = group_first (find_group "name" nodes) in
  let inputs = count_items (group_items (find_group "inputs" nodes)) in
  let outputs = count_items (group_items (find_group "outputs" nodes)) in
  let line = "BIND " ^ name ^ " inputs:" ^ string_of_int inputs ^ " outputs:" ^ string_of_int outputs in
  (COk (line :: acc), (name, Shape (inputs, outputs)) :: env)

let check_assign nodes env acc =
  let expected = count_items (group_items (find_group "pattern" nodes)) in
  let expr = group_items (find_group "expr" nodes) in
  match sum_item_arities expr env 0 with
  | AError s -> (CError s, env)
  | AOk actual ->
      if expected = actual then (COk ("ASSIGN arity:" ^ string_of_int actual :: acc), env)
      else (CError ("checker:arity-mismatch expected:" ^ string_of_int expected ^ " actual:" ^ string_of_int actual), env)

let check_call_shape callee inputs outputs nodes env acc =
  let args = group_items (find_group "args" nodes) in
  match sum_item_arities args env 0 with
  | AError s -> (CError s, env)
  | AOk actual ->
      if inputs = actual then (COk ("CALL " ^ callee ^ " inputs:" ^ string_of_int actual ^ " outputs:" ^ string_of_int outputs :: acc), env)
      else (CError ("checker:call-arity-mismatch callee:" ^ callee ^ " expected:" ^ string_of_int inputs ^ " actual:" ^ string_of_int actual), env)

let check_call nodes env acc =
  let callee = group_first (find_group "callee" nodes) in
  let pair = lookup_shape callee env in
  if fst pair then (match snd pair with Shape (inputs, outputs) -> check_call_shape callee inputs outputs nodes env acc)
  else (CError ("checker:unbound-name:" ^ callee), env)

let check_stmt stmt env acc = match stmt with Ast.AStmt (kind, nodes) -> if kind = "signature" then check_signature nodes env acc else if kind = "assign" then check_assign nodes env acc else if kind = "call" then check_call nodes env acc else (COk ("SKIP " ^ kind :: acc), env) | _ -> (COk acc, env)
let rec check_nodes nodes env acc = match nodes with [] -> COk (List.rev acc) | h :: t -> let pair = check_stmt h env acc in let res = fst pair in let env2 = snd pair in (match res with CError s -> CError s | COk acc2 -> check_nodes t env2 acc2)
let check n = match n with Ast.AProgram nodes -> check_nodes nodes [] [] | Ast.AError s -> CError s | _ -> check_nodes [n] [] []
let rec dump_lines xs = match xs with [] -> () | h :: t -> let _ = print_endline h in dump_lines t
let dump_result r = match r with CError s -> print_endline ("ERROR  " ^ s) | COk xs -> let _ = print_endline "CHECK OK" in let _ = dump_lines xs in print_endline "ENDCHECK"
