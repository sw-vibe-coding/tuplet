type syntax_entry = SyntaxEntry of string * string * string list * string list
let syntax_entries = ref []
let syntax_next_order = ref 0
let add_syntax mode template expansion = let order = !syntax_next_order in let order_s = string_of_int order in let _ = syntax_next_order := order + 1 in syntax_entries := SyntaxEntry (order_s, mode, template, expansion) :: !syntax_entries
let reset_syntax_registry u = let _ = syntax_entries := [] in syntax_next_order := 0
let rec dump_items xs = match xs with [] -> () | h :: t -> let _ = print_endline ("ITEM   " ^ h) in dump_items t
let dump_entry e = match e with SyntaxEntry (order, mode, template, expansion) -> let _ = print_endline ("ENTRY  " ^ order ^ " " ^ mode) in let _ = print_endline "TEMPLATE" in let _ = dump_items template in let _ = print_endline "EXPANSION" in let _ = dump_items expansion in print_endline "ENDENTRY"
let rec dump_entries xs = match xs with [] -> () | h :: t -> let _ = dump_entry h in dump_entries t
let dump_syntax_registry u = let _ = print_endline "REGISTRY" in let _ = dump_entries (List.rev !syntax_entries) in print_endline "ENDREGISTRY"
