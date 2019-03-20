/*========================================================================*/
/*                                                                        */
/*  Copyright (c) 2015-2019 Robert M. Norton                              */
/*  Copyright (c) 2015-2017 Kathyrn Gray                                  */
/*  All rights reserved.                                                  */
/*                                                                        */
/*  This software was developed by the University of Cambridge Computer   */
/*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  */
/*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   */
/*                                                                        */
/*  Redistribution and use in source and binary forms, with or without    */
/*  modification, are permitted provided that the following conditions    */
/*  are met:                                                              */
/*  1. Redistributions of source code must retain the above copyright     */
/*     notice, this list of conditions and the following disclaimer.      */
/*  2. Redistributions in binary form must reproduce the above copyright  */
/*     notice, this list of conditions and the following disclaimer in    */
/*     the documentation and/or other materials provided with the         */
/*     distribution.                                                      */
/*                                                                        */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    */
/*  SUCH DAMAGE.                                                          */
/*========================================================================*/

function raise_c2_exception6(capEx, regnum) =
  {
    print("CHERI " ^ string_of_capex(capEx) ^ " Reg=" ^ BitStr(regnum));
    /*
    let cause : cheri_cause = struct {
        cap_idx = regnum,
        capEx   = capEx
    };
    let t : sync_exception = struct {
      trap = E_CHERI,
      excinfo = (None() : option(xlenbits)),
      ccause = Some(cause)
    };
    nextPC = handle_exception(cur_privilege, CTL_TRAP(t), PC);
    */
    assert(false);
    false
  }

/*!
causes the processor to raise a capability exception by writing the given capability exception cause and register number to the xccsr register then signalling an exception. */
val raise_c2_exception : (CapEx, bits(5)) -> bool effect {escape, rreg, wreg}
function raise_c2_exception(capEx, regnum) =
  let reg6 = 0b0 @ regnum in
  raise_c2_exception6(capEx, reg6)

/*!
is as [raise_c2_exception] except that CapCause.RegNum  is written with the special value 0x10 indicating PCC register.
 */
val raise_c2_exception_pcc : (CapEx) -> bool effect {escape, rreg, wreg}
function raise_c2_exception_pcc(capEx) =
  raise_c2_exception6(capEx, 0b100000)

val pcc_access_system_regs : unit -> bool effect {rreg}
function pcc_access_system_regs () = PCC.access_system_regs

val execute_branch_pcc : Capability -> unit effect {wreg}
function execute_branch_pcc(newPCC) = {
  nextPC = newPCC.address;
  nextPCC = newPCC;
}

/* Operations that extract parts of a capability into GPR */

union clause ast = CGetPerm   : (regbits, regbits)
union clause ast = CGetType   : (regbits, regbits)
union clause ast = CGetBase   : (regbits, regbits)
union clause ast = CGetLen    : (regbits, regbits)
union clause ast = CGetTag    : (regbits, regbits)
union clause ast = CGetSealed : (regbits, regbits)
union clause ast = CGetOffset : (regbits, regbits)
union clause ast = CGetAddr   : (regbits, regbits)

