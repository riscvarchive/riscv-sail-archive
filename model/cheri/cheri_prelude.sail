/* CHERI specific helpers */

val MEMr_tag = "read_tag_bool"  : bits(64) -> bool effect { rmemt }
val MEMw_tag = "write_tag_bool" : (bits(64) , bool) -> unit effect { wmvt }

val MAX : forall 'n, 'n >= 0 . atom('n) -> atom(2 ^ 'n - 1) effect pure
function MAX(n) = pow2(n) - 1

val "shiftl" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)
val "shiftr" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)

overload operator >> = {shiftr}
overload operator << = {shiftl}

val not = {coq:"negb", _:"not"} : bool -> bool
