type node = AToken of string | AProgram of node list
let dump_leaf s = print_endline ("TOKEN  " ^ s)
let dump_node n = match n with AToken s -> dump_leaf s | AProgram xs -> print_endline "PROGRAM"
let rec dump_nodes xs = match xs with [] -> () | h :: t -> let _ = dump_node h in dump_nodes t
let dump_program n = match n with AProgram xs -> let _ = print_endline "PROGRAM" in let _ = dump_nodes xs in print_endline "END" | AToken s -> dump_node (AToken s)
