/* register type */
type regtype = Capability

/* null cap */
let zero_reg : regtype = null_cap

/* register printer */
val RegStr : Capability -> string effect {escape}
function RegStr(r) = capToString(r)

