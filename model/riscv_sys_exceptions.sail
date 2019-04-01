/* default exception model */

type ext_exception = unit

function handle_trap_extension(p : Privilege, pc : xlenbits, u : option(unit)) -> unit = ()
