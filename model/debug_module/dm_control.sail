type dm_cmd_arg = bits(24)

bitfield AccessRegisterArg : dm_cmd_arg = {
  AARSize  : 22 .. 20,
  PostExec : 18,
  Transfer : 17,
  Write    : 16,
  Regno    : 15 .. 0
}

bitfield AccessMemoryArg : dm_cmd_arg = {
  AAMVirtual       : 23,
  AAMSize          : 22 .. 20,
  AAMPostIncrement : 19,
  Write            : 16,
  TargetSpecific   : 15 .. 14
}

function dm_access_register(a : AccessRegisterArg) -> unit = {
  // TODO: pg 11
  ()
}

function dm_access_memory(a : AccessMemoryArg) -> unit = {
  // TODO: pg 13
  ()
}

function dm_exec_cmd (c : Command) -> unit = {
  match c.CmdType() {
    0x00 => dm_access_register(Mk_AccessRegisterArg(c.Control())),
    0x01 => (), // Quick access not yet supported
    0x02 => dm_access_memory(Mk_AccessMemoryArg(c.Control())),
       _ => ()
  }
}

val initDMRegs : bool -> unit   effect {wreg}
val readDMReg  : dmiaddr -> dmlenbits effect {rreg}
val writeDMReg : (dmiaddr, dmlenbits) -> unit effect {rreg, wreg}

function initDMRegs (halted : bool) = {
  data0    = zeros();
  haltsum0 = EXTZ(if halted then 0b1 else 0b0);
}

function readDMReg (reg) = {
  match reg {
    0x04 => data0,
    0x05 => data1,
    0x06 => data2,
    0x07 => data3,
    0x10 => dmcontrol.bits(),
    0x11 => dmstatus.bits(),
    0x16 => abstractcs.bits(),
    0x17 => command.bits(),
    0x19 => devtreeaddr0,
    0x40 => haltsum0,
    _    => zeros()
  }
}

function writeDMReg (reg, value) = {
  match reg {
    0x04 => { data0 = value },
    0x05 => { data1 = value },
    0x06 => { data2 = value },
    0x07 => { data3 = value },
    0x10 => { dmcontrol = legalize_dmcontrol(dmcontrol, Mk_DMControl(value)) },
    0x16 => { abstractcs = legalize_abstractcs(abstractcs, Mk_AbstractCS(value)) },
    0x17 => { command->bits() = value; dm_exec_cmd(command) },
    _    => ()
  }
}
