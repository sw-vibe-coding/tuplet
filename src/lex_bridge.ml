let rec bytes_to_string bs = match bs with [] -> "" | h :: t -> String.make 1 (Char.chr h) ^ bytes_to_string t
let to_parser_fixed_token t = match t with Lexer.TInt n -> Parser.TInt n | Lexer.TPct n -> Parser.TPct n | Lexer.TMinus -> Parser.TMinus | Lexer.TLArrow -> Parser.TLArrow | Lexer.TRArrow -> Parser.TRArrow | Lexer.TLParen -> Parser.TLParen | Lexer.TRParen -> Parser.TRParen | Lexer.TLBrace -> Parser.TLBrace | Lexer.TRBrace -> Parser.TRBrace | Lexer.TComma -> Parser.TComma | Lexer.TUnderscore -> Parser.TUnderscore | Lexer.TMint -> Parser.TMint | Lexer.TEOF -> Parser.TEOF | _ -> Parser.TEOF
let to_parser_token t = match t with Lexer.THash bs -> Parser.THash (bytes_to_string bs) | Lexer.TIdent bs -> Parser.TIdent (bytes_to_string bs) | Lexer.TLiteral bs -> Parser.TLiteral (bytes_to_string bs) | Lexer.TUnknown n -> Parser.TUnknown n | _ -> to_parser_fixed_token t
let rec to_parser_tokens toks = match toks with [] -> [] | h :: t -> to_parser_token h :: to_parser_tokens t
let parse_next u = Parser.parse (to_parser_tokens (Lexer.lex_loop 0 []))
let parse_line u = Parser.parse (to_parser_tokens (Lexer.lex_line_loop 0 []))
