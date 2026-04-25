let t = (1, (42, "hello")) in match t with (0, (_, s)) -> print_endline ("IDENT " ^ s) | (1, (n, _)) -> print_endline ("INT " ^ string_of_int n) | (_, (_, _)) -> print_endline "OTHER"
