/* Step hooks for rvfi. */

val ext_fetch_hook : FetchResult -> unit effect {wreg}
function ext_fetch_hook(f) = {
  match f {
    F_Ext_Error(_) => (),
    F_Error(_)     => (),
    _              => {
      /* for successful fetches, fill out the rvfi packet. */
      let i = rvfi_instruction.rvfi_insn();
      rvfi_exec->rvfi_order()    = minstret;
      rvfi_exec->rvfi_pc_rdata() = PC;
      rvfi_exec->rvfi_insn()     = sail_zero_extend(i,64);
      /* TODO: should we write these even if they're not really registers? */
      rvfi_exec->rvfi_rs1_data() = X(i[19 .. 15]);
      rvfi_exec->rvfi_rs2_data() = X(i[24 .. 20]);
      rvfi_exec->rvfi_rs1_addr() = sail_zero_extend(i[19 .. 15],8);
      rvfi_exec->rvfi_rs2_addr() = sail_zero_extend(i[24 .. 20],8)
    }
  }
}

function ext_pre_step_hook()  -> unit = ()

function ext_post_step_hook() -> unit = {
  /* record the next pc */
  rvfi_exec->rvfi_pc_wdata() = PC
}

val ext_init : unit -> unit effect {wreg}
function ext_init() = {
  /* these are here so that the C backend doesn't prune them out. */
  rvfi_set_instr_packet(0x0000000000000000);
  print_bits("", rvfi_get_cmd());
  // let _ = rvfi_step(0);
  rvfi_zero_exec_packet();
  rvfi_halt_exec_packet();
  let _ = rvfi_get_exec_packet();
  ()
}
