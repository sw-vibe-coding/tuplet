let bad_tokens = [Parser.TIdent "ok"; Parser.THash "ignored"; Parser.TUnknown 64; Parser.TEOF]
let _ = Ast.dump_program (Parser.parse bad_tokens)