function clause execute (CGetPerm(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(getCapPerms(capVal));
  true
}

function clause execute (CGetType(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = if capVal.sealed
    then zero_extend(capVal.otype)
    else 0xffffffffffffffff;
  true
}

function clause execute (CGetBase(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapBase(capVal));
  true
}

function clause execute (CGetOffset(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapOffset(capVal));
  true
}

function clause execute (CGetLen(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  let len65  = getCapLength(capVal);
  wGPR(rd) = to_bits(64, if len65 > MAX_U64 then MAX_U64 else len65);
  true
}

function clause execute (CGetTag(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(capVal.tag);
  true
}

function clause execute (CGetSealed(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = zero_extend(capVal.sealed);
  true
}

function clause execute (CGetAddr(rd, cb)) =
{
  checkCP2usable();
  let capVal = readCapReg(cb);
  wGPR(rd) = to_bits(64, getCapCursor(capVal));
  true
}

union clause ast = CAndPerm : (regbits, regbits, regbits)
function clause execute(CAndPerm(cd, cb, rt)) = 
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let perms   = getCapPerms(cb_val);
    let newCap  = setCapPerms(cb_val, (perms & rt_val[30..0]));
    writeCapReg(cd, newCap);
    true
  }
}



union clause ast = CToPtr : (regbits, regbits, regbits)
function clause execute(CToPtr(rd, cb, ct)) = 
{
  checkCP2usable();
  let ct_val = readCapReg(ct);
  let cb_val = readCapReg(cb);
  if not (ct_val.tag) then
    raise_c2_exception(CapEx_TagViolation, ct)
  else if cb_val.tag & cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else 
  {
    let ctBase = getCapBase(ct_val);
    /* Note: returning zero for untagged values breaks magic constants such as SIG_IGN */
    wGPR(rd) = if not (cb_val.tag) then
        zeros()
      else
        to_bits(64, getCapCursor(cb_val) - ctBase);
    true
  }
}

union clause ast = CIncOffset : (regbits, regbits, regbits)
function clause execute (CIncOffset(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if cb_val.tag & cb_val.sealed & (rt_val != 0x0000000000000000) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = incCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val));
    true
  }
}

union clause ast = CIncOffsetImmediate : (regbits, regbits, bits(12))
function clause execute (CIncOffsetImmediate(cd, cb, imm)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let imm64 : bits(64) = sign_extend(imm);
  if cb_val.tag & cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = incCapOffset(cb_val, imm64);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + imm64));
    true
  }
}

union clause ast = CSetOffset : (regbits, regbits, regbits)
function clause execute (CSetOffset(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if cb_val.tag & cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = setCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val));
    true
  }
}

union clause ast = CSetBounds : (regbits, regbits, regbits)
function clause execute (CSetBounds(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = unsigned(rGPR(rt));
  let cursor = getCapCursor(cb_val);
  let base   = getCapBase(cb_val);
  let top    = getCapTop(cb_val);
  let newTop = cursor + rt_val;
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cursor < base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if newTop > top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else
  {
    let (_, newCap) = setCapBounds(cb_val, to_bits(64, cursor), to_bits(65, newTop));
    writeCapReg(cd, newCap); /* ignore exact */
    true
  }
}

union clause ast = CSetBoundsImmediate : (regbits, regbits, bits(12))
function clause execute (CSetBoundsImmediate(cd, cb, imm)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let immU   = unsigned(imm);
  let cursor = getCapCursor(cb_val);
  let base   = getCapBase(cb_val);
  let top    = getCapTop(cb_val);
  let newTop = cursor + immU;
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cursor < base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if newTop > top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else
  {
    let (_, newCap) = setCapBounds(cb_val, to_bits(64, cursor), to_bits(65, newTop));
    writeCapReg(cd, newCap); /* ignore exact */
    true
  }
}

union clause ast = CSetBoundsExact : (regbits, regbits, regbits)
function clause execute (CSetBoundsExact(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = unsigned(rGPR(rt));
  let cursor = getCapCursor(cb_val);
  let base   = getCapBase(cb_val);
  let top    = getCapTop(cb_val);
  let newTop = cursor + rt_val;
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cursor < base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if newTop > top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else
  {
    let (exact, newCap) = setCapBounds(cb_val, to_bits(64, cursor), to_bits(65, newTop));
    if not (exact) then
        raise_c2_exception(CapEx_InexactBounds, cb)
    else {
        writeCapReg(cd, newCap);
        true
    }
  }
}

union clause ast = CClearTag : (regbits, regbits)
function clause execute (CClearTag(cd, cb)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  writeCapReg(cd, {cb_val with tag=false});
  true
}

union clause ast = CMove : (regbits, regbits)
function clause execute (CMove(cd, cb)) =
{
  checkCP2usable();
  writeCapReg(cd) = readCapReg(cb);
  true
}

union clause ast = CFromPtr : (regbits, regbits, regbits)
function clause execute (CFromPtr(cd, cb, rt)) =
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let rt_val = rGPR(rt);
  if rt_val == 0x0000000000000000 then {
    writeCapReg(cd, null_cap);
    true
  } else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if cb_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cb)
  else
  {
    let (success, newCap) = setCapOffset(cb_val, rt_val);
    if success then
        writeCapReg(cd, newCap)
    else
        writeCapReg(cd, int_to_cap(to_bits(64, getCapBase(cb_val)) + rt_val));
    true
  }
}

