from cffi import FFI
ffi = FFI()
ffi.cdef("""
   int printf(const char *format, ...);
""")
C = ffi.dlopen(None)                     # loads the entire C namespace
arg = ffi.new("char[]", "world")         # equivalent to C code: char arg[] = "world";
C.printf("hi there, %s!\n", arg)
