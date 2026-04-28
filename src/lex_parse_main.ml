let _ = Lexer.use_memory_input 524288
let _ = Ast.dump_program (Lex_bridge.parse_next ())
