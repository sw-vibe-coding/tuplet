let tokens = [Parser.TIdent "plot"; Parser.TLParen; Parser.TIdent "coord2"; Parser.TIdent "Red"; Parser.TPct 50; Parser.TRParen; Parser.TEOF]
let parsed = Parser.parse tokens
let _ = Ast.dump_program parsed