union clause ast = CSeal : (regbits, regbits, regbits)
function clause execute (CSeal(cd, cs, ct)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let ct_val = readCapReg(ct);
  let ct_cursor = getCapCursor(ct_val);
  let ct_top    = getCapTop(ct_val);
  let ct_base   = getCapBase(ct_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (ct_val.tag) then
    raise_c2_exception(CapEx_TagViolation, ct)
  else if cs_val.sealed then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if ct_val.sealed then
    raise_c2_exception(CapEx_SealViolation, ct)
  else if not (ct_val.permit_seal) then
    raise_c2_exception(CapEx_PermitSealViolation, ct)
  else if ct_cursor < ct_base then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor >= ct_top then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor > max_otype then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else
  {
    let (success, newCap) = sealCap(cs_val, to_bits(24, ct_cursor));
    if not (success) then
        raise_c2_exception(CapEx_InexactBounds, cs)
    else {
        writeCapReg(cd, newCap);
        true
    }
  }
}

union clause ast = CUnseal : (regbits, regbits, regbits)
function clause execute (CUnseal(cd, cs, ct)) =
{
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let ct_val = readCapReg(ct);
  let ct_cursor = getCapCursor(ct_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (ct_val.tag) then
    raise_c2_exception(CapEx_TagViolation, ct)
  else if not (cs_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if ct_val.sealed then
    raise_c2_exception(CapEx_SealViolation, ct)
  else if ct_cursor != unsigned(cs_val.otype) then
    raise_c2_exception(CapEx_TypeViolation, ct)
  else if not (ct_val.permit_unseal) then
    raise_c2_exception(CapEx_PermitUnsealViolation, ct)
  else if ct_cursor <  getCapBase(ct_val) then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else if ct_cursor >= getCapTop(ct_val) then
    raise_c2_exception(CapEx_LengthViolation, ct)
  else {
    writeCapReg(cd, {unsealCap(cs_val) with 
      global=(cs_val.global & ct_val.global)
    });
    true
  }
}

union clause ast = CCall : (regbits, regbits, regbits)
function clause execute (CCall(cs, cb, 0b00001)) = /* selector=1 */
{
  /* Jump-like implementation of CCall that unseals arguments */
  checkCP2usable();
  let cs_val = readCapReg(cs);
  let cb_val = readCapReg(cb);
  let cs_cursor = getCapCursor(cs_val);
  if not (cs_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cs)
  else if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if not (cs_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cs)
  else if not (cb_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if cs_val.otype != cb_val.otype then
    raise_c2_exception(CapEx_TypeViolation, cs)
  else if not (cs_val.permit_ccall) then
    raise_c2_exception(CapEx_PermitCCallViolation, cs)
  else if not (cb_val.permit_ccall) then
    raise_c2_exception(CapEx_PermitCCallViolation, cb)
  else if not (cs_val.permit_execute) then
    raise_c2_exception(CapEx_PermitExecuteViolation, cs)
  else if cb_val.permit_execute then
    raise_c2_exception(CapEx_PermitExecuteViolation, cb)
  else if cs_cursor < getCapBase(cs_val) then
    raise_c2_exception(CapEx_LengthViolation, cs)
  else if cs_cursor >= getCapTop(cs_val) then
    raise_c2_exception(CapEx_LengthViolation, cs)
  else
  {
    
    C26 = unsealCap(cb_val);
    nextPC = cs_val.address;
    nextPCC = unsealCap(cs_val);
    true
  }
}

union clause ast = CJALR : (regbits, regbits)
function clause execute(CJALR(cd, cb)) = 
{
  checkCP2usable();
  let cb_val = readCapReg(cb);
  let cb_ptr = getCapCursor(cb_val);
  let cb_top = getCapTop(cb_val);
  let cb_base= getCapBase(cb_val);
  if not (cb_val.tag) then
    raise_c2_exception(CapEx_TagViolation, cb)
  else if (cb_val.sealed) then
    raise_c2_exception(CapEx_SealViolation, cb)
  else if not (cb_val.permit_execute) then
    raise_c2_exception(CapEx_PermitExecuteViolation, cb)
  else if cb_ptr < cb_base then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if (cb_ptr + min_inst_bytes) > cb_top then
    raise_c2_exception(CapEx_LengthViolation, cb)
  else if (cb_ptr % min_inst_bytes) != 0 then {
    handle_mem_exception(to_bits(xlen, cb_ptr),  E_Fetch_Addr_Align);
    false
  } else {
    let (success, linkCap) = setCapAddr(PCC, nextPC); /* Note that nextPC accounts for compressed instrucitons */
    assert(success, "Link cap should always be representable.");
    writeCapReg(cd, linkCap);
    execute_branch_pcc(cb_val);
    true
  };
}

val handle_load_data_via_cap : (regbits, bits(6), Capability, uint64, bool, word_width) -> bool effect {escape, rmem, rreg, wmv, wmvt, wreg}
function handle_load_data_via_cap(rd, cs, cap_val, vaddr, is_unsigned, width) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let size = word_width_bytes(width);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception6(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception6(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_load) then {
    raise_c2_exception6(CapEx_PermitLoadViolation, cs);
  } else if (vaddr + size) > top then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if check_misaligned(vaddrBits, width) then {
    handle_mem_exception(vaddrBits, E_Load_Addr_Align);
    false
  } else
    process_load(rd, vaddrBits, mem_read(vaddrBits, size, aq, rl, false), is_unsigned)
}

union clause ast = CLoadCap : (regbits, regbits, bool, word_width)
function clause execute (CLoadCap(rd, cs, is_unsigned, width)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_load_data_via_cap(rd, 0b0 @ cs, cap_val, vaddr, is_unsigned, width)
}

val handle_load_cap_via_cap : (regbits, bits(6), Capability, uint64) -> bool effect {escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function handle_load_cap_via_cap(rd, cs, cap_val, vaddr) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception6(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception6(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_load) then {
    raise_c2_exception6(CapEx_PermitLoadViolation, cs);
  } else if (vaddr + cap_size) > top then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception6(CapEx_LengthViolation, cs);
  } else if not(is_aligned_addr(vaddrBits, cap_size)) then {
    handle_mem_exception(vaddrBits, E_Load_Addr_Align);
    false
  } else {
    let c = mem_read_cap(vaddrBits, aq, rl, false);
    match c {
      MemValue(v) => {writeCapReg(rd, v); true},
      MemException(e) => {handle_mem_exception(vaddrBits, e); false }
    }
  }
}

union clause ast = CLoadCapCap : (regbits, regbits)
function clause execute (CLoadCapCap(rd, cs)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_load_cap_via_cap(rd, 0b0 @ cs, cap_val, vaddr)
}

val handle_store_data_via_cap : (regbits, regbits, Capability, uint64, word_width) -> bool effect {eamem, escape, rmem, rreg, wmv, wmvt, wreg}
function handle_store_data_via_cap(rs, cs, cap_val, vaddr, width) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let size = word_width_bytes(width);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_store) then {
    raise_c2_exception(CapEx_PermitStoreViolation, cs);
  } else if (vaddr + size) > top then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if check_misaligned(vaddrBits, width) then {
    handle_mem_exception(vaddrBits, E_SAMO_Addr_Align);
    false
  } else {
    let eares : MemoryOpResult(unit) = mem_write_ea(vaddrBits, size, aq, rl, false);
    match (eares) {
      MemException(e) => { handle_mem_exception(vaddrBits, e); false },
      MemValue(_) => {
        let rs_val = X(rs);
        let res : MemoryOpResult(bool) = match width {
          BYTE   => mem_write_value(vaddrBits, 1, rs_val[7..0],  aq, rl, false),
          HALF   => mem_write_value(vaddrBits, 2, rs_val[15..0], aq, rl, false),
          WORD   => mem_write_value(vaddrBits, 4, rs_val[31..0], aq, rl, false),
          DOUBLE => mem_write_value(vaddrBits, 8, rs_val,        aq, rl, false)
        };
        match (res) {
          MemValue(true)  => true,
          MemValue(false) => internal_error("store got false from mem_write_value"),
          MemException(e) => { handle_mem_exception(vaddrBits, e); false }
        }
      }
    }
  }
}

union clause ast = CStoreCap : (regbits, regbits, word_width)
function clause execute (CStoreCap(rs, cs, width)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_store_data_via_cap(rs, cs, cap_val, vaddr, width)
}

val handle_store_cap_via_cap : (regbits, regbits, Capability, uint64) -> bool effect {eamem, escape, rmem, rreg, wmv, wreg, wmvt}
function handle_store_cap_via_cap(rs, cs, cap_val, vaddr) = {
  let (base, top) = getCapBounds(cap_val);
  let vaddrBits = to_bits(xlen, vaddr);
  let aq : bool = false;
  let rl : bool = false;
  if not(cap_val.tag) then {
    raise_c2_exception(CapEx_TagViolation, cs);
  } else if cap_val.sealed then {
    raise_c2_exception(CapEx_SealViolation, cs);
  } else if not (cap_val.permit_store) then {
    raise_c2_exception(CapEx_PermitStoreViolation, cs);
  } else if (vaddr + cap_size) > top then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if vaddr < base then {
    raise_c2_exception(CapEx_LengthViolation, cs);
  } else if not(is_aligned_addr(vaddrBits, cap_size)) then {
    handle_mem_exception(vaddrBits, E_SAMO_Addr_Align);
    false
  } else {
    let eares : MemoryOpResult(unit) = mem_write_ea_cap(vaddrBits, aq, rl, false);
    match (eares) {
      MemException(e) => { handle_mem_exception(vaddrBits, e); false },
      MemValue(_) => {
        let rs_val = readCapReg(rs);
        let res : MemoryOpResult(bool) = mem_write_cap(vaddrBits, rs_val, aq, rl, false);
        match (res) {
          MemValue(true)  => true,
          MemValue(false) => internal_error("store got false from mem_write_value"),
          MemException(e) => { handle_mem_exception(vaddrBits, e); false }
        }
      }
    }
  }
}

union clause ast = CStoreCapCap : (regbits, regbits)
function clause execute (CStoreCapCap(rs, cs)) =
{
  checkCP2usable();
  let cap_val = readCapReg(cs);
  let vaddr = getCapCursor(cap_val);
  handle_store_cap_via_cap(rs, cs, cap_val, vaddr)
}

/* 
NB: Must be careful about order of matching because unused register
fields are re-used as additional function codes: more specific matches
must come before more general ones. In our case that means two-arg
instructions (that have 0x7f in func7 field) must come before
three-arg ones.
*/

/* Two arg */

mapping clause encdec = CGetPerm(rd, cb)   <-> 0b1111111 @ 0b00000 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetType(rd, cb)   <-> 0b1111111 @ 0b00001 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetBase(rd, cb)   <-> 0b1111111 @ 0b00010 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetLen(rd, cb)    <-> 0b1111111 @ 0b00011 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetTag(rd, cb)    <-> 0b1111111 @ 0b00100 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetSealed(rd, cb) <-> 0b1111111 @ 0b00101 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetOffset(rd, cb) <-> 0b1111111 @ 0b00110 @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CGetAddr(rd, cb)   <-> 0b1111111 @ 0b01111 @ cb @ 0b000 @ rd @ 0b1011011

mapping clause encdec = CMove(cd, cs)      <-> 0b1111111 @ 0b01010 @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CClearTag(cd, cs)  <-> 0b1111111 @ 0b01011 @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CJALR(cd, cb)      <-> 0b1111111 @ 0b01100 @ cb @ 0b000 @ cd @ 0b1011011

mapping clause assembly = CGetPerm(rd, cb)   <-> "CGetPerm"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetType(rd, cb)   <-> "CGetType"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetBase(rd, cb)   <-> "CGetBase"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetLen(rd, cb)    <-> "CGetLen"    ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetTag(rd, cb)    <-> "CGetTag"    ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetSealed(rd, cb) <-> "CGetSealed" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetOffset(rd, cb) <-> "CGetOffset" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)
mapping clause assembly = CGetAddr(rd, cb)   <-> "CGetAddr"   ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb)

