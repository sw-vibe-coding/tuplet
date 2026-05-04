let tokens = [Parser.TMint; Parser.TIdent "coord2"; Parser.TRArrow; Parser.TLParen; Parser.TIdent "x"; Parser.TIdent "y"; Parser.TRParen; Parser.TIdent "a"; Parser.TComma; Parser.TIdent "b"; Parser.TLArrow; Parser.TIdent "coord2"; Parser.TEOF]
let parsed = Parser.parse tokens
let lowered = Ir.lower parsed
let emitted = Forth_emit.emit lowered
let _ = Forth_emit.dump_result emitted
