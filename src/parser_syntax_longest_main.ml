let short_decl = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "if"; Parser.TUnderscore; Parser.TIdent "expand"; Parser.TIdent "short"; Parser.TEOF]
let long_decl = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "if"; Parser.TUnderscore; Parser.TIdent "then"; Parser.TUnderscore; Parser.TIdent "expand"; Parser.TIdent "long"; Parser.TEOF]
let use_tokens = [Parser.TIdent "if"; Parser.TIdent "cond"; Parser.TIdent "then"; Parser.TIdent "body"; Parser.TEOF]
let _ = Registry.reset_syntax_registry ()
let _ = Parser.parse short_decl
let _ = Parser.parse long_decl
let parsed = Parser.parse use_tokens
let _ = Ast.dump_program parsed
