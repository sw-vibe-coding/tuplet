let sample_tokens = [TMint; TIdent "coord2"; TRArrow; TLParen; TIdent "x"; TIdent "y"; TRParen; THash "ignored"; TLiteral "if"; TEOF]
let _ = dump_program (parse sample_tokens)
