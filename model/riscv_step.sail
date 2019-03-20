/* The emulator fetch-execute-interrupt dispatch loop. */

union FetchResult = {
  F_Base  : word,                      /* Base ISA */
  F_RVC   : half,                      /* Compressed ISA */
  F_Error : (ExceptionType, xlenbits), /* exception and PC */
  F_CHERI_Err : (CapEx, xlenbits)      /* CHERI exception code and PC */
}

function isRVC(h : half) -> bool =
 ~ (h[1 .. 0] == 0b11)

val fetch : unit -> FetchResult effect {escape, rmem, rreg, wmv, wmvt, wreg}
function fetch() -> FetchResult = {
  /* check for legal PC */
  let abs_pc = unsigned(PC);
  let abs_pc_bits = to_bits(xlen, abs_pc);
  let (pcc_base, pcc_top) = getCapBounds(PCC);
  if not(PCC.tag) then
     F_CHERI_Err(CapEx_TagViolation, PC)
  else if PCC.sealed then
     F_CHERI_Err(CapEx_SealViolation, PC)
  else if not(PCC.permit_execute) then
     F_CHERI_Err(CapEx_PermitExecuteViolation, PC)
  else if abs_pc < pcc_base | abs_pc + 4 > pcc_top then
     F_CHERI_Err(CapEx_LengthViolation, PC)
  else if (abs_pc_bits[0] != 0b0 | (abs_pc_bits[1] != 0b0 ))
    then F_Error(E_Fetch_Addr_Align, PC)
  else
    match checked_mem_read(Instruction, abs_pc_bits, 4, false, false, false) {
      MemException(e) => F_Error(E_Fetch_Access_Fault, PC),
      MemValue(v) => F_Base(v)
    }
}

/* returns whether to increment the step count in the trace */
val step : int -> bool effect {barr, eamem, escape, exmem, rmem, rreg, wmv, wmvt, wreg}
function step(step_no) = {
  minstret_written = false;     /* see note for minstret */
  let (retired, stepped) : (bool, bool) =
        match fetch() {
          F_Error(e, addr) => {
            handle_mem_exception(addr, e);
            (false, false)
          },
          F_CHERI_Err(e, addr) => {
            let _ = raise_c2_exception_pcc(e);
            (false, false)
          },
          F_RVC(h) => {
            match decodeCompressed(h) {
              None() => {
                instbits = EXTZ(h);
                handle_illegal();
                (false, true)
              },
              Some(ast) => {
		/* check for RVC once here instead of every RVC execute clause. */
		if haveRVC() then {
                  nextPC = PC + 2;
                  (execute(ast), true)
		} else {
		  (false, true)
		}
              }
            }
          },
          F_Base(w) => {
            match decode(w) {
              None() => {
                instbits = EXTZ(w);
                handle_illegal();
                (false, true)
              },
              Some(ast) => {
                nextPC = PC + 4;
                (execute(ast), true)
              }
            }
          }
        };
  PC = nextPC;
  PCC = nextPCC;
  stepped
}

val loop : unit -> unit effect {barr, eamem, escape, exmem, rmem, rreg, wmv, wmvt, wreg}
function loop () =
  while true do
    let _ = step(0) in ()
