let bad_tokens = [TIdent "ok"; THash "ignored"; TUnknown 64; TEOF]
let _ = dump_program (parse bad_tokens)
