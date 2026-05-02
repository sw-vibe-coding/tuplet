let _ = Lexer.use_memory_input 524288
let parsed = Lex_bridge.parse_next ()
let lowered = Ir.lower parsed
let _ = Ir.dump_result lowered
