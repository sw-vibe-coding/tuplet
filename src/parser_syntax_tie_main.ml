let first_decl = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "pick"; Parser.TUnderscore; Parser.TIdent "expand"; Parser.TIdent "first"; Parser.TEOF]
let second_decl = [Parser.TMint; Parser.TIdent "syntax"; Parser.TIdent "pick"; Parser.TUnderscore; Parser.TIdent "expand"; Parser.TIdent "second"; Parser.TEOF]
let use_tokens = [Parser.TIdent "pick"; Parser.TIdent "value"; Parser.TEOF]
let _ = Registry.reset_syntax_registry ()
let _ = Parser.parse first_decl
let _ = Parser.parse second_decl
let parsed = Parser.parse use_tokens
let _ = Ast.dump_program parsed
