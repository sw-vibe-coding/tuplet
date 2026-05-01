let saved = ref []

let rec range n acc =
  if n = 0 then acc else range (n - 1) (n :: acc)

let rec churn n =
  if n = 0 then ()
  else
    let tmp = range 80 [] in
    let _ = tmp in
    churn (n - 1)

let rec sum xs =
  match xs with
  | [] -> 0
  | h :: t -> h + sum t

let _ = saved := range 50 []
let _ = churn 120
let _ = print_int (sum !saved)
