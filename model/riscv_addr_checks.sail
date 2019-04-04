/* default PC and data address checks */

type ext_fetch_error = unit

/* Since fetch is done in granules, the check function gets two arguments:
 * start_pc: the PC at the start of the current fetch sequence
 * pc:       the PC for the current granule
 *
 * returns:  the *virtual* memory address to use for the fetch.
 *           any address translation errors are reported for pc, not the returned value.
 *           FIXME: Would this be the generally desired behaviour?
 */
function ext_fetch_check_pc(start_pc : xlenbits, pc : xlenbits) -> Ext_Fetch_Check(ext_fetch_error) =
  Ext_Fetch_OK(pc)

function ext_handle_fetch_check_error(err : ext_fetch_error) -> unit =
  ()
