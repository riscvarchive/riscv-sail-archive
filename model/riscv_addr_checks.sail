/* default fetch address checks */

type ext_fetch_error = unit

/* Since fetch is done in granules, the check function gets two arguments:
 * start_pc: the PC at the start of the current fetch sequence
 * pc:       the PC for the current granule
 *
 * returns:  the *virtual* memory address to use for the fetch.
 *           any address translation errors are reported for pc, not the returned value.
 *           FIXME: Would this be the generally desired behaviour?
 */
function ext_fetch_check_pc(start_pc : xlenbits, pc : xlenbits) -> Ext_Fetch_Check(ext_fetch_error) = {
  let _ = Ext_Fetch_Error(); /* FIXME: workaround for C backend */
  Ext_Fetch_OK(pc)
}

function ext_handle_fetch_check_error(err : ext_fetch_error) -> unit =
  ()

/* default control address checks */

type ext_control_error = unit

/* these functions return the address to use as the target for
 * the control transfer.  any address translation or other errors
 * are reported for the original value, not the returned value.
 *
 * NOTE: the input value does *not* have bit[0] set to 0, to enable
 * more accurate bounds checking.  There is no constraint on the output
 * value, which will have bit[0] cleared by the caller if needed.
 *
 * FIXME: Would this be the generally desired behaviour?
 */

/* the control address is derived from a non-PC register, e.g. in JALR */
function ext_control_check_addr(pc : xlenbits) -> Ext_Control_Check(ext_control_error) =
  Ext_Control_OK(pc)

/* the control address is derived from the PC register, e.g. in JAL */
function ext_control_check_pc(pc : xlenbits) -> Ext_Control_Check(ext_control_error) = {
  let _ = Ext_Control_Error();  /* FIXME: workaround for C backend */
  Ext_Control_OK(pc)
}

function ext_handle_control_check_error(err : ext_control_error) -> unit =
  ()

/* accessors for default architectural addresses, for use from within instructions */

val get_next_pc : unit -> xlenbits effect {rreg}
function get_next_pc() = nextPC

val set_next_pc : xlenbits -> unit effect {wreg}
function set_next_pc(pc) = {
  nextPC = pc
}
