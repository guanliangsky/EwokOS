LIB_OBJS = lib/src/string.o \
	lib/src/syscall.o \
	lib/src/fork.o \
	lib/src/malloc.o \
	lib/src/vsprintf.o \
	lib/src/pmessage.o \
	lib/src/sramdisk.o \
	lib/src/stdio.o \
	lib/src/package.o \
	lib/src/kserv/kserv.o \
	lib/src/kserv/fs.o 

lib/libewok.a: $(LIB_OBJS)
	mkdir -p build
	$(AR) rT $@ $(LIB_OBJS)	

EXTRA_CLEAN += $(LIB_OBJS) lib/libewok.a
