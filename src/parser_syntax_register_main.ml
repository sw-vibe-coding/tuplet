let syntax_tokens = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "do"; Parser.TUnderscore; Parser.TIdent "while"; Parser.TUnderscore; Parser.TIdent "end"; Parser.TIdent "expand"; Parser.TUnderscore; Parser.TInt 1; Parser.TUnderscore; Parser.TInt 2; Parser.TLiteral "again"; Parser.TEOF]
let _ = Registry.reset_syntax_registry ()
let parsed = Parser.parse syntax_tokens
let _ = Ast.dump_program parsed
let _ = Registry.dump_syntax_registry ()
