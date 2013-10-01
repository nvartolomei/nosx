# tell make `tools` is not a file


all: boot.img
	@echo
	@echo "  >>> Build succeeded <<<  "

test: boot.img
	@echo "  >>> Starting emulator <<<  "
	@qemu-system-i386 -fda boot.img

release: bin/bootloader.bin bin/kernel.bin tools/writer
	@sudo tools/writer bin/bootloader.bin bin/kernel.bin /dev/disk1

boot.img: bin/bootloader.bin bin/kernel.bin tools/writer
	@tools/writer bin/bootloader.bin bin/kernel.bin boot.img

bin/bootloader.bin: src/bootloader.asm
	@echo "> Compiling loader..."
	@nasm -f bin -I src/inc/ -o bin/bootloader.bin src/bootloader.asm

bin/kernel.bin: src/kernel.asm src/inc/screen.asm src/inc/defines.asm src/inc/cli.asm
	@echo "> Compiling kernel..."
	@nasm -f bin -I src/inc/ -o bin/kernel.bin src/kernel.asm

tools/writer: tools/writer.c
	@echo "> Compiling tools..."
	@$(MAKE) -C tools

clean:
	@$(MAKE) -C tools clean

	rm -rf bin/bootloader.bin
	rm -rf bin/kernel.bin
	rm -rf boot.img