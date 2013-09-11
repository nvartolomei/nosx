# tell make `tools` is not a file


all: boot.img

run: boot.img
	qemu-system-i386 -fda boot.img

boot.img: bin/loader.bin bin/kernel.bin tools/writer
	tools/writer bin/loader.bin bin/kernel.bin boot.img

bin/loader.bin: src/loader.asm
	@echo "> Compiling loader"
	nasm -f bin -I src/inc/ -o bin/loader.bin src/loader.asm
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

	rm -rf bin/loader.bin
	rm -rf bin/kernel.bin
	rm -rf boot.img