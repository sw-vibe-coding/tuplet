let sample_tokens = [Parser.TMint; Parser.TIdent "coord2"; Parser.TRArrow; Parser.TLParen; Parser.TIdent "x"; Parser.TIdent "y"; Parser.TRParen; Parser.THash "ignored"; Parser.TLiteral "if"; Parser.TEOF]
let _ = Ast.dump_program (Parser.parse sample_tokens)
