type node = AAtom of string | AGroup of string * string list | AStmt of string * node list | AProgram of node list | AError of string
let dump_atom s = print_endline ("ATOM   " ^ s)
let dump_error s = print_endline ("ERROR  " ^ s)
let rec dump_group_items xs = match xs with [] -> () | h :: t -> let _ = print_endline ("ITEM   " ^ h) in dump_group_items t
let dump_group kind xs = let _ = print_endline ("GROUP  " ^ kind) in let _ = dump_group_items xs in print_endline "ENDGROUP"
let dump_stmt_node n = match n with AAtom s -> dump_atom s | AGroup (kind, xs) -> dump_group kind xs | AStmt (kind, xs) -> print_endline ("STMT   " ^ kind) | AProgram xs -> print_endline "PROGRAM" | AError s -> dump_error s
let rec dump_stmt_nodes xs = match xs with [] -> () | h :: t -> let _ = dump_stmt_node h in dump_stmt_nodes t
let dump_node n = match n with AAtom s -> dump_atom s | AGroup (kind, xs) -> dump_group kind xs | AStmt (kind, xs) -> let _ = print_endline ("STMT   " ^ kind) in let _ = dump_stmt_nodes xs in print_endline "ENDSTMT" | AProgram xs -> print_endline "PROGRAM" | AError s -> dump_error s
let rec dump_program_nodes xs = match xs with [] -> () | h :: t -> let _ = dump_node h in dump_program_nodes t
let dump_program n = match n with AProgram xs -> let _ = print_endline "PROGRAM" in let _ = dump_program_nodes xs in print_endline "END" | AError s -> dump_error s | AAtom s -> dump_node (AAtom s) | AGroup (kind, xs) -> dump_node (AGroup (kind, xs)) | AStmt (kind, xs) -> dump_node (AStmt (kind, xs))
