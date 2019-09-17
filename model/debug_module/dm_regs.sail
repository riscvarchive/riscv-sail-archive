/* Debug module registers */

/* The current implementation tries to rely on using the abstract
 * command mechanism as far as possible (i.e. for accessing registers,
 * and reading and writing memory).  It does not implement a program
 * buffer or system bus access.
 */

type dmlenbits  = bits(32)

/* DM register indices are specified as offsets from the base
 * address of the DM module on the DMI bus.
 */
type dmiaddr = bits(8)

bitfield DMStatus : dmlenbits = {
  ImpEbreak      : 22,
  AllHaveReset   : 19,
  AnyHaveReset   : 18,
  AllResumeAck   : 17,
  AnyResumeAck   : 16,
  AllNonExistent : 15,
  AnyNonExistent : 14,
  AllUnavail     : 13,
  AnyUnavail     : 12,
  AllRunning     : 11,
  AnyRunning     : 10,
  AllHalted      :  9,
  AnyHalted      :  8,

  Authenticated   : 7,
  AuthBusy        : 6,
  HasResetHaltReq : 5,
  DevTreeValid    : 4,
  Version         : 3 .. 0,
}
register dmstatus : DMStatus

bitfield DMControl : dmlenbits = {
  HaltReq         : 31,
  ResumeReq       : 30,
  HartReset       : 29,
  AckHaveReset    : 28,
  HaSel           : 26,
  HartSelLo       : 16,  // HARTSELLEN = 1
  SetResetHaltReq : 3,
  ClrResetHaltReq : 2,
  NDMReset        : 1,
  DMActive        : 0
}
register dmcontrol : DMControl

function legalize_dmcontrol(c : DMControl, v : DMControl) -> DMControl = {
  // TODO: implement control actions
  let c = update_HaltReq(c, v.HaltReq());
  let c = update_ResumeReq(c, v.ResumeReq());
  let c = update_HartReset(c, v.HartReset());
  let c = update_AckHaveReset(c, v.AckHaveReset());
  let c = update_HaSel(c, v.HaSel());
  let c = update_HartSelLo(c, v.HartSelLo());
  let c = update_SetResetHaltReq(c, v.SetResetHaltReq());
  let c = update_ClrResetHaltReq(c, v.ClrResetHaltReq());
  c
}

bitfield AbstractCS : dmlenbits = {
  ProgBufSize : 28 .. 24,
  Busy        : 12,
  CmdErr      : 10 ..  8,
  DataCount   :  3 ..  0
}
register abstractcs : AbstractCS

function legalize_abstractcs(cs : AbstractCS, v : AbstractCS) -> AbstractCS = {
  let cs = update_CmdErr(cs, cs.CmdErr() & (~ (v.CmdErr())));
  cs
}

bitfield Command : dmlenbits = {
  CmdType : 31 .. 24,
  Control : 23 ..  0
}
register command : Command

// TODO: Remove if not needed.
bitfield SBCS : dmlenbits = {
  SBVersion       : 31 .. 29,
  SBBusyError     : 22,
  SBBusy          : 21,
  SBReadOnAddr    : 20,
  SBAccess        : 19 .. 17,
  SBAutoIncrement : 16,
  SBReadOnData    : 15,
  SBError         : 14,
  SBASize         : 11 .. 5,
  SBAccess128     :  4,
  SBAccess64      :  3,
  SBAccess32      :  2,
  SBAccess16      :  1,
  SBAccess8       :  0
}
register sbcs : SBCS

register devtreeaddr0 : dmlenbits
register haltsum0     : dmlenbits

register data0 : dmlenbits
register data1 : dmlenbits
register data2 : dmlenbits
register data3 : dmlenbits
