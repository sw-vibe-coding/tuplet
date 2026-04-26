(* Tuplet lexer.

   Byte-stream model: input via getc; token text payload
   accumulated as int list and emitted via putc. ETX (3)
   terminates input. See docs/lexer.md for the full design.

   Each top-level let RHS stays on one physical line because
   the host parses each top-level statement independently;
   multi-line let-rec bodies parse-error. Multi-line `match`
   is supported as long as the `match X with` opener is on
   the same line as `let f y =`. *)

type token =
  | THash of int list
  | TInt of int
  | TPct of int
  | TMinus
  | TUnknown of int
  | TEOF

(* Emit each byte in a list via putc. *)
let rec emit_bytes bs = match bs with [] -> () | h :: t -> let _ = putc h in emit_bytes t

(* Fixed-width prefixes for each token kind, composed from
   char literals so the magic numbers don't appear here. *)
let prefix_hash = [Char.code 'H'; Char.code 'A'; Char.code 'S'; Char.code 'H'; Char.code ' '; Char.code ' '; Char.code ' ']
let prefix_int  = [Char.code 'I'; Char.code 'N'; Char.code 'T'; Char.code ' '; Char.code ' '; Char.code ' '; Char.code ' ']
let prefix_pct  = [Char.code 'P'; Char.code 'C'; Char.code 'T'; Char.code ' '; Char.code ' '; Char.code ' '; Char.code ' ']
let prefix_unk  = [Char.code 'U'; Char.code 'N'; Char.code 'K'; Char.code ' '; Char.code ' '; Char.code ' '; Char.code ' ']

(* Decompose a non-negative integer into a list of ASCII digit
   bytes, most significant first. n=0 emits ["0"]. *)
let rec int_to_bytes_aux x acc = if x = 0 then acc else int_to_bytes_aux (x / 10) ((x mod 10 + Char.code '0') :: acc)
let int_to_bytes n = if n = 0 then [Char.code '0'] else int_to_bytes_aux n []

(* Emit a fixed prefix + a payload byte list + LF. *)
let dump_with_prefix prefix bs = let _ = emit_bytes prefix in let _ = emit_bytes bs in putc (Char.code '\n')

let dump_tok t = match t with
  | TEOF       -> print_endline "EOF"
  | TMinus     -> print_endline "MINUS"
  | THash bs   -> dump_with_prefix prefix_hash bs
  | TInt n     -> dump_with_prefix prefix_int (int_to_bytes n)
  | TPct n     -> dump_with_prefix prefix_pct (int_to_bytes n)
  | TUnknown b -> let _ = emit_bytes prefix_unk in let _ = print_int b in putc (Char.code '\n')

let dump_tokens toks = List.iter dump_tok toks

(* Character classes. *)
let is_ws c = c = Char.code ' ' || c = Char.code '\t' || c = Char.code '\n' || c = Char.code '\r'
let is_digit c = c >= Char.code '0' && c <= Char.code '9'

(* Read bytes until LF or ETX; collect into reversed list, then reverse.
   Used after the leading '#' has been consumed. *)
let rec collect_comment acc = let c = getc () in if c = Char.code '\n' || c = 3 then List.rev acc else collect_comment (c :: acc)

(* Accumulate a digit run into an int. Returns (n, next_byte) where
   next_byte is the first non-digit byte (consumed from the stream). *)
let rec lex_digits n = let b = getc () in if is_digit b then lex_digits (n * 10 + (b - Char.code '0')) else (n, b)

(* Main lex loop. `pre` is a one-byte lookahead buffer:
   0 means "no pending byte; call getc". The sentinel 0 is
   safe because NUL is not a valid Tuplet source byte. *)
let rec lex_loop pre acc = let b = if pre = 0 then getc () else pre in if b = 3 then List.rev (TEOF :: acc) else if is_ws b then lex_loop 0 acc else if b = Char.code '#' then let body = collect_comment [] in lex_loop 0 (THash body :: acc) else if b = Char.code '-' then lex_loop 0 (TMinus :: acc) else if is_digit b then let pair = lex_digits (b - Char.code '0') in let n = fst pair in let next = snd pair in if next = Char.code '%' then lex_loop 0 (TPct n :: acc) else lex_loop next (TInt n :: acc) else lex_loop 0 (TUnknown b :: acc)

let _ = dump_tokens (lex_loop 0 [])
