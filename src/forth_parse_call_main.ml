let tokens = [Parser.TMint; Parser.TIdent "plot"; Parser.TLParen; Parser.TIdent "x"; Parser.TIdent "y"; Parser.TIdent "color"; Parser.TIdent "transparency"; Parser.TRParen; Parser.TRArrow; Parser.TLParen; Parser.TIdent "success"; Parser.TRParen; Parser.TMint; Parser.TIdent "coord2"; Parser.TRArrow; Parser.TLParen; Parser.TIdent "x"; Parser.TIdent "y"; Parser.TRParen; Parser.TIdent "plot"; Parser.TLParen; Parser.TIdent "coord2"; Parser.TInt 7; Parser.TPct 50; Parser.TRParen; Parser.TEOF]
let parsed = Parser.parse tokens
let lowered = Ir.lower parsed
let emitted = Forth_emit.emit lowered
let _ = Forth_emit.dump_result emitted