mapping clause assembly = CMove(cd, cs)      <-> "CMove"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs)
mapping clause assembly = CClearTag(cd, cs)  <-> "CClearTag"  ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs)
mapping clause assembly = CJALR(0b00000, cb) <-> "CJR"        ^ spc() ^ reg_name(cb)
mapping clause assembly = CJALR(cd, cb)      <-> "CJALR"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb)

/* Three arg */

mapping clause encdec = CSeal(cd, cs, ct)      <-> 0b0001011 @ ct @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CUnseal(cd, cs, ct)    <-> 0b0001100 @ ct @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CAndPerm(cd, cs, rt)   <-> 0b0001101 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CSetOffset(cd, cs, rt) <-> 0b0001111 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CIncOffset(cd, cs, rt) <-> 0b0010001 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CSetBounds(cd, cs, rt) <-> 0b0001000 @ rt @ cs @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CSetBoundsExact(cd, cs, rt) <-> 0b0001001 @ rt @ cs @ 0b000 @ cd @ 0b1011011

mapping clause encdec = CToPtr(rd, cb, cs)    <-> 0b0010010 @ cs @ cb @ 0b000 @ rd @ 0b1011011
mapping clause encdec = CFromPtr(cd, cb, rs)  <-> 0b0010011 @ rs @ cb @ 0b000 @ cd @ 0b1011011
mapping clause encdec = CCall(cs, cb, 0b00001) <-> 0b1111110 @ 0b00001 @ cb @ 0b000 @ cs @ 0b1011011 /* CCallFast */

