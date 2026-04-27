type node = AAtom of string | AStmt of node list | AProgram of node list | AError of string
let dump_atom s = print_endline ("ATOM   " ^ s)
let dump_error s = print_endline ("ERROR  " ^ s)
let dump_stmt_node n = match n with AAtom s -> dump_atom s | AStmt xs -> print_endline "STMT" | AProgram xs -> print_endline "PROGRAM" | AError s -> dump_error s
let rec dump_stmt_nodes xs = match xs with [] -> () | h :: t -> let _ = dump_stmt_node h in dump_stmt_nodes t
let dump_node n = match n with AAtom s -> dump_atom s | AStmt xs -> let _ = print_endline "STMT" in let _ = dump_stmt_nodes xs in print_endline "ENDSTMT" | AProgram xs -> print_endline "PROGRAM" | AError s -> dump_error s
let rec dump_program_nodes xs = match xs with [] -> () | h :: t -> let _ = dump_node h in dump_program_nodes t
let dump_program n = match n with AProgram xs -> let _ = print_endline "PROGRAM" in let _ = dump_program_nodes xs in print_endline "END" | AError s -> dump_error s | AAtom s -> dump_node (AAtom s) | AStmt xs -> dump_node (AStmt xs)
