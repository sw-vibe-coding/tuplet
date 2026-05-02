let parsed = Ast.AProgram [Ast.AStmt ("signature", [Ast.AGroup ("name", ["ident:plot"]); Ast.AGroup ("inputs", ["ident:x"; "ident:y"; "ident:color"; "ident:transparency"]); Ast.AGroup ("outputs", ["ident:success"])]); Ast.AStmt ("signature", [Ast.AGroup ("name", ["ident:coord2"]); Ast.AGroup ("inputs", []); Ast.AGroup ("outputs", ["ident:x"; "ident:y"])]); Ast.AStmt ("call", [Ast.AGroup ("callee", ["ident:plot"]); Ast.AGroup ("args", ["ident:coord2"; "int:7"; "pct:50"])])]
let checked = Checker.check parsed
let _ = Checker.dump_result checked
