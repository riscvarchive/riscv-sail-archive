/* control and address checks for CHERI */

type ext_fetch_error = CapEx

val ext_fetch_check_pc : (xlenbits, xlenbits) -> Ext_Fetch_Check(ext_fetch_error) effect {rreg}
function ext_fetch_check_pc(start_pc, pc) = {
  let abs_start_pc = unsigned(start_pc);
  let abs_pc       = unsigned(pc);

  /* not sure how these are different from start_pc and pc */
  let abs_start_pc_bits = to_bits(sizeof(xlen), abs_start_pc);
  let abs_pc_bits       = to_bits(sizeof(xlen), abs_pc);

  let (pcc_base, pcc_top) = getCapBounds(PCC);

  if   start_pc == pc
  then {
    /* We need to perform the permission checks only for the first granule. */
    if      not(PCC.tag)
    then    Ext_Fetch_Error(CapEx_TagViolation)
    else if PCC.sealed
    then    Ext_Fetch_Error(CapEx_SealViolation)
    else if not(PCC.permit_execute)
    then    Ext_Fetch_Error(CapEx_PermitExecuteViolation)
    else if abs_pc < pcc_base | abs_pc + 2 > pcc_top
    then    Ext_Fetch_Error(CapEx_LengthViolation)
    else    Ext_Fetch_OK(abs_pc_bits)
  } else {
    /* Perform only the bounds checks on the current granule, i.e. pc. */
    if      abs_pc < pcc_base | abs_pc + 2 > pcc_top
    then    Ext_Fetch_Error(CapEx_LengthViolation)
    else    Ext_Fetch_OK(abs_pc_bits)
  }
}

function ext_handle_fetch_check_error(e : ext_fetch_error) -> unit = {
  /* FIXME: check if we can avoid the ignored boolean return */
  let _ = raise_c2_exception_pcc(e);
  ()
}
