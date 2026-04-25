let dump_pair p = match p with ("INT", v) -> "INT " ^ v | ("IDENT", v) -> "IDENT " ^ v | (other, v) -> other ^ " " ^ v in print_endline (dump_pair ("INT", "42"))
