Java bytecode translator to JavaCPU instructions.

Restrictions:
  1. Exceptions aren't supported.
  2. Garbage collector is not implemented.

Requires 3 memory segments:
  1. Data segment (for static class fields).
  2. RoData segment (for class definitions/string constants).
  3. Heap (for allocations with new keyword).
