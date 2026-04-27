let sample_tokens = [TMint; TIdent "coord2"; TRArrow; TLParen; TIdent "x"; TIdent "y"; TRParen; TLiteral "if"; THash "ignored"; TEOF]
let _ = dump_program (parse sample_tokens)
