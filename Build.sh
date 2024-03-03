export PATH=$PATH:/usr/local/i386elfgcc/bin

nasm "Boot.asm" -f bin -o "Boot.bin"
nasm "Kernel.asm" -f bin -o "Kernel.bin"
nasm "Padding.asm" -f bin -o "Padding.bin"
nasm "Terminal.asm" -f bin -o "Terminal.bin"


cat "Boot.bin" "Kernel.bin" "Padding.bin" "Terminal.bin" > "OS.bin"

dd status=noxfer conv=notrunc if=OS.bin of=myflp.flp
qemu-system-i386 -m 1 -fda myflp.flp