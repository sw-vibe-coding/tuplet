type syntax_entry = SyntaxEntry of string * string * string list * string list
type syntax_match = NoSyntaxMatch | SyntaxMatch of string * string list * string list * string list * int
let syntax_entries = ref []
let syntax_next_order = ref 0
let add_syntax mode template expansion = let order = !syntax_next_order in let order_s = string_of_int order in let _ = syntax_next_order := order + 1 in syntax_entries := SyntaxEntry (order_s, mode, template, expansion) :: !syntax_entries
let reset_syntax_registry u = let _ = syntax_entries := [] in syntax_next_order := 0
let is_slot s = s = "slot"
let has_capture cap = match cap with [] -> false | _ -> true
let rec rev_items xs acc = match xs with [] -> acc | h :: t -> rev_items t (h :: acc)
let rec append_items xs ys = match xs with [] -> ys | h :: t -> h :: append_items t ys
let append_capture cap slots = append_items slots ("slot-start" :: rev_items cap [])
let rec template_len xs = match xs with [] -> 0 | h :: t -> 1 + template_len t
let rec capture_rest toks cap slots consumed = match toks with [] -> SyntaxMatch ("", [], [], append_capture cap slots, consumed) | h :: t -> capture_rest t (h :: cap) slots (consumed + 1)
let rec match_template_items template toks slots consumed = match template with [] -> SyntaxMatch ("", [], [], slots, consumed) | th :: tt -> (match toks with [] -> NoSyntaxMatch | ih :: it -> if is_slot th then match_slot_items tt toks [] slots consumed else if th = ih then match_template_items tt it slots (consumed + 1) else NoSyntaxMatch)
and match_slot_items template_tail toks cap slots consumed = match toks with [] -> NoSyntaxMatch | h :: t -> (match template_tail with [] -> capture_rest toks cap slots consumed | next :: rest -> if (not (is_slot next)) && h = next && has_capture cap then match_template_items template_tail toks (append_capture cap slots) consumed else match_slot_items template_tail t (h :: cap) slots (consumed + 1))
let entry_match entry toks = match entry with SyntaxEntry (order, mode, template, expansion) -> (match match_template_items template toks [] 0 with NoSyntaxMatch -> NoSyntaxMatch | SyntaxMatch (m, t, e, slots, consumed) -> SyntaxMatch (mode, template, expansion, slots, consumed))
let match_len m = match m with NoSyntaxMatch -> 0 | SyntaxMatch (mode, template, expansion, slots, consumed) -> template_len template
let better_match current candidate = if match_len candidate > match_len current then candidate else current
let rec best_match_entries entries toks best = match entries with [] -> best | h :: t -> best_match_entries t toks (better_match best (entry_match h toks))
let find_syntax_match toks = best_match_entries (List.rev !syntax_entries) toks NoSyntaxMatch
let rec dump_items xs = match xs with [] -> () | h :: t -> let _ = print_endline ("ITEM   " ^ h) in dump_items t
let dump_entry e = match e with SyntaxEntry (order, mode, template, expansion) -> let _ = print_endline ("ENTRY  " ^ order ^ " " ^ mode) in let _ = print_endline "TEMPLATE" in let _ = dump_items template in let _ = print_endline "EXPANSION" in let _ = dump_items expansion in print_endline "ENDENTRY"
let rec dump_entries xs = match xs with [] -> () | h :: t -> let _ = dump_entry h in dump_entries t
let dump_syntax_registry u = let _ = print_endline "REGISTRY" in let _ = dump_entries (List.rev !syntax_entries) in print_endline "ENDREGISTRY"
