type result = FOk of string list | FError of string

let rec append_items xs ys = match xs with [] -> ys | h :: t -> h :: append_items t ys
let rec has_name name xs = match xs with [] -> false | h :: t -> if h = name then true else has_name name t

let store_item line = match line with
  | "STORE ident:a" -> "a"
  | "STORE ident:b" -> "b"
  | "STORE ident:success" -> "success"
  | _ -> ""

let rec collect_stores lines acc = match lines with
  | [] -> acc
  | h :: t ->
      let name = store_item h in
      if name = "" then collect_stores t acc
      else if has_name name acc then collect_stores t acc
      else collect_stores t (append_items acc [name])

let scalar_decl name = ("CREATE " ^ name ^ "-cell 0 ,") :: ((": " ^ name ^ "!  " ^ name ^ "-cell ! ;") :: ((": " ^ name ^ "@  " ^ name ^ "-cell @ ;") :: []))

let rec scalar_decls names acc = match names with
  | [] -> acc
  | h :: t -> scalar_decls t (append_items acc (scalar_decl h))

let tuple_decl line = match line with
  | "DECLARE ident:coord2 inputs:0 outputs:2" ->
      "CREATE coord2-0 0 ," :: ("CREATE coord2-1 0 ," :: (": coord2!  coord2-1 ! coord2-0 ! ;" :: (": coord2@  coord2-0 @ coord2-1 @ ;" :: [])))
  | "DECLARE ident:plot inputs:4 outputs:1" -> []
  | _ -> []

let rec tuple_decls lines acc = match lines with
  | [] -> acc
  | h :: t -> tuple_decls t (append_items acc (tuple_decl h))

let body_line line = match line with
  | "LOAD_TUPLE ident:coord2 arity:2" -> "coord2@"
  | "PUSH_INT 0" -> "0"
  | "PUSH_INT 1" -> "1"
  | "PUSH_INT 2" -> "2"
  | "PUSH_INT 3" -> "3"
  | "PUSH_INT 4" -> "4"
  | "PUSH_INT 5" -> "5"
  | "PUSH_INT 6" -> "6"
  | "PUSH_INT 7" -> "7"
  | "PUSH_INT 8" -> "8"
  | "PUSH_INT 9" -> "9"
  | "PUSH_PCT 50" -> "50"
  | "STORE ident:a" -> "a!"
  | "STORE ident:b" -> "b!"
  | "STORE ident:success" -> "success!"
  | "CALL ident:plot inputs:4 outputs:1" -> "plot"
  | _ -> ""

let rec body_lines lines acc = match lines with
  | [] -> acc
  | h :: t ->
      let out = body_line h in
      if out = "" then body_lines t acc else body_lines t (append_items acc [out])

let emit ir = match ir with
  | Ir.IRError s -> FError s
  | Ir.IROk lines ->
      let decls = append_items (tuple_decls lines []) (scalar_decls (collect_stores lines []) []) in
      FOk (append_items decls ("BODY" :: append_items (body_lines lines []) ["ENDFORTH"]))

let rec dump_lines xs = match xs with [] -> () | h :: t -> let _ = print_endline h in dump_lines t
let dump_result r = match r with FError s -> print_endline ("ERROR  " ^ s) | FOk xs -> let _ = print_endline "FORTH" in dump_lines xs
