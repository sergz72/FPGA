// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#define r_type_insn(_f7, _rs2, _rs1, _f3, _rd, _opc) \
.word (((_f7) << 25) | ((_rs2) << 20) | ((_rs1) << 15) | ((_f3) << 12) | ((_rd) << 7) | ((_opc) << 0))

#define waitirq_insn() \
r_type_insn(0, 0, 0, 0, 0, 0b0001011)

#define retirq_insn() \
r_type_insn(0, 0, 0, 1, 0, 0b0001011)

#define halt_insn() \
r_type_insn(0, 0, 0, 2, 0, 0b0001011)
