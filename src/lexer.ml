type token = THash of int list | TEOF
let rec emit_bytes bs = match bs with [] -> () | h :: t -> let _ = putc h in emit_bytes t
let prefix_hash = [72; 65; 83; 72; 32; 32; 32]
let dump_tok t = match t with TEOF -> print_endline "EOF" | THash bs -> let _ = emit_bytes prefix_hash in let _ = emit_bytes bs in putc 10
let rec dump_tokens toks = match toks with [] -> () | h :: t -> let _ = dump_tok h in dump_tokens t
let is_ws c = if c = 32 then true else if c = 9 then true else if c = 10 then true else if c = 13 then true else false
let rec collect_comment acc = let c = getc () in if c = 10 then List.rev acc else if c = 3 then List.rev acc else collect_comment (c :: acc)
let rec lex_loop acc = let c = getc () in if c = 3 then List.rev (TEOF :: acc) else if c = 35 then let body = collect_comment [] in lex_loop (THash body :: acc) else if is_ws c then lex_loop acc else lex_loop acc
let _ = dump_tokens (lex_loop [])
