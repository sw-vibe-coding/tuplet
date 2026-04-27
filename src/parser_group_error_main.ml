let bad_group_tokens = [Parser.TIdent "call"; Parser.TLParen; Parser.TIdent "x"; Parser.TEOF]
let _ = Ast.dump_program (Parser.parse bad_group_tokens)
