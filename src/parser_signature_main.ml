let tokens = [Parser.TMint; Parser.TIdent "coord2"; Parser.TRArrow; Parser.TLParen; Parser.TIdent "x"; Parser.TIdent "y"; Parser.TRParen; Parser.TEOF]
let parsed = Parser.parse tokens
let _ = Ast.dump_program parsed
