let bad_group_tokens = [TIdent "call"; TLParen; TIdent "x"; TEOF]
let _ = dump_program (parse bad_group_tokens)
