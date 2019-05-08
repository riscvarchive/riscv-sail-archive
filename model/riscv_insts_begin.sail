/* Instruction definitions.
 *
 * This includes decoding, execution, and assembly parsing and printing.
 */

scattered union ast

/* returns whether an instruction was retired, used for computing minstret */
val execute : ast -> bool effect {escape, wreg, rreg, wmv, wmvt, eamem, rmem, barr, exmem}
scattered function execute

val assembly : ast <-> string
scattered mapping assembly

val encdec : ast <-> bits(32)
scattered mapping encdec

val encdec_compressed : ast <-> bits(16)
scattered mapping encdec_compressed

/* an ast not defined in the standard might be defined by an extension.
 * this hook allows the extension to implement these ast.  it has the
 * same semantics as execute.
 */
val ext_execute : ast -> bool effect {escape, wreg, rreg, wmv, wmvt, eamem, rmem, barr, exmem}
