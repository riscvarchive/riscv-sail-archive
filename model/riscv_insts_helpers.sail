/* This file contains some helpers for instruction definition.  They are collected
 * here for use by instruction extensions.
 */

val extend_value : forall 'n, 0 < 'n <= xlen_bytes. (bool, MemoryOpResult(bits(8 * 'n))) -> MemoryOpResult(xlenbits)
function extend_value(is_unsigned, value) = match (value) {
  MemValue(v)     => MemValue(if is_unsigned then EXTZ(v) else EXTS(v) : xlenbits),
  MemException(e) => MemException(e)
}

val process_load : forall 'n, 0 < 'n <= xlen_bytes. (regbits, xlenbits, MemoryOpResult(bits(8 * 'n)), bool) -> bool effect {escape, rreg, wreg}
function process_load(rd, addr, value, is_unsigned) =
  match extend_value(is_unsigned, value) {
    MemValue(result) => { X(rd) = result; true },
    MemException(e)  => { handle_mem_exception(addr, e); false }
  }

function check_misaligned(vaddr : xlenbits, width : word_width) -> bool =
  if   plat_enable_misaligned_access() then false
  else match width {
         BYTE   => false,
         HALF   => vaddr[0] == true,
         WORD   => vaddr[0] == true | vaddr[1] == true,
         DOUBLE => vaddr[0] == true | vaddr[1] == true | vaddr[2] == true
       }

/* We could set load-reservations on physical or virtual addresses.
 * For now we set them on virtual addresses, since it makes the
 * sequential model of SC a bit simpler, at the cost of an explicit
 * call to load_reservation in LR and cancel_reservation in SC.
 */
val process_loadres : forall 'n, 0 < 'n <= xlen_bytes. (regbits, xlenbits, MemoryOpResult(bits(8 * 'n)), bool) -> bool effect {escape, rreg, wreg}
function process_loadres(rd, addr, value, is_unsigned) =
  match extend_value(is_unsigned, value) {
    MemValue(result) => { load_reservation(addr); X(rd) = result; true },
    MemException(e)  => { handle_mem_exception(addr, e); false }
  }
