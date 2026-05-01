let tokens = [Parser.TIdent "a"; Parser.TComma; Parser.TIdent "b"; Parser.TLArrow; Parser.TIdent "coord2"; Parser.TEOF]
let parsed = Parser.parse tokens
let _ = Ast.dump_program parsed
