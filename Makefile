OS = EwokOS

ifndef arch
	arch = versatilepb
#	arch = raspberrypi
endif
include kernel/arch/$(arch)/config.mk

# tools
AR = arm-none-eabi-ar
AS = arm-none-eabi-as
CC = arm-none-eabi-gcc
CXX = arm-none-eabi-c++
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump

# flags
CFLAGS = -mcpu=$(CPU) -gstabs -I. -I kernel/include -Ilib/include \
				 -I lib/include \
				 -I kernel/arch/$(arch)/include \
				 -marm \
				 -pedantic -Wall -Wextra -msoft-float -fPIC -mapcs-frame \
         -fno-builtin-printf -fno-builtin-strcpy -Wno-overlength-strings \
         -fno-builtin-exit -fno-builtin-stdio \
				 -std=c99 

ASFLAGS = -mcpu=$(CPU) -g -I kernel/include -I lib/include
QEMU_FLAGS = $(ARCH_QEMU_FLAGS) -nographic

all: lib/libewok.a $(OS).bin 

OBJS = kernel/asm/boot.o \
	kernel/asm/system.o \
	kernel/asm/context.o

include lib/build.mk
include kernel/build.mk
include mkramfs/build.mk
include sbin/build.mk


$(OS).bin: $(MKRAMFS) $(PROGRAM) $(OBJS) $(OS).ld
	mkdir -p build
	$(LD) -T $(OS).ld $(OBJS) lib/libewok.a -o build/$(OS).elf
	$(OBJCOPY) -O binary build/$(OS).elf build/$(OS).bin
	$(OBJDUMP) -D build/$(OS).elf > build/$(OS).asm
	$(MKRAMFS) build/initfs sbin/sbin

run: $(OS).bin
	qemu-system-arm $(QEMU_FLAGS) -kernel build/$(OS).bin -initrd build/initfs

debug: $(OS).bin
	qemu-system-arm $(QEMU_FLAGS) -gdb tcp::26000 -S -kernel build/$(OS).bin -initrd build/initfs

gdb: 
	echo "target remote :26000" > /tmp/gdbinit
	arm-none-eabi-gdb build/$(OS).elf -x /tmp/gdbinit

clean:
	rm -f $(OBJS) $(EXTRA_CLEAN)
	rm -fr build
	rm -fr sbin/sbin
