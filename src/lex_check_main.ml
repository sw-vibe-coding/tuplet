let _ = Lexer.use_memory_input 524288
let parsed = Lex_bridge.parse_next ()
let checked = Checker.check parsed
let _ = Checker.dump_result checked
