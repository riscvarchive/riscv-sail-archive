/* The definition for the sequential model. */

function clause execute (RISCV_JALR(imm, rs1, rd)) = {
/* For the sequential model, the memory-model definition doesn't work directly
 * if rs1 = rd.  We would effectively have to keep a regfile for reads and another for
 * writes, and swap on instruction completion.  This could perhaps be optimized in
 * some manner, but for now, we just keep a reordered definition to improve simulator
 * performance.
 */
  let t : xlenbits = X(rs1) + EXTS(imm);
  /* Extensions get the first checks on the prospective target address. */
  match ext_control_check_addr(t) {
    Ext_Control_Error(e) => {
      ext_handle_control_check_error(e);
      false
    },
    Ext_Control_OK(addr) => {
      /* Clear bit[0] */
      let  target = addr[(sizeof(xlen) - 1) .. 1] @ 0b0;
      if   target[1] & (~ (haveRVC()))
      then {
        handle_mem_exception(target, E_Fetch_Addr_Align);
        false
      } else {
        X(rd) = get_next_pc();
        set_next_pc(target);
        true
      }
    }
  }
}