mapping clause encdec = CIncOffsetImmediate(cd, cb, imm12) <-> imm12 : bits(12) @ cb @ 0b001 @ cd @ 0b1011011
mapping clause encdec = CSetBoundsImmediate(cd, cb, imm12) <-> imm12 : bits(12) @ cb @ 0b010 @ cd @ 0b1011011

mapping clause assembly = CSeal(cd, cs, ct)      <-> "CSeal"      ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(ct)
mapping clause assembly = CUnseal(cd, cs, ct)    <-> "CUnseal"    ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(ct)
mapping clause assembly = CAndPerm(cd, cs, rt)   <-> "CAndPerm"   ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CSetOffset(cd, cs, rt) <-> "CSetOffset" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CIncOffset(cd, cs, rt) <-> "CIncOffset" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CSetBounds(cd, cs, rt) <-> "CSetBounds" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)
mapping clause assembly = CSetBoundsExact(cd, cs, rt) <-> "CSetBoundsExact" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cs) ^ sep() ^ reg_name(rt)

mapping clause assembly = CToPtr(rd, cb, cs)    <-> "CToPtr"      ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(cs)
mapping clause assembly = CFromPtr(cd, cb, rs)  <-> "CFromPtr"    ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ reg_name(rs)
mapping clause assembly = CCall(cs, cb, 0b00001) <-> "CCallFast"  ^ spc() ^ reg_name(cs) ^ sep() ^ reg_name(cb)

