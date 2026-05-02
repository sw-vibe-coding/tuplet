let tokens = [Parser.TLParen; Parser.TIdent "x"; Parser.TComma; Parser.TIdent "y"; Parser.TInt 7; Parser.TRParen; Parser.TEOF]
let parsed = Parser.parse tokens
let _ = Ast.dump_program parsed
