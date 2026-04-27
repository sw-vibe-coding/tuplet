let syntax_tokens = [TMint; TIdent "syntax"; TIdent "do"; TUnderscore; TIdent "while"; TUnderscore; TIdent "end"; TIdent "expand"; TUnderscore; TInt 1; TUnderscore; TInt 2; TLiteral "again"; TEOF]
let _ = dump_program (parse syntax_tokens)
