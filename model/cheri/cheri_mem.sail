/* Physical memory helpers */

val mem_read_cap : (xlenbits, bool, bool, bool) -> MemoryOpResult(Capability) effect {rmem, rmemt, rreg, escape}
function mem_read_cap (addr, aq, rl, res) = {
  let result : MemoryOpResult(bits(8 * 'cap_size)) =
    if   ~(is_aligned_addr(addr, cap_size))
    then MemException(E_Load_Addr_Align)
    else match (aq, rl, res) {
           (false, true,  false) => throw(Error_not_implemented("load.rl")),
           (false, true,  true)  => throw(Error_not_implemented("lr.rl")),
           (_, _, _)             => checked_mem_read(Data, addr, cap_size, aq, rl, res)
    };
  let tag = MEMr_tag(addr);
  match result {
    MemValue(v)     => MemValue(memBitsToCapability(tag, v)),
    MemException(e) => MemException(e) : MemoryOpResult(Capability)
  }
}

val mem_write_ea_cap : (xlenbits, bool, bool, bool) -> MemoryOpResult(unit) effect {eamem}
function mem_write_ea_cap(addr, aq, rl, con) = {
  if   ~(is_aligned_addr(addr, cap_size))
  then MemException(E_SAMO_Addr_Align)
  else MemValue(MEMea(addr, cap_size))
}

val mem_write_cap : (xlenbits, Capability, bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, rreg, wreg, escape, wmvt}

function mem_write_cap (addr, cap, aq, rl, con) = {
  let cap_bits = capToMemBits(cap);
  rvfi_write(addr, cap_size, cap_bits);
  if   ~ (is_aligned_addr(addr, cap_size))
  then MemException(E_SAMO_Addr_Align)
  else checked_mem_write(addr, cap_size, cap.tag, cap_bits)
}
