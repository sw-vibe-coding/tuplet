let rec append_nodes xs ys = match xs with [] -> ys | h :: t -> h :: append_nodes t ys
let program_nodes n = match n with Ast.AProgram xs -> xs | _ -> []
let append_program a b = Ast.AProgram (append_nodes (program_nodes a) (program_nodes b))
let _ = Lexer.use_memory_input 524288
let first = Lex_bridge.parse_line ()
let second = Lex_bridge.parse_next ()
let checked = Checker.check (append_program first second)
let _ = Checker.dump_result checked
