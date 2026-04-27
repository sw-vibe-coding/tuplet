type token = THash of int list | TInt of int | TPct of int | TMinus | TLArrow | TRArrow | TLParen | TRParen | TLBrace | TRBrace | TComma | TUnderscore | TMint | TIdent of int list | TLiteral of int list | TUnknown of int | TEOF
let rec emit_bytes bs = match bs with [] -> () | h :: t -> let _ = putc h in emit_bytes t
let prefix_hash = [72; 65; 83; 72; 32; 32; 32]
let prefix_int = [73; 78; 84; 32; 32; 32; 32]
let prefix_pct = [80; 67; 84; 32; 32; 32; 32]
let prefix_unk = [85; 78; 75; 32; 32; 32; 32]
let prefix_id = [73; 68; 69; 78; 84; 32; 32]
let prefix_lit = [76; 73; 84; 32; 32; 32; 32]
let rec int_to_bytes_aux x acc = if x = 0 then acc else int_to_bytes_aux (x / 10) ((x mod 10 + 48) :: acc)
let int_to_bytes n = if n = 0 then [48] else int_to_bytes_aux n []
let dump_tok t = match t with TEOF -> print_endline "EOF" | TMinus -> print_endline "MINUS" | TLArrow -> print_endline "LARROW" | TRArrow -> print_endline "RARROW" | TLParen -> print_endline "LPAREN" | TRParen -> print_endline "RPAREN" | TLBrace -> print_endline "LBRACE" | TRBrace -> print_endline "RBRACE" | TComma -> print_endline "COMMA" | TUnderscore -> print_endline "USCORE" | TMint -> print_endline "MINT" | THash bs -> let _ = emit_bytes prefix_hash in let _ = emit_bytes bs in putc 10 | TInt n -> let _ = emit_bytes prefix_int in let _ = emit_bytes (int_to_bytes n) in putc 10 | TPct n -> let _ = emit_bytes prefix_pct in let _ = emit_bytes (int_to_bytes n) in putc 10 | TIdent bs -> let _ = emit_bytes prefix_id in let _ = emit_bytes bs in putc 10 | TLiteral bs -> let _ = emit_bytes prefix_lit in let _ = emit_bytes bs in putc 10 | TUnknown b -> let _ = emit_bytes prefix_unk in let _ = print_int b in putc 10
let rec dump_tokens toks = match toks with [] -> () | h :: t -> let _ = dump_tok h in dump_tokens t
let registered_literals = ref []
let add_literal bs = registered_literals := bs :: !registered_literals
let rec bytes_equal a b = match a with [] -> (match b with [] -> true | _ -> false) | ah :: at -> (match b with [] -> false | bh :: bt -> if ah = bh then bytes_equal at bt else false)
let rec is_registered bs regs = match regs with [] -> false | h :: t -> if bytes_equal bs h then true else is_registered bs t
let token_for_ident bs = if is_registered bs !registered_literals then TLiteral bs else TIdent bs
let is_ws c = c = 32 || c = 9 || c = 10 || c = 13
let is_digit c = c >= 48 && c <= 57
let is_letter c = (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
let is_ident_cont c = is_letter c || is_digit c || c = 95
let rec collect_comment acc = let c = getc () in if c = 10 then List.rev acc else if c = 3 then List.rev acc else collect_comment (c :: acc)
let rec lex_digits n = let b = getc () in if is_digit b then lex_digits (n * 10 + (b - 48)) else (n, b)
let rec lex_ident_body acc = let b = getc () in if is_ident_cont b then lex_ident_body (b :: acc) else (acc, b)
let lex_ident_after start acc = let pair = lex_ident_body start in let rev_body = fst pair in let next = snd pair in if next = 63 then (token_for_ident (List.rev (63 :: rev_body)) :: acc, 0) else let name = List.rev rev_body in (token_for_ident name :: acc, next)
let lex_uscore acc = let nxt = getc () in if is_ident_cont nxt then lex_ident_after [nxt; 95] acc else (TUnderscore :: acc, nxt)
let lex_lt acc = let nxt = getc () in if nxt = 45 then (TLArrow :: acc, 0) else (TUnknown 60 :: acc, nxt)
let lex_minus acc = let nxt = getc () in if nxt = 62 then (TRArrow :: acc, 0) else (TMinus :: acc, nxt)
let lex_other b acc = if is_letter b then lex_ident_after [b] acc else if is_digit b then let pair = lex_digits (b - 48) in let n = fst pair in let next = snd pair in if next = 37 then (TPct n :: acc, 0) else (TInt n :: acc, next) else if b = 40 then (TLParen :: acc, 0) else if b = 41 then (TRParen :: acc, 0) else if b = 123 then (TLBrace :: acc, 0) else if b = 125 then (TRBrace :: acc, 0) else if b = 44 then (TComma :: acc, 0) else if b = 42 then (TMint :: acc, 0) else if b = 34 then (TMint :: acc, 0) else if b = 170 then (TMint :: acc, 0) else if b = 144 then (TLArrow :: acc, 0) else if b = 245 then (TLArrow :: acc, 0) else if b = 146 then (TRArrow :: acc, 0) else if b = 210 then (TUnknown 62 :: TRArrow :: acc, 0) else (TUnknown b :: acc, 0)
let rec lex_loop pre acc = let b = if pre = 0 then getc () else pre in if b = 3 then List.rev (TEOF :: acc) else if is_ws b then lex_loop 0 acc else if b = 35 then let body = collect_comment [] in lex_loop 0 (THash body :: acc) else if b = 60 then let pair = lex_lt acc in lex_loop (snd pair) (fst pair) else if b = 45 then let pair = lex_minus acc in lex_loop (snd pair) (fst pair) else if b = 95 then let pair = lex_uscore acc in lex_loop (snd pair) (fst pair) else let pair = lex_other b acc in lex_loop (snd pair) (fst pair)
let add_nonempty bs = match bs with [] -> () | _ -> add_literal bs
let rec read_reg_word acc = let c = getc () in if c = 2 then (List.rev acc, 0) else if c = 32 then (List.rev acc, 1) else read_reg_word (c :: acc)
let rec read_registrations u = let pair = read_reg_word [] in let _ = add_nonempty (fst pair) in if snd pair = 0 then () else read_registrations ()
let start_lexer u = let first = getc () in if first = 1 then let _ = read_registrations () in dump_tokens (lex_loop 0 []) else dump_tokens (lex_loop first [])
let _ = start_lexer ()
