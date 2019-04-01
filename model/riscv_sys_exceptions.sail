/* default exception model */

type ext_exception = unit

function handle_trap_extension(p : Privilege, pc : xlenbits, u : option(unit)) -> unit = ()

function get_trap_vector(p : Privilege, cause : Mcause) -> xlenbits = {
  let tvec : Mtvec = match p {
                       Machine    => mtvec,
                       Supervisor => stvec,
                       User       => utvec
                     };
  match tvec_addr(tvec, cause) {
    Some(epc) => epc,
    None()    => internal_error("Invalid tvec mode")
  }
}
