let decl_tokens = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "do"; Parser.TUnderscore; Parser.TIdent "while"; Parser.TUnderscore; Parser.TIdent "end"; Parser.TIdent "expand"; Parser.TUnderscore; Parser.TInt 1; Parser.TUnderscore; Parser.TInt 2; Parser.TEOF]
let use_tokens = [Parser.TIdent "do"; Parser.TIdent "work"; Parser.TIdent "hard"; Parser.TIdent "while"; Parser.TIdent "x"; Parser.TInt 0; Parser.TIdent "gt"; Parser.TIdent "end"; Parser.TEOF]
let _ = Registry.reset_syntax_registry ()
let _ = Parser.parse decl_tokens
let parsed = Parser.parse use_tokens
let _ = Ast.dump_program parsed
