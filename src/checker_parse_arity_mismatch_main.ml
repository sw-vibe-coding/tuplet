let tokens = [Parser.TMint; Parser.TIdent "coord2"; Parser.TRArrow; Parser.TLParen; Parser.TIdent "x"; Parser.TIdent "y"; Parser.TRParen; Parser.TIdent "a"; Parser.TComma; Parser.TIdent "b"; Parser.TComma; Parser.TIdent "c"; Parser.TLArrow; Parser.TIdent "coord2"; Parser.TEOF]
let parsed = Parser.parse tokens
let checked = Checker.check parsed
let _ = Checker.dump_result checked
