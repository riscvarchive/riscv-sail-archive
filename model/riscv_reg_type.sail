/* default register type */
type regtype = xlenbits

/* default zero register */
let zero_reg : regtype = EXTZ(0x0)

/* default register printer */
val RegStr : regtype -> string
function RegStr(r) = BitStr(r)
