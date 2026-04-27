let assign_tokens = [Parser.TIdent "n"; Parser.TLArrow; Parser.TInt 1; Parser.TComma; Parser.TLBrace; Parser.TIdent "n"; Parser.TInt 2; Parser.TRBrace; Parser.TEOF]
let _ = Ast.dump_program (Parser.parse assign_tokens)
