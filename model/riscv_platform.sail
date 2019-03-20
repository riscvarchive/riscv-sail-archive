/* Platform-specific definitions, and basic MMIO devices. */

/* Current constraints on this implementation are:
   - it cannot access memory directly, but instead provides definitions for the physical memory model
   - it can access system register state, needed to manipulate interrupt bits
   - it relies on externs to get platform address information and doesn't hardcode them.
*/

/* Main memory */
val plat_ram_base = {c: "plat_ram_base", ocaml: "Platform.dram_base", lem: "plat_ram_base"} : unit -> xlenbits
val plat_ram_size = {c: "plat_ram_size", ocaml: "Platform.dram_size", lem: "plat_ram_size"} : unit -> xlenbits

/* whether the MMU should update dirty bits in PTEs */
val plat_enable_dirty_update = {ocaml: "Platform.enable_dirty_update",
                                c: "plat_enable_dirty_update",
                                lem: "plat_enable_dirty_update"} : unit -> bool

/* whether the platform supports misaligned accesses without trapping to M-mode. if false,
 * misaligned loads/stores are trapped to Machine mode.
 */
val plat_enable_misaligned_access = {ocaml: "Platform.enable_misaligned_access",
                                     c: "plat_enable_misaligned_access",
                                     lem: "plat_enable_misaligned_access"} : unit -> bool

/* whether mtval stores the bits of a faulting instruction on illegal instruction exceptions */
val plat_mtval_has_illegal_inst_bits = {ocaml: "Platform.mtval_has_illegal_inst_bits",
                                        c: "plat_mtval_has_illegal_inst_bits",
                                        lem: "plat_mtval_has_illegal_inst_bits"} : unit -> bool

/* ROM holding reset vector and device-tree DTB */
val plat_rom_base   = {ocaml: "Platform.rom_base", c: "plat_rom_base", lem: "plat_rom_base"} : unit -> xlenbits
val plat_rom_size   = {ocaml: "Platform.rom_size", c: "plat_rom_size", lem: "plat_rom_size"} : unit -> xlenbits

/* Location of clock-interface, which should match with the spec in the DTB */
val plat_clint_base = {ocaml: "Platform.clint_base", c: "plat_clint_base", lem: "plat_clint_base"} : unit -> xlenbits
val plat_clint_size = {ocaml: "Platform.clint_size", c: "plat_clint_size", lem: "plat_clint_size"} : unit -> xlenbits

/* Location of HTIF ports */
val plat_htif_tohost = {ocaml: "Platform.htif_tohost", c: "plat_htif_tohost", lem: "plat_htif_tohost"} : unit -> xlenbits
// todo: fromhost

val phys_mem_segments : unit -> list((xlenbits, xlenbits))
function phys_mem_segments() =
  (plat_rom_base (), plat_rom_size ()) ::
  (plat_ram_base (), plat_ram_size ()) ::
  [||]


/* Platform-specific handling of instruction faults */

function handle_illegal() -> unit = {
  assert(false);
}
