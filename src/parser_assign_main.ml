let assign_tokens = [TIdent "n"; TLArrow; TInt 1; TComma; TLBrace; TIdent "n"; TInt 2; TRBrace; TEOF]
let _ = dump_program (parse assign_tokens)
