let parsed = Ast.AProgram [Ast.AStmt ("signature", [Ast.AGroup ("name", ["ident:coord2"]); Ast.AGroup ("inputs", []); Ast.AGroup ("outputs", ["ident:x"; "ident:y"])]); Ast.AStmt ("assign", [Ast.AGroup ("pattern", ["ident:a"; "ident:b"]); Ast.AGroup ("expr", ["ident:missing2"])])]
let checked = Checker.check parsed
let _ = Checker.dump_result checked
