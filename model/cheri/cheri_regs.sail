/* Cheri architectural registers */

register PCC       : Capability
register nextPCC   : Capability
register DDC       : Capability

register UTCC      : Capability
register UScratchC : Capability
register UEPCC     : Capability
register STCC      : Capability
register SScratchC : Capability
register SEPCC     : Capability
register MTCC      : Capability
register MScratchC : Capability
register MEPCC     : Capability

/* Cheri DDC interpretation */

union DDC_Result = {
  DDC_Address : xlenbits,
  DDC_Failure : CapEx
}

val translateDDC : (xlenbits, AccessType, word_width) -> DDC_Result effect {rreg, escape}
function translateDDC (addr, at, width) = {
  let ddc = DDC;
  let have_rqd_load_perm : bool = match at {
    Read       => ddc.permit_load,
    Write      => true,
    ReadWrite  => ddc.permit_load,
    Execute    => false /* DDC should only be for load/store */
  };
  let have_rqd_store_perm : bool = match at {
    Read       => true,
    Write      => ddc.permit_store,
    ReadWrite  => ddc.permit_store,
    Execute    => false /* DDC should only be for load/store */
  };
  let newAddr = (getCapCursor(ddc) + unsigned(addr)) % pow2(xlen);
  let size  = word_width_bytes(width);
  let (base, top) = getCapBounds(ddc);

  if not(ddc.tag) then
    DDC_Failure(CapEx_TagViolation)
  else if ddc.sealed then
    DDC_Failure(CapEx_SealViolation)
  else if not(have_rqd_load_perm) then
    DDC_Failure(CapEx_PermitLoadViolation)
  else if not(have_rqd_store_perm) then
    DDC_Failure(CapEx_PermitStoreViolation)
  else if (newAddr + size) > top then
    DDC_Failure(CapEx_LengthViolation)
  else if newAddr < base then
    DDC_Failure(CapEx_LengthViolation)
  else
    DDC_Address(to_bits(64, newAddr))
}

val raise_c2_exception6 : (CapEx, bits(6)) -> bool effect {escape, rreg, wreg}
