let tokens = [Parser.TMint; Parser.TIdent "max2"; Parser.TLParen; Parser.TIdent "a"; Parser.TIdent "b"; Parser.TRParen; Parser.TRArrow; Parser.TLParen; Parser.TIdent "q"; Parser.TIdent "r"; Parser.TRParen; Parser.TEOF]
let parsed = Parser.parse tokens
let _ = Ast.dump_program parsed
