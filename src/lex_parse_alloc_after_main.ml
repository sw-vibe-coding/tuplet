let _ = Lexer.use_memory_input 524288
let parsed = Lex_bridge.parse_next ()
let _ = Ast.dump_program parsed
let s = "a" ^ "b"
let _ = print_endline s
