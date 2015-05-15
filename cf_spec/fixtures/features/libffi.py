from cffi import FFI
ffi = FFI()
ffi.cdef("""
   int printf(const char *format, ...);
""")
C = ffi.dlopen(None)                     # loads the entire C namespace
arg = ffi.new("char[]", b"world")        # equivalent to C code: char arg[] = "world";
C.printf(b"hi there, %s!\n", arg)
