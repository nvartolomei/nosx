# tell make `tools` is not a file


all: boot.img

test: boot.img
	qemu-system-i386 -fda boot.img

boot.img: bin/bootloader.bin bin/kernel.bin tools/writer
	tools/writer bin/bootloader.bin bin/kernel.bin boot.img

bin/bootloader.bin: src/bootloader.asm
	@echo "> Compiling loader"
	nasm -f bin -I src/inc/ -o bin/bootloader.bin src/bootloader.asm
	@echo "> End compiling loader"

bin/kernel.bin: src/kernel.asm
	@echo "> Compiling kernel"
	@nasm -f bin -I src/inc/ -o bin/kernel.bin src/kernel.asm
	@echo "> End compiling kernel"

tools/writer: tools/writer.c
	@echo "> Making tools"
	$(MAKE) -C tools
	@echo "> End making tools"

clean:
	$(MAKE) -C tools clean

	rm -rf bin/bootloader.bin
	rm -rf bin/kernel.bin
	rm -rf boot.img