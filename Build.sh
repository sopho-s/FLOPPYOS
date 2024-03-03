export PATH=$PATH:/usr/local/i386elfgcc/bin

nasm "Boot.asm" -f bin -o "Boot.bin"
nasm "Kernel.asm" -f bin -o "Kernel.bin"
nasm "Terminal.asm" -f bin -o "Terminal.bin"

cat "Boot.bin"  > "OS.bin"

dd status=noxfer conv=notrunc if=OS.bin of=flp.img
qemu-system-i386 -m 1 -fda flp.img