mapping clause assembly = CIncOffsetImmediate(cd, cb, imm12) <-> "CIncOffsetImmediate" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ hex_bits_12(imm12)
mapping clause assembly = CSetBoundsImmediate(cd, cb, imm12) <-> "CSetBoundsImmediate" ^ spc() ^ reg_name(cd) ^ sep() ^ reg_name(cb) ^ sep() ^ hex_bits_12(imm12)

/* Loads and stores */

/* Load / store data via cap, cs */
mapping clause encdec = CLoadCap(rd, cs, false, BYTE)   <-> 0b0000000 @ 0b10000 @ cs @ 0b000 @ rd @ 0b1011011  /* lbcap */
mapping clause encdec = CLoadCap(rd, cs, false, HALF)   <-> 0b0000000 @ 0b10001 @ cs @ 0b000 @ rd @ 0b1011011  /* lhcap */
mapping clause encdec = CLoadCap(rd, cs, false, WORD)   <-> 0b0000000 @ 0b10010 @ cs @ 0b000 @ rd @ 0b1011011  /* lwcap */
mapping clause encdec = CLoadCap(rd, cs, false, DOUBLE) <-> 0b0000000 @ 0b10011 @ cs @ 0b000 @ rd @ 0b1011011  /* ldcap */
mapping clause encdec = CLoadCap(rd, cs, true, BYTE)    <-> 0b0000000 @ 0b10100 @ cs @ 0b000 @ rd @ 0b1011011  /* lbucap */
mapping clause encdec = CLoadCap(rd, cs, true, HALF)    <-> 0b0000000 @ 0b10101 @ cs @ 0b000 @ rd @ 0b1011011  /* lhucap */
mapping clause encdec = CLoadCap(rd, cs, true, WORD)    <-> 0b0000000 @ 0b10110 @ cs @ 0b000 @ rd @ 0b1011011  /* lwucap */
mapping clause encdec = CLoadCap(rd, cs, true, DOUBLE)  <-> 0b0000000 @ 0b10111 @ cs @ 0b000 @ rd @ 0b1011011  /* lducap */
mapping clause encdec = CStoreCap(rd, cs, BYTE)         <-> 0b0000000 @ 0b11000 @ cs @ 0b000 @ rd @ 0b1011011  /* sbcap */
mapping clause encdec = CStoreCap(rd, cs, HALF)         <-> 0b0000000 @ 0b11001 @ cs @ 0b000 @ rd @ 0b1011011  /* shcap */
mapping clause encdec = CStoreCap(rd, cs, WORD)         <-> 0b0000000 @ 0b11010 @ cs @ 0b000 @ rd @ 0b1011011  /* swcap */
mapping clause encdec = CStoreCap(rd, cs, DOUBLE)       <-> 0b0000000 @ 0b11011 @ cs @ 0b000 @ rd @ 0b1011011  /* sdcap */
mapping clause encdec = CStoreCapCap(rd, cs)            <-> 0b0000000 @ 0b11100 @ cs @ 0b000 @ rd @ 0b1011011  /* sqcap */
mapping clause encdec = CLoadCapCap(rd, cs)             <-> 0b0000000 @ 0b11101 @ cs @ 0b000 @ rd @ 0b1011011  /* lqcap */

mapping clause assembly = CLoadCap(rd, cs, u, w) <-> "l" ^ size_mnemonic(w) ^ maybe_u(u) ^ "Cap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(cs)
mapping clause assembly = CStoreCap(rd, rs, w)   <-> "s" ^ size_mnemonic(w) ^ "Cap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CStoreCapCap(rd, rs)   <-> "lqCap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
mapping clause assembly = CLoadCapCap(rd, rs)    <-> "sqCap" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs)
