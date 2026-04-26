type token = THash of int list | TInt of int | TPct of int | TMinus | TUnknown of int | TEOF
let rec emit_bytes bs = match bs with [] -> () | h :: t -> let _ = putc h in emit_bytes t
let prefix_hash = [72; 65; 83; 72; 32; 32; 32]
let prefix_int = [73; 78; 84; 32; 32; 32; 32]
let prefix_pct = [80; 67; 84; 32; 32; 32; 32]
let prefix_unk = [85; 78; 75; 32; 32; 32; 32]
let rec int_to_bytes_aux x acc = if x = 0 then acc else int_to_bytes_aux (x / 10) ((x mod 10 + 48) :: acc)
let int_to_bytes n = if n = 0 then [48] else int_to_bytes_aux n []
let dump_tok t = match t with TEOF -> print_endline "EOF" | TMinus -> print_endline "MINUS" | THash bs -> let _ = emit_bytes prefix_hash in let _ = emit_bytes bs in putc 10 | TInt n -> let _ = emit_bytes prefix_int in let _ = emit_bytes (int_to_bytes n) in putc 10 | TPct n -> let _ = emit_bytes prefix_pct in let _ = emit_bytes (int_to_bytes n) in putc 10 | TUnknown b -> let _ = emit_bytes prefix_unk in let _ = print_int b in putc 10
let rec dump_tokens toks = match toks with [] -> () | h :: t -> let _ = dump_tok h in dump_tokens t
let is_ws c = c = 32 || c = 9 || c = 10 || c = 13
let is_digit c = c >= 48 && c <= 57
let rec collect_comment acc = let c = getc () in if c = 10 || c = 3 then List.rev acc else collect_comment (c :: acc)
let rec lex_digits n = let b = getc () in if is_digit b then lex_digits (n * 10 + (b - 48)) else (n, b)
let rec lex_loop pre acc = let b = if pre = 0 then getc () else pre in if b = 3 then List.rev (TEOF :: acc) else if is_ws b then lex_loop 0 acc else if b = 35 then let body = collect_comment [] in lex_loop 0 (THash body :: acc) else if b = 45 then lex_loop 0 (TMinus :: acc) else if is_digit b then let pair = lex_digits (b - 48) in let n = fst pair in let next = snd pair in if next = 37 then lex_loop 0 (TPct n :: acc) else lex_loop next (TInt n :: acc) else lex_loop 0 (TUnknown b :: acc)
let _ = dump_tokens (lex_loop 0 [])
