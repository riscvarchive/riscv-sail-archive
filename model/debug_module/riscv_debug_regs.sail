/* These are additional CSRs added to the CSR address space by the debug mode. */

bitfield DCSR : dmlenbits = {
  XDebugVer : 31 .. 28,
  EBreakM   : 15,
  EBreakS   : 13,
  EBreakU   : 12,
  StepIE    : 11,
  StopCount : 10,
  StopTime  : 9,
  Cause     : 8 .. 6,
  MPrvEn    : 4,
  NMIP      : 3,
  Step      : 2,
  Prv       : 1 .. 0
}
register dcsr : DCSR

function legalize_dcsr(d : DCSR, v : DCSR) -> DCSR = {
  let d = update_EBreakM(d, v.EBreakM());
  let d = if haveSupMode() then update_EBreakS(d, v.EBreakS()) else d;
  let d = if haveUsrMode() then update_EBreakU(d, v.EBreakU()) else d;
  let d = update_StepIE(d, v.StepIE());
  let d = update_StopCount(d, v.StopCount());
  let d = update_StopTime(d, v.StopTime());
  let d = update_MPrvEn(d, v.MPrvEn());
  let d = update_Step(d, v.Step());
  let d : DCSR = match privLevel_of_bits(v.Prv()) {
                   Machine    => update_Prv(d, v.Prv()),
                   Supervisor => if haveSupMode() then update_Prv(d, v.Prv()) else d,
                   User       => if haveUsrMode() then update_Prv(d, v.Prv()) else d
                 };
  d
}

register dpc : xlenbits

