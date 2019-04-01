/* default exception model */

type ext_exception = cheri_cause

function handle_trap_extension(p : Privilege, pc : xlenbits, ccause : option(cheri_cause)) -> unit = {
  match p {
    Machine => {
      match ccause {
        Some(c) => { mccsr->cap_idx() = c.cap_idx;
                     mccsr->cause()   = CapExCode(c.capEx) },
        _       => ()
      };
      /* XXX should legalize pc here? */
      let (representable, mepcc) = setCapAddr(PCC, pc);
      assert(representable, "mepcc should always be representable");
      MEPCC   = mepcc;
      nextPCC = MTCC
    },
    Supervisor => {
      match ccause {
        Some(c) => { sccsr->cap_idx() = c.cap_idx;
                     sccsr->cause()   = CapExCode(c.capEx) },
        _       => ()
      };
      /* XXX should legalize pc here? */
      let (representable, sepcc) = setCapAddr(PCC, pc);
      assert(representable, "sepcc should always be representable");
      SEPCC   = sepcc;
      nextPCC = STCC
    },
    User => {
      match ccause {
        Some(c) => { uccsr->cap_idx() = c.cap_idx;
                     uccsr->cause()   = CapExCode(c.capEx) },
        _       => ()
      };
      /* XXX should legalize pc here? */
      let (representable, uepcc) = setCapAddr(PCC, pc);
      assert(representable, "uepcc should always be representable");
      UEPCC   = uepcc;
      nextPCC = UTCC
    }
  }
}

function get_trap_vector(p : Privilege, c : Mcause) -> xlenbits = {
  let tcc : Capability = match p {
                           Machine    => MTCC,
                           Supervisor => STCC,
                           User       => UTCC
                         };
  match tvec_addr(Mk_Mtvec(getCapOffsetBits(tcc)), c) {
    Some(epc) => epc,
    None()    => internal_error("Invalid tvec mode")
  }
}
