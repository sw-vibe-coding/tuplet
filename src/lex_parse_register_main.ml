let _ = Lexer.use_memory_input 524288
let _ = Registry.reset_syntax_registry ()
let _ = Lex_bridge.parse_line ()
let parsed = Lex_bridge.parse_next ()
let _ = Ast.dump_program parsed
