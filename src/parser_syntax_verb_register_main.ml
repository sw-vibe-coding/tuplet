let syntax_tokens = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "if"; Parser.TUnderscore; Parser.TIdent "then"; Parser.TUnderscore; Parser.TRArrow; Parser.TIdent "branch"; Parser.TEOF]
let _ = Registry.reset_syntax_registry ()
let parsed = Parser.parse syntax_tokens
let _ = Ast.dump_program parsed
let _ = Registry.dump_syntax_registry ()